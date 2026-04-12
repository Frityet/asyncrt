#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#import "Async/AsyncRuntime.h"

#pragma clang assume_nonnull begin

typedef struct {
    const char *name;
    const char *unit;
    size_t operationsPerInvocation;
    void (*invoke)(AsyncScope *rootScope);
} BenchmarkScenario;

typedef struct {
    uint64_t elapsedNanoseconds;
    size_t totalOperations;
    size_t invocationCount;
} BenchmarkSample;

static const size_t benchmark_sample_count_default = 5;

static uint64_t monotonic_nanoseconds(void)
{
    struct timespec ts;

    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ((uint64_t)ts.tv_sec * 1000000000ull) + (uint64_t)ts.tv_nsec;
}

enum {
    promise_map_chain_rounds = 64,
    promise_map_chain_depth = 512,
    promise_all_resolved_rounds = 128,
    promise_all_resolved_batch_size = 1024,
    promise_all_trivial_tasks_rounds = 24,
    promise_all_trivial_tasks_batch_size = 128,
    scope_spawn_all_rounds = 24,
    scope_spawn_all_batch_size = 128,
    channel_ping_pong_message_count = 40000,
    scheduler_offload_roundtrips = 4000
};

static void benchmark_promise_map_chain(AsyncScope *rootScope)
{
    (void)rootScope;

    for (size_t round = 0; round < promise_map_chain_rounds; round++) {
        Promise *promise = [Promise resolved: AsyncUnit.unit];

        for (size_t depth = 0; depth < promise_map_chain_depth; depth++) {
            promise = [promise map: ^id(id value) {
                return value;
            }];
        }

        [promise await];
    }
}

static void benchmark_promise_all_resolved(AsyncScope *rootScope)
{
    (void)rootScope;
    auto inputs = [OFMutableArray<id<PromiseLike>> arrayWithCapacity: promise_all_resolved_batch_size];

    for (size_t index = 0; index < promise_all_resolved_batch_size; index++)
        [inputs addObject: [Promise resolved: AsyncUnit.unit]];

    OFArray<id<PromiseLike>> *resolvedInputs = [inputs copy];

    for (size_t round = 0; round < promise_all_resolved_rounds; round++)
        [[Promise all: resolvedInputs] await];
}

static void benchmark_promise_all_trivial_tasks(AsyncScope *rootScope)
{
    id (^trivialBlock)(void) = ^{
        return AsyncUnit.unit;
    };

    for (size_t round = 0; round < promise_all_trivial_tasks_rounds; round++) {
        auto promises = [OFMutableArray<id<PromiseLike>> arrayWithCapacity: promise_all_trivial_tasks_batch_size];

        for (size_t index = 0; index < promise_all_trivial_tasks_batch_size; index++)
            [promises addObject: [rootScope spawn: trivialBlock]];

        [[Promise all: promises] await];
    }
}

static void benchmark_scope_spawn_all_trivial(AsyncScope *rootScope)
{
    auto blocks = [OFMutableArray<id (^)(void)> arrayWithCapacity: scope_spawn_all_batch_size];
    id (^trivialBlock)(void) = ^{
        return AsyncUnit.unit;
    };

    for (size_t index = 0; index < scope_spawn_all_batch_size; index++)
        [blocks addObject: trivialBlock];

    OFArray<id (^)(void)> *trivialBlocks = [blocks copy];

    for (size_t round = 0; round < scope_spawn_all_rounds; round++)
        [[rootScope spawnAll: trivialBlocks] await];
}

static void benchmark_channel_ping_pong(AsyncScope *rootScope)
{
    auto channel = [[AsyncChannel<id> alloc] initWithCapacity: 0];

    (void)[rootScope withChildScopeNamed: @"bench-channel" block: ^id(AsyncScope *scope) {
        [scope spawn: ^{
            for (size_t messageIndex = 0; messageIndex < channel_ping_pong_message_count; messageIndex++)
                [channel send: AsyncUnit.unit];

            return AsyncUnit.unit;
        } name: @"bench-channel-producer"];

        [scope spawn: ^{
            for (size_t messageIndex = 0; messageIndex < channel_ping_pong_message_count; messageIndex++)
                (void)channel.receive;

            return AsyncUnit.unit;
        } name: @"bench-channel-consumer"];

        return AsyncUnit.unit;
    }];
}

static void benchmark_scheduler_offload_roundtrip(AsyncScope *rootScope)
{
    AsyncScheduler *scheduler = rootScope.scheduler;

    for (size_t iteration = 0; iteration < scheduler_offload_roundtrips; iteration++)
        (void)[scheduler offload: ^{
            return AsyncUnit.unit;
        }].await;
}

static BenchmarkScenario benchmark_scenarios[] = {
    {.name = "promise-map-chain", .unit = "continuations", .operationsPerInvocation = promise_map_chain_rounds * promise_map_chain_depth, .invoke = benchmark_promise_map_chain},
    {.name = "promise-all-resolved", .unit = "promises", .operationsPerInvocation = promise_all_resolved_rounds * promise_all_resolved_batch_size, .invoke = benchmark_promise_all_resolved},
    {.name = "promise-all-trivial-tasks", .unit = "tasks", .operationsPerInvocation = promise_all_trivial_tasks_rounds * promise_all_trivial_tasks_batch_size, .invoke = benchmark_promise_all_trivial_tasks},
    {.name = "scope-spawn-all-trivial", .unit = "tasks", .operationsPerInvocation = scope_spawn_all_rounds * scope_spawn_all_batch_size, .invoke = benchmark_scope_spawn_all_trivial},
    {.name = "channel-ping-pong", .unit = "messages", .operationsPerInvocation = channel_ping_pong_message_count, .invoke = benchmark_channel_ping_pong},
    {.name = "scheduler-offload-roundtrip", .unit = "roundtrips", .operationsPerInvocation = scheduler_offload_roundtrips, .invoke = benchmark_scheduler_offload_roundtrip},
};

