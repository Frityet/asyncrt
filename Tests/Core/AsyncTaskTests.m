#import <AsyncRT/Core/AsyncTask.h>
#import <ObjFWTest/ObjFWTest.h>

#pragma clang assume_nonnull begin

@interface AsyncTaskTests : OTTestCase
@end

@implementation AsyncTaskTests

- (void)testSpawnRunsBlockAndResolves
{
    auto task = [AsyncTask<OFNumber *> spawn: ^{
        return @42;
    }];

    OTAssertEqualObjects([task await], @42, @"spawned task must resolve with block result");
    OTAssertEqual(task.status, AsyncTaskStatus_RESOLVED, @"awaited task must be resolved");
    OTAssertTrue(task.isComplete, @"resolved task must be complete");
}

- (void)testCompletionSourceResolve
{
    auto source = [[AsyncTaskCompletionSource<OFString *> alloc] init];

    [source resolveWithResult: @"done"];

    OTAssertEqualObjects([source.task await], @"done", @"completion source must resolve its task");
    OTAssertEqual(source.task.status, AsyncTaskStatus_RESOLVED, @"resolved completion source task must expose resolved status");
}

- (void)testRejectedTaskThrowsStoredError
{
    OFException *error = [OFException exception];
    AsyncTask *task = [AsyncTask rejectedWithError: error];
    block_reference bool didThrow = false;

    @try {
        [task await];
    } @catch (OFException *caught) {
        didThrow = true;
        OTAssertEqual(caught, error, @"await must throw the stored rejection error");
    }

    OTAssertTrue(didThrow, @"awaiting a rejected task must throw");
}

- (void)testCompletionSourceCancelThrowsCancelledException
{
    auto source = [[AsyncTaskCompletionSource alloc] init];
    block_reference bool didThrow = false;

    [source cancel];

    @try {
        [source.task await];
    } @catch (AsyncTaskCancelledException *exception) {
        didThrow = true;
        OTAssertEqual(exception.task, source.task, @"cancel exception must expose the cancelled task");
    }

    OTAssertTrue(didThrow, @"awaiting a cancelled task must throw");
    OTAssertTrue(source.task.isCancelled, @"cancelled task must expose cancelled state");
    OTAssertTrue(source.task.isComplete, @"cancelled task must be complete");
}

- (void)testAwaitInsideExecutorTaskCanRunNestedTask
{
    auto outer = [AsyncTask<OFString *> spawn: ^{
        auto inner = [AsyncTask<OFString *> spawn: ^{
            return @"inner";
        }];

        return [inner await];
    }];

    OTAssertEqualObjects([outer await], @"inner", @"task await must allow nested executor work to make progress");
}

- (void)testAllCollectsResultsInInputOrder
{
    auto firstSource = [[AsyncTaskCompletionSource<OFString *> alloc] init];
    auto secondSource = [[AsyncTaskCompletionSource<OFString *> alloc] init];
    auto all = [AsyncTask<OFString *> all: @[
        firstSource.task,
        secondSource.task
    ]];

    [secondSource resolveWithResult: @"second"];
    OTAssertTrue(all.isPending,
        @"all must wait for every child task rather than the first completion");

    [firstSource resolveWithResult: @"first"];
    OTAssertEqualObjects([all await], (@[ @"first", @"second" ]),
        @"all must preserve the input task order");
}

- (void)testAllPropagatesChildRejection
{
    auto source = [[AsyncTaskCompletionSource<OFString *> alloc] init];
    auto all = [AsyncTask<OFString *> all: @[ source.task ]];
    auto error = [OFException exception];
    block_reference bool didThrow = false;

    [source rejectWithError: error];

    @try {
        [all await];
    } @catch (OFException *caught) {
        didThrow = true;
        OTAssertEqual(caught, error,
            @"all must propagate the child rejection error");
    }

    OTAssertTrue(didThrow, @"all must reject when a child task rejects");
}

- (void)testAllResolvesEmptyInput
{
    auto all = [AsyncTask<OFString *> all: @[]];
    auto results = [all await];

    OTAssertEqual(results.count, 0,
        @"all must resolve with an empty result list for empty input");
    OTAssertEqual(all.status, AsyncTaskStatus_RESOLVED,
        @"all must resolve immediately for empty input");
}

- (void)testAnyResolvesWithFirstCompletedIndex
{
    auto firstSource = [[AsyncTaskCompletionSource<OFString *> alloc] init];
    auto secondSource = [[AsyncTaskCompletionSource<OFString *> alloc] init];
    auto any = [AsyncTask<OFString *> any: @[
        firstSource.task,
        secondSource.task
    ]];

    [secondSource resolveWithResult: @"second"];

    OTAssertEqualObjects([any await], @1,
        @"any must resolve with the first completed task index");
}

- (void)testCompletionFromAnotherThreadWakesNonCoroutineAwait
{
    auto source = [[AsyncTaskCompletionSource<OFString *> alloc] init];
    OFThread *worker = [OFThread threadWithBlock: ^ id nillable {
        [OFThread sleepForTimeInterval: 0.01];
        [source resolveWithResult: @"cross-thread"];
        return nilptr;
    }];
    [worker start];

    OTAssertEqualObjects([source.task await], @"cross-thread",
        @"cross-thread completion must wake a run-loop-backed await");
    [worker join];
}

@end

#pragma clang assume_nonnull end
