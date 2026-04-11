#define _GNU_SOURCE

#include <dlfcn.h>
#include <execinfo.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

#define DFTRACE_BUCKET_COUNT 65536u
#define DFTRACE_BACKTRACE_DEPTH 24
#define DFTRACE_PAGE_SIZE 65536u

typedef void *(*malloc_fn)(size_t);
typedef void *(*calloc_fn)(size_t, size_t);
typedef void *(*realloc_fn)(void *, size_t);
typedef void (*free_fn)(void *);

typedef struct FreeRecord {
    void *ptr;
    int frame_count;
    void *frames[DFTRACE_BACKTRACE_DEPTH];
    struct FreeRecord *next;
} FreeRecord;

typedef struct RecordPage {
    struct RecordPage *next;
    size_t used;
    FreeRecord records[];
} RecordPage;

static malloc_fn real_malloc;
static calloc_fn real_calloc;
static realloc_fn real_realloc;
static free_fn real_free;
static pthread_mutex_t dftrace_lock = PTHREAD_MUTEX_INITIALIZER;
static __thread bool dftrace_reentrant;
static FreeRecord *dftrace_buckets[DFTRACE_BUCKET_COUNT];
static RecordPage *dftrace_pages;

static inline size_t dftrace_hash_ptr(void *ptr)
{
    uintptr_t value = (uintptr_t)ptr;
    value ^= value >> 33;
    value *= 0xff51afd7ed558ccdULL;
    value ^= value >> 33;
    return (size_t)(value & (DFTRACE_BUCKET_COUNT - 1));
}

static void dftrace_resolve_symbols(void)
{
    if (real_malloc != NULL)
        return;

    real_malloc = (malloc_fn)dlsym(RTLD_NEXT, "malloc");
    real_calloc = (calloc_fn)dlsym(RTLD_NEXT, "calloc");
    real_realloc = (realloc_fn)dlsym(RTLD_NEXT, "realloc");
    real_free = (free_fn)dlsym(RTLD_NEXT, "free");
}

static FreeRecord *dftrace_alloc_record(void)
{
    if (dftrace_pages == NULL || dftrace_pages->used == (DFTRACE_PAGE_SIZE - sizeof(RecordPage)) / sizeof(FreeRecord)) {
        RecordPage *page = mmap(NULL, DFTRACE_PAGE_SIZE, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);

        if (page == MAP_FAILED)
            _Exit(99);

        page->next = dftrace_pages;
        page->used = 0;
        dftrace_pages = page;
    }

    return &dftrace_pages->records[dftrace_pages->used++];
}

static void dftrace_print_frames(char const *label, void *const *frames, int frame_count)
{
    fprintf(stderr, "%s (%d frame(s)):\n", label, frame_count);
    backtrace_symbols_fd((void *const *)frames, frame_count, fileno(stderr));
}

static void dftrace_remove_reused_pointer(void *ptr)
{
    size_t bucket = dftrace_hash_ptr(ptr);
    FreeRecord *previous = NULL;
    FreeRecord *record = dftrace_buckets[bucket];

    while (record != NULL) {
        if (record->ptr == ptr) {
            if (previous == NULL)
                dftrace_buckets[bucket] = record->next;
            else
                previous->next = record->next;
            return;
        }

        previous = record;
        record = record->next;
    }
}

static void dftrace_record_free(void *ptr)
{
    size_t bucket;
    FreeRecord *record;

    if (ptr == NULL)
        return;

    bucket = dftrace_hash_ptr(ptr);
    record = dftrace_buckets[bucket];
    while (record != NULL) {
        if (record->ptr == ptr) {
            void *frames[DFTRACE_BACKTRACE_DEPTH];
            int frame_count = backtrace(frames, DFTRACE_BACKTRACE_DEPTH);

            fprintf(stderr, "dftrace: double free detected for %p\n", ptr);
            dftrace_print_frames("first free", record->frames, record->frame_count);
            dftrace_print_frames("second free", frames, frame_count);
            _Exit(88);
        }

        record = record->next;
    }

    record = dftrace_alloc_record();
    record->ptr = ptr;
    record->frame_count = backtrace(record->frames, DFTRACE_BACKTRACE_DEPTH);
    record->next = dftrace_buckets[bucket];
    dftrace_buckets[bucket] = record;
}

__attribute__((constructor))
static void dftrace_init(void)
{
    dftrace_resolve_symbols();
}

void *malloc(size_t size)
{
    void *ptr;

    if (dftrace_reentrant)
        return real_malloc(size);

    dftrace_reentrant = true;
    dftrace_resolve_symbols();
    ptr = real_malloc(size);

    pthread_mutex_lock(&dftrace_lock);
    dftrace_remove_reused_pointer(ptr);
    pthread_mutex_unlock(&dftrace_lock);

    dftrace_reentrant = false;
    return ptr;
}

void *calloc(size_t count, size_t size)
{
    void *ptr;

    if (dftrace_reentrant)
        return real_calloc(count, size);

    dftrace_reentrant = true;
    dftrace_resolve_symbols();
    ptr = real_calloc(count, size);

    pthread_mutex_lock(&dftrace_lock);
    dftrace_remove_reused_pointer(ptr);
    pthread_mutex_unlock(&dftrace_lock);

    dftrace_reentrant = false;
    return ptr;
}

void *realloc(void *ptr, size_t size)
{
    void *new_ptr;

    if (dftrace_reentrant)
        return real_realloc(ptr, size);

    dftrace_reentrant = true;
    dftrace_resolve_symbols();

    pthread_mutex_lock(&dftrace_lock);
    if (ptr != NULL)
        dftrace_remove_reused_pointer(ptr);
    pthread_mutex_unlock(&dftrace_lock);

    new_ptr = real_realloc(ptr, size);

    pthread_mutex_lock(&dftrace_lock);
    dftrace_remove_reused_pointer(new_ptr);
    pthread_mutex_unlock(&dftrace_lock);

    dftrace_reentrant = false;
    return new_ptr;
}

void free(void *ptr)
{
    if (dftrace_reentrant) {
        real_free(ptr);
        return;
    }

    dftrace_reentrant = true;
    dftrace_resolve_symbols();

    pthread_mutex_lock(&dftrace_lock);
    dftrace_record_free(ptr);
    pthread_mutex_unlock(&dftrace_lock);

    real_free(ptr);
    dftrace_reentrant = false;
}
