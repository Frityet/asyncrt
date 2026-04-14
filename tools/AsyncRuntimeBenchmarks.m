#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#import "AsyncRuntime.h"

#pragma clang assume_nonnull begin

typedef struct {
    const char *name;
    const char *unit;
    size_t operationsPerInvocation;
    void (*invoke)(AsyncTaskGroup *rootTaskGroup);
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
    task_map_chain_rounds = 64,
    task_map_chain_depth = 512,
    task_all_resolved_rounds = 128,
    task_all_resolved_batch_size = 1024,
    task_all_trivial_tasks_rounds = 24,
    task_all_trivial_tasks_batch_size = 128,
    taskGroup_spawn_all_rounds = 24,
    taskGroup_spawn_all_batch_size = 128,
    channel_ping_pong_message_count = 40000,
    scheduler_offload_roundtrips = 4000
};

static void benchmark_task_map_chain(AsyncTaskGroup *rootTaskGroup)
{
    (void)rootTaskGroup;

    for (size_t round = 0; round < task_map_chain_rounds; round++) {
        Task *task = [Task resolved: AsyncUnit.unit];

        for (size_t depth = 0; depth < task_map_chain_depth; depth++) {
            task = [task map: ^id(id value) {
                return value;
            }];
        }

        [task await];
    }
}

static void benchmark_task_all_resolved(AsyncTaskGroup *rootTaskGroup)
{
    (void)rootTaskGroup;
    auto inputs = [OFMutableArray<Task *> arrayWithCapacity: task_all_resolved_batch_size];

    for (size_t index = 0; index < task_all_resolved_batch_size; index++)
        [inputs addObject: [Task resolved: AsyncUnit.unit]];

    OFArray<Task *> *resolvedInputs = [inputs copy];

    for (size_t round = 0; round < task_all_resolved_rounds; round++)
        [[Task all: resolvedInputs] await];
}

static void benchmark_task_all_trivial_tasks(AsyncTaskGroup *rootTaskGroup)
{
    id (^trivialBlock)(void) = ^{
        return AsyncUnit.unit;
    };

    for (size_t round = 0; round < task_all_trivial_tasks_rounds; round++) {
        auto tasks = [OFMutableArray<Task *> arrayWithCapacity: task_all_trivial_tasks_batch_size];

        for (size_t index = 0; index < task_all_trivial_tasks_batch_size; index++)
            [tasks addObject: [rootTaskGroup spawnTask: trivialBlock]];

        [[Task all: tasks] await];
    }
}

static void benchmark_task_group_spawn_all_trivial(AsyncTaskGroup *rootTaskGroup)
{
    auto blocks = [OFMutableArray<id (^)(void)> arrayWithCapacity: taskGroup_spawn_all_batch_size];
    id (^trivialBlock)(void) = ^{
        return AsyncUnit.unit;
    };

    for (size_t index = 0; index < taskGroup_spawn_all_batch_size; index++)
        [blocks addObject: trivialBlock];

    OFArray<id (^)(void)> *trivialBlocks = [blocks copy];

    for (size_t round = 0; round < taskGroup_spawn_all_rounds; round++)
        [[rootTaskGroup spawnAllTasks: trivialBlocks] await];
}

static void benchmark_channel_ping_pong(AsyncTaskGroup *rootTaskGroup)
{
    auto channel = [[AsyncChannel<id> alloc] initWithCapacity: 0];

    (void)[rootTaskGroup performInChildTaskGroupNamed: @"bench-channel" block: ^id(AsyncTaskGroup *taskGroup) {
        [taskGroup spawnTask: ^{
            for (size_t messageIndex = 0; messageIndex < channel_ping_pong_message_count; messageIndex++)
                [channel send: AsyncUnit.unit];

            return AsyncUnit.unit;
        } name: @"bench-channel-producer"];

        [taskGroup spawnTask: ^{
            for (size_t messageIndex = 0; messageIndex < channel_ping_pong_message_count; messageIndex++)
                (void)channel.receive;

            return AsyncUnit.unit;
        } name: @"bench-channel-consumer"];

        return AsyncUnit.unit;
    }];
}

static void benchmark_scheduler_offload_roundtrip(AsyncTaskGroup *rootTaskGroup)
{
    auto scheduler = rootTaskGroup.scheduler;

    for (size_t iteration = 0; iteration < scheduler_offload_roundtrips; iteration++)
        (void)[scheduler offload: ^{
            return AsyncUnit.unit;
        }].await;
}

static BenchmarkScenario benchmark_scenarios[] = {
    {.name = "task-map-chain", .unit = "continuations", .operationsPerInvocation = task_map_chain_rounds * task_map_chain_depth, .invoke = benchmark_task_map_chain},
    {.name = "task-all-resolved", .unit = "tasks", .operationsPerInvocation = task_all_resolved_rounds * task_all_resolved_batch_size, .invoke = benchmark_task_all_resolved},
    {.name = "task-all-trivial-tasks", .unit = "tasks", .operationsPerInvocation = task_all_trivial_tasks_rounds * task_all_trivial_tasks_batch_size, .invoke = benchmark_task_all_trivial_tasks},
    {.name = "task-group-spawn-all-trivial", .unit = "tasks", .operationsPerInvocation = taskGroup_spawn_all_rounds * taskGroup_spawn_all_batch_size, .invoke = benchmark_task_group_spawn_all_trivial},
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

static BenchmarkSample measure_scenario(BenchmarkScenario *scenario, AsyncTaskGroup *rootTaskGroup, double seconds)
{
    uint64_t startNanoseconds = monotonic_nanoseconds();
    uint64_t minimumNanoseconds = (uint64_t)(seconds * 1000000000.0);
    size_t totalOperations = 0;
    size_t invocationCount = 0;
    uint64_t elapsedNanoseconds = 0;

    do {
        scenario->invoke(rootTaskGroup);
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

static void print_scenario_summary(BenchmarkScenario *scenario, AsyncTaskGroup *rootTaskGroup, double seconds, size_t sampleCount)
{
    double rates[16];
    double nanosecondsPerOperation[16];

    if (sampleCount > 16)
        @throw [OFOutOfRangeException exception];

    scenario->invoke(rootTaskGroup);

    printf("scenario=%s unit=%s target_seconds_per_sample=%.2f samples=%zu\n",
           scenario->name,
           scenario->unit,
           seconds,
           sampleCount);

    for (size_t sampleIndex = 0; sampleIndex < sampleCount; sampleIndex++) {
        BenchmarkSample sample = measure_scenario(scenario, rootTaskGroup, seconds);
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

[[subclassing_restricted]]
@interface AsyncRuntimeBenchmarksApp : AsyncApplication @end

@implementation AsyncRuntimeBenchmarksApp

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification
                               taskGroup: (AsyncTaskGroup *)rootTaskGroup
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
            print_scenario_summary(&benchmark_scenarios[index], rootTaskGroup, secondsPerSample, sampleCount);

        return AsyncUnit.unit;
    }

    BenchmarkScenario *nillable scenario = find_scenario(selectedScenario);

    if (scenario == nullptr) {
        print_usage(program);
        return @1;
    }

    print_scenario_summary($assert_nonnil(scenario), rootTaskGroup, secondsPerSample, sampleCount);
    return AsyncUnit.unit;
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-inferred-on-nested-type"
ASYNC_APPLICATION_DELEGATE(AsyncRuntimeBenchmarksApp);
#pragma clang diagnostic pop

#pragma clang assume_nonnull end