static int compare_doubles(const void *left, const void *right)
{
    double lhs = *(const double *)left;
    double rhs = *(const double *)right;

    if (lhs < rhs)
        return -1;
    if (lhs > rhs)
        return 1;
    return 0;
}

static BenchmarkScenario *nillable find_scenario(const char *name)
{
    for (size_t index = 0; index < sizeof(benchmark_scenarios) / sizeof(benchmark_scenarios[0]); index++) {
        if (strcmp(benchmark_scenarios[index].name, name) == 0)
            return &benchmark_scenarios[index];
    }

    return nullptr;
}

static BenchmarkSample measure_scenario(BenchmarkScenario *scenario, AsyncScope *rootScope, double seconds)
{
    uint64_t startNanoseconds = monotonic_nanoseconds();
    uint64_t minimumNanoseconds = (uint64_t)(seconds * 1000000000.0);
    size_t totalOperations = 0;
    size_t invocationCount = 0;
    uint64_t elapsedNanoseconds = 0;

    do {
        scenario->invoke(rootScope);
        invocationCount++;
        totalOperations += scenario->operationsPerInvocation;
        elapsedNanoseconds = monotonic_nanoseconds() - startNanoseconds;
    } while (elapsedNanoseconds < minimumNanoseconds);

    return (BenchmarkSample){
        .elapsedNanoseconds = elapsedNanoseconds,
        .totalOperations = totalOperations,
        .invocationCount = invocationCount
    };
}

static void print_scenario_summary(BenchmarkScenario *scenario, AsyncScope *rootScope, double seconds, size_t sampleCount)
{
    double rates[16];
    double nanosecondsPerOperation[16];

    if (sampleCount > 16)
        @throw [OFOutOfRangeException exception];

    scenario->invoke(rootScope);

    printf("scenario=%s unit=%s target_seconds_per_sample=%.2f samples=%zu\n",
           scenario->name,
           scenario->unit,
           seconds,
           sampleCount);

    for (size_t sampleIndex = 0; sampleIndex < sampleCount; sampleIndex++) {
        BenchmarkSample sample = measure_scenario(scenario, rootScope, seconds);
        double elapsedSeconds = (double)sample.elapsedNanoseconds / 1000000000.0;
        double rate = (double)sample.totalOperations / elapsedSeconds;
        double nsPerOperation = (double)sample.elapsedNanoseconds / (double)sample.totalOperations;

        rates[sampleIndex] = rate;
        nanosecondsPerOperation[sampleIndex] = nsPerOperation;

        printf("  sample=%zu elapsed=%.3fs invocations=%zu operations=%zu rate=%.0f_%s_per_s ns_per_%s=%.1f\n",
               sampleIndex + 1,
               elapsedSeconds,
               sample.invocationCount,
               sample.totalOperations,
               rate,
               scenario->unit,
               scenario->unit,
               nsPerOperation);
    }

    qsort(rates, sampleCount, sizeof(double), compare_doubles);
    qsort(nanosecondsPerOperation, sampleCount, sizeof(double), compare_doubles);

    printf("  summary median_rate=%.0f_%s_per_s min_rate=%.0f max_rate=%.0f median_ns_per_%s=%.1f\n\n",
           rates[sampleCount / 2],
           scenario->unit,
           rates[0],
           rates[sampleCount - 1],
           scenario->unit,
           nanosecondsPerOperation[sampleCount / 2]);
}

static void print_usage(const char *program)
{
    printf("usage: %s [all|scenario] [seconds_per_sample] [sample_count]\n", program);
    printf("scenarios:\n");

    for (size_t index = 0; index < sizeof(benchmark_scenarios) / sizeof(benchmark_scenarios[0]); index++)
        printf("  %s\n", benchmark_scenarios[index].name);
}

@interface AsyncRuntimeBenchmarksApp : AsyncApplication @end

@implementation AsyncRuntimeBenchmarksApp

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification scope: (AsyncScope *)rootScope
{
    (void)notification;

    OFArray<OFString *> *arguments = OFApplication.arguments ?: @[];
    const char *program = (OFApplication.programName != nilptr ? OFApplication.programName.UTF8String : "async-runtime-benchmarks");
    const char *selectedScenario = (arguments.count >= 1 ? arguments[0].UTF8String : "all");
    double secondsPerSample = (arguments.count >= 2 ? strtod(arguments[1].UTF8String, nullptr) : 1.0);
    size_t sampleCount = (arguments.count >= 3 ? (size_t)strtoull(arguments[2].UTF8String, nullptr, 10) : benchmark_sample_count_default);

    if (secondsPerSample <= 0 or sampleCount == 0) {
        print_usage(program);
        return @1;
    }

    if (strcmp(selectedScenario, "all") == 0) {
        for (size_t index = 0; index < sizeof(benchmark_scenarios) / sizeof(benchmark_scenarios[0]); index++)
            print_scenario_summary(&benchmark_scenarios[index], rootScope, secondsPerSample, sampleCount);

        return AsyncUnit.unit;
    }

    BenchmarkScenario *nillable scenario = find_scenario(selectedScenario);

    if (scenario == nullptr) {
        print_usage(program);
        return @1;
    }

    print_scenario_summary($assert_nonnil(scenario), rootScope, secondsPerSample, sampleCount);
    return AsyncUnit.unit;
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-inferred-on-nested-type"
ASYNC_APPLICATION_DELEGATE(AsyncRuntimeBenchmarksApp);
#pragma clang diagnostic pop

#pragma clang assume_nonnull end
