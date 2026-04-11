#include <pthread.h>
#import "Async/AsyncRuntimeInternal.h"

#pragma clang assume_nonnull begin

thread_local unretained Task *nillable async_current_task;
thread_local unretained AsyncScheduler *nillable async_current_scheduler;
thread_local unretained AsyncScope *nillable async_current_scope;

#if defined(__has_feature)
# if __has_feature(thread_sanitizer)
#  define ASYNC_RUNTIME_HAVE_TSAN 1
# endif
#endif

#if defined(__SANITIZE_THREAD__)
# define ASYNC_RUNTIME_HAVE_TSAN 1
#endif

#if defined(ASYNC_RUNTIME_HAVE_TSAN)
static pthread_mutex_t async_tsan_keepalive_lock = PTHREAD_MUTEX_INITIALIZER;
static OFMutableArray<id> *nillable async_tsan_keepalive_objects;
#endif

OFString *PromiseStatusToString(enum PromiseStatus status)
{
    switch (status) {
        case PromiseStatus_PENDING: return @"PENDING";
        case PromiseStatus_FULFILLED: return @"FULFILLED";
        case PromiseStatus_REJECTED: return @"REJECTED";
    }
}

OFString *DescribePromise(Promise *nillable future)
{
    if (future == nilptr)
        return @"<nil>";

    return [OFString stringWithFormat: @"%p (%@)", future, PromiseStatusToString(future.status)];
}

OFString *DescribeScheduler(AsyncScheduler *nillable scheduler)
{
    if (scheduler == nilptr)
        return @"<nil>";

    return [OFString stringWithFormat: @"%p (%@)", scheduler, scheduler.mode];
}

OFString *TaskExecutionStateToString(enum AsyncTaskExecutionState state)
{
    switch (state) {
        case AsyncTaskExecutionState_READY: return @"READY";
        case AsyncTaskExecutionState_RUNNING: return @"RUNNING";
        case AsyncTaskExecutionState_WAITING: return @"WAITING";
        case AsyncTaskExecutionState_RESOLVED: return @"RESOLVED";
    }
}

void AsyncRetainForTSAN(id nillable object)
{
#if !defined(ASYNC_RUNTIME_HAVE_TSAN)
    (void)object;
#else
    if (object == nilptr)
        return;

    pthread_mutex_lock(&async_tsan_keepalive_lock);

    if (async_tsan_keepalive_objects == nilptr)
        async_tsan_keepalive_objects = [OFMutableArray array];

    [async_tsan_keepalive_objects addObject: $assert_nonnil(object)];

    pthread_mutex_unlock(&async_tsan_keepalive_lock);
#endif
}

@implementation AsyncTaskWaitRegistration

@synthesize scheduler = _scheduler;
@synthesize task = _task;

- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (Task *)task
{
    self = [super init];
    _scheduler = scheduler;
    _task = task;
    return self;
}

- (void)arm
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (void)cancel
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

@end

@implementation AsyncWaitInstruction {
    AsyncTaskWaitRegistration *_registration;
    OFString *_waitReason;
}

@synthesize registration = _registration;
@synthesize waitReason = _waitReason;

- (instancetype)initWithRegistration: (AsyncTaskWaitRegistration *)registration waitReason: (OFString *)waitReason
{
    self = [super init];
    _registration = registration;
    _waitReason = [waitReason copy];
    return self;
}

@end

@implementation AsyncPromiseCompletion {
    id nillable _value;
    OFException *nillable _exception;
}

@synthesize value = _value;
@synthesize exception = _exception;

- (instancetype)initWithValue: (id)value
{
    self = [super init];
    _value = value;
    return self;
}

- (instancetype)initWithException: (OFException *)exception
{
    self = [super init];
    _exception = exception;
    return self;
}

@end

#pragma clang assume_nonnull end
