#import <AsyncRT/Core/AsyncTask.h>
#import <ObjFWTest/ObjFWTest.h>

#pragma clang assume_nonnull begin

@interface AsyncTaskTests : OTTestCase
@end

@implementation AsyncTaskTests

- (void)testSpawnRunsBlockAndResolves
{
    AsyncTask<OFNumber *> *task = [AsyncTask spawn: ^OFNumber *{
        return @42;
    }];

    OTAssertEqualObjects([task await], @42, @"spawned task must resolve with block result");
    OTAssertEqual(task.status, AsyncTaskStatus_RESOLVED, @"awaited task must be resolved");
    OTAssertTrue(task.isComplete, @"resolved task must be complete");
}

- (void)testCompletionSourceResolve
{
    AsyncTaskCompletionSource<OFString *> *source = [[AsyncTaskCompletionSource alloc] init];

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
    AsyncTaskCompletionSource *source = [[AsyncTaskCompletionSource alloc] init];
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
    AsyncTask<OFString *> *outer = [AsyncTask spawn: ^OFString *{
        AsyncTask<OFString *> *inner = [AsyncTask spawn: ^OFString *{
            return @"inner";
        }];

        return [inner await];
    }];

    OTAssertEqualObjects([outer await], @"inner", @"task await must allow nested executor work to make progress");
}

@end

#pragma clang assume_nonnull end
