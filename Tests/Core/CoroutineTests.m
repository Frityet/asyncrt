#import <AsyncRT/Common/Common.h>
#import <AsyncRT/Core/Coroutine.h>
#import <ObjFWTest/ObjFWTest.h>

#include <stdlib.h>

#pragma clang assume_nonnull begin

@interface CoroutineTests : OTTestCase
@end

static Coroutine<OFString *> *coroutineYieldingStrings(OFArray<OFString *> *strings, OFString *nillable returnValue)
{
    return [Coroutine fromBlock: ^OFString *(unretained Coroutine *co) {
        for (OFString *string in strings)
            [co yield: string];

        return returnValue;
    }];
}

@implementation CoroutineTests

- (void)assertCoroutine: (Coroutine *)co hasStatus: (enum CoroutineStatus)expected
{
    OTAssertEqual(co.status, expected, @"actual status %@, expected %@", describe(co.status), describe(expected));
}

- (CoroutineStateTransitionFailedException *)stateTransitionExceptionFromCoroutine: (Coroutine *)co
                                                                        operation: (void (^)(void))operation
{
    @try {
        operation();
    } @catch (CoroutineStateTransitionFailedException *exception) {
        return exception;
    }

    OTAssert(false, @"operation must throw CoroutineStateTransitionFailedException");
    __builtin_unreachable();
}

- (void)expectCoroutine: (Coroutine *)co
    throwsTransitionFrom: (enum CoroutineStatus)fromState
                      to: (enum CoroutineStatus)toState
               operation: (void (^)(void))operation
{
    CoroutineStateTransitionFailedException *exception =
        [self stateTransitionExceptionFromCoroutine: co operation: operation];

    OTAssertEqual(exception.coroutine, co, @"state transition exception must expose the offending coroutine");
    OTAssertEqual(exception.fromState, fromState, @"state transition exception must expose the source state");
    OTAssertEqual(exception.toState, toState, @"state transition exception must expose the requested destination state");
}

- (void)testInitialStateAndStackSize
{
    block_reference Coroutine *co = nilptr;
    co = [Coroutine fromBlock: ^id (unretained Coroutine *blockCoroutine) {
        OTAssertEqual(blockCoroutine, co, @"block must receive its coroutine instance");
        return @"unused";
    }];

    [self assertCoroutine: co hasStatus: CoroutineStatus_READY];
    OTAssertFalse(co.didYieldObject, @"new coroutine must not report a yielded object");
    OTAssertFalse(co.didReturnObject, @"new coroutine must not report a returned object");
    OTAssertNil(co.yieldedObject, @"new coroutine must not have a yielded object");
    OTAssertNil(co.returnedObject, @"new coroutine must not have a returned object");
    OTAssertGreaterThanOrEqual(co.stackSize, Coroutine.defaultStackSize,
        @"native stack must be at least the configured default stack size");
}

- (void)testFactoryReturnsReadyCoroutine
{
    block_reference Coroutine<OFNumber *> *co = nilptr;
    co = [Coroutine fromBlock: ^OFNumber *(unretained Coroutine *blockCoroutine) {
        OTAssertEqual(blockCoroutine, co, @"factory-created block must receive its coroutine");
        return @42;
    }];

    OTAssertTrue([co isKindOfClass: [Coroutine class]], @"factory must return a Coroutine instance");
    [self assertCoroutine: co hasStatus: CoroutineStatus_READY];
    OTAssertEqualObjects([co resume], @42, @"factory coroutine must return the block result");
    [self assertCoroutine: co hasStatus: CoroutineStatus_DEAD];
}

- (void)testExplicitYieldObjectTransitions
{
    Coroutine<OFString *> *co = [Coroutine fromBlock: ^OFString *(unretained Coroutine *blockCoroutine) {
        [self assertCoroutine: blockCoroutine hasStatus: CoroutineStatus_RUNNING];
        [blockCoroutine yield: @"first"];
        [self assertCoroutine: blockCoroutine hasStatus: CoroutineStatus_RUNNING];
        return @"done";
    }];

    OTAssertEqualObjects([co resume], @"first", @"first resume must return the yielded object");
    [self assertCoroutine: co hasStatus: CoroutineStatus_SUSPENDED];
    OTAssertTrue(co.didYieldObject, @"coroutine must record that an object was yielded");
    OTAssertFalse(co.didReturnObject, @"coroutine must not report return after a yield");
    OTAssertEqualObjects(co.yieldedObject, @"first", @"yieldedObject must retain the yielded object");
    OTAssertNil(co.returnedObject, @"returnedObject must remain empty after a yield");

    OTAssertEqualObjects([co resume], @"done", @"second resume must return the block result");
    [self assertCoroutine: co hasStatus: CoroutineStatus_DEAD];
    OTAssertFalse(co.didYieldObject, @"returning must clear didYieldObject");
    OTAssertTrue(co.didReturnObject, @"returning must set didReturnObject");
    OTAssertNil(co.yieldedObject, @"returning must clear yieldedObject");
    OTAssertEqualObjects(co.returnedObject, @"done", @"returnedObject must retain the block return value");
}

- (void)testExplicitYieldNilRecordsYield
{
    Coroutine *co = [Coroutine fromBlock: ^id (unretained Coroutine *blockCoroutine) {
        [blockCoroutine yield];
        return @"done";
    }];

    OTAssertNil([co resume], @"nil yield must resume to nil");
    [self assertCoroutine: co hasStatus: CoroutineStatus_SUSPENDED];
    OTAssertTrue(co.didYieldObject, @"nil yield must still record that yield occurred");
    OTAssertNil(co.yieldedObject, @"nil yield must leave yieldedObject nil");
    OTAssertFalse(co.didReturnObject, @"nil yield must not set didReturnObject");
}

- (void)testImplicitReturnValueAfterBlockCompletion
{
    Coroutine<OFString *> *co = [Coroutine fromBlock: ^OFString *(unretained Coroutine *blockCoroutine) {
        [self assertCoroutine: blockCoroutine hasStatus: CoroutineStatus_RUNNING];
        return @"implicit";
    }];

    OTAssertEqualObjects([co resume], @"implicit", @"resume must return the implicit block value");
    [self assertCoroutine: co hasStatus: CoroutineStatus_DEAD];
    OTAssertFalse(co.didYieldObject, @"implicit return must not mark didYieldObject");
    OTAssertTrue(co.didReturnObject, @"implicit return must mark didReturnObject");
    OTAssertEqualObjects(co.returnedObject, @"implicit", @"returnedObject must contain the implicit block value");
}

- (void)testImplicitReturnNilAfterBlockCompletion
{
    Coroutine *co = [Coroutine fromBlock: ^id (unretained Coroutine *blockCoroutine) {
        [self assertCoroutine: blockCoroutine hasStatus: CoroutineStatus_RUNNING];
        return nilptr;
    }];

    OTAssertNil([co resume], @"implicit nil return must resume to nil");
    [self assertCoroutine: co hasStatus: CoroutineStatus_DEAD];
    OTAssertFalse(co.didYieldObject, @"implicit nil return must not mark didYieldObject");
    OTAssertTrue(co.didReturnObject, @"implicit nil return must mark didReturnObject");
    OTAssertNil(co.returnedObject, @"implicit nil return must leave returnedObject nil");
}

- (void)testExplicitReturnValueStopsImmediately
{
    block_reference bool reachedAfterReturn = false;
    Coroutine<OFString *> *co = [Coroutine fromBlock: ^OFString *(unretained Coroutine *blockCoroutine) {
        [blockCoroutine return: @"explicit"];
        reachedAfterReturn = true;
        return @"wrong";
    }];

    OTAssertEqualObjects([co resume], @"explicit", @"resume must return explicit return value");
    OTAssertFalse(reachedAfterReturn, @"explicit return must not continue executing the block");
    [self assertCoroutine: co hasStatus: CoroutineStatus_DEAD];
    OTAssertFalse(co.didYieldObject, @"explicit return must clear didYieldObject");
    OTAssertTrue(co.didReturnObject, @"explicit return must set didReturnObject");
    OTAssertEqualObjects(co.returnedObject, @"explicit", @"returnedObject must contain explicit return value");
}

- (void)testExplicitReturnNilSetsReturnFlag
{
    Coroutine *co = [Coroutine fromBlock: ^id (unretained Coroutine *blockCoroutine) {
        [blockCoroutine return];
        return @"wrong";
    }];

    OTAssertNil([co resume], @"explicit nil return must resume to nil");
    [self assertCoroutine: co hasStatus: CoroutineStatus_DEAD];
    OTAssertFalse(co.didYieldObject, @"explicit nil return must clear yielded state");
    OTAssertTrue(co.didReturnObject, @"explicit nil return must set returned state");
    OTAssertNil(co.returnedObject, @"explicit nil return must leave returnedObject nil");
}

- (void)testMultipleYieldsThenImplicitReturn
{
    Coroutine<OFString *> *co = coroutineYieldingStrings(@[@"a", @"b", @"c"], @"done");

    OTAssertEqualObjects([co resume], @"a", @"resume 1 must return first yielded object");
    [self assertCoroutine: co hasStatus: CoroutineStatus_SUSPENDED];
    OTAssertEqualObjects([co resume], @"b", @"resume 2 must return second yielded object");
    [self assertCoroutine: co hasStatus: CoroutineStatus_SUSPENDED];
    OTAssertEqualObjects([co resume], @"c", @"resume 3 must return third yielded object");
    [self assertCoroutine: co hasStatus: CoroutineStatus_SUSPENDED];
    OTAssertEqualObjects([co resume], @"done", @"resume 4 must return the final value");
    [self assertCoroutine: co hasStatus: CoroutineStatus_DEAD];
}

- (void)testResumeClearsPreviousYieldState
{
    Coroutine<OFString *> *co = [Coroutine fromBlock: ^OFString *(unretained Coroutine *blockCoroutine) {
        [blockCoroutine yield: @"old"];
        return @"new";
    }];

    OTAssertEqualObjects([co resume], @"old", @"first resume must yield old value");
    OTAssertTrue(co.didYieldObject, @"first resume must mark yielded state");
    OTAssertEqualObjects(co.yieldedObject, @"old", @"first resume must expose old yielded object");

    OTAssertEqualObjects([co resume], @"new", @"second resume must return final value");
    OTAssertFalse(co.didYieldObject, @"second resume must clear previous yielded flag");
    OTAssertNil(co.yieldedObject, @"second resume must clear previous yielded object");
    OTAssertTrue(co.didReturnObject, @"second resume must mark returned state");
    OTAssertEqualObjects(co.returnedObject, @"new", @"second resume must expose returned object");
}

- (void)testResumeAfterDeadThrowsStateTransition
{
    Coroutine *co = [Coroutine fromBlock: ^id (unretained Coroutine *blockCoroutine) {
        (void)blockCoroutine;
        return @"done";
    }];

    OTAssertEqualObjects([co resume], @"done", @"first resume must complete coroutine");
    [self expectCoroutine: co throwsTransitionFrom: CoroutineStatus_DEAD to: CoroutineStatus_RUNNING operation: ^{
        [co resume];
    }];
}

- (void)testYieldBeforeResumeThrowsStateTransition
{
    Coroutine *co = [Coroutine fromBlock: ^id (unretained Coroutine *blockCoroutine) {
        (void)blockCoroutine;
        return @"unused";
    }];

    [self expectCoroutine: co throwsTransitionFrom: CoroutineStatus_READY to: CoroutineStatus_SUSPENDED operation: ^{
        [co yield: @"illegal"];
    }];
    [self assertCoroutine: co hasStatus: CoroutineStatus_READY];
}

- (void)testReturnBeforeResumeThrowsStateTransition
{
    Coroutine *co = [Coroutine fromBlock: ^id (unretained Coroutine *blockCoroutine) {
        (void)blockCoroutine;
        return @"unused";
    }];

    [self expectCoroutine: co throwsTransitionFrom: CoroutineStatus_READY to: CoroutineStatus_DEAD operation: ^{
        [co return: @"illegal"];
    }];
    [self assertCoroutine: co hasStatus: CoroutineStatus_READY];
}

- (void)testBlockExceptionPropagatesAndKillsCoroutine
{
    OFException *sentinel = [OFException exception];
    Coroutine *co = [Coroutine fromBlock: ^id (unretained Coroutine *blockCoroutine) {
        (void)blockCoroutine;
        @throw sentinel;
    }];

    bool caughtSentinel = false;
    @try {
        [co resume];
    } @catch (OFException *exception) {
        caughtSentinel = (exception == sentinel);
    }

    OTAssertTrue(caughtSentinel, @"resume must rethrow the exact exception raised inside the coroutine block");
    [self assertCoroutine: co hasStatus: CoroutineStatus_DEAD];
    OTAssertFalse(co.didYieldObject, @"exception propagation must clear yielded state");
    OTAssertFalse(co.didReturnObject, @"exception propagation must clear returned state");

    [self expectCoroutine: co throwsTransitionFrom: CoroutineStatus_DEAD to: CoroutineStatus_RUNNING operation: ^{
        [co resume];
    }];
}

- (void)testFastEnumerationCollectsYieldedObjects
{
    Coroutine<OFString *> *co = coroutineYieldingStrings(@[@"zero", @"one", @"two"], @"finished");
    OFMutableArray<OFString *> *collected = [OFMutableArray array];

    for (OFString *string in co)
        [collected addObject: string];

    OTAssertEqualObjects(collected, (@[@"zero", @"one", @"two"]), @"fast enumeration must collect every non-nil yielded object");
    [self assertCoroutine: co hasStatus: CoroutineStatus_DEAD];
    OTAssertTrue(co.didReturnObject, @"fast enumeration must leave final return state visible");
    OTAssertEqualObjects(co.returnedObject, @"finished", @"fast enumeration must preserve final returnedObject");
}

- (void)testFastEnumerationRejectsNilYield
{
    Coroutine *co = [Coroutine fromBlock: ^id (unretained Coroutine *blockCoroutine) {
        [blockCoroutine yield];
        return @"done";
    }];

    OTAssertThrowsSpecific({
        for (id object in co)
            (void)object;
    }, OFInvalidArgumentException, @"fast enumeration must reject nil-yielded values");

    [self assertCoroutine: co hasStatus: CoroutineStatus_SUSPENDED];
    OTAssertTrue(co.didYieldObject, @"nil yield rejected by enumeration must leave yielded state visible");
}

- (void)testFastEnumerationStopsOnReturnWithoutYield
{
    Coroutine<OFString *> *co = [Coroutine fromBlock: ^OFString *(unretained Coroutine *blockCoroutine) {
        (void)blockCoroutine;
        return @"not-enumerated";
    }];
    unsigned int count = 0;

    for (OFString *string in co) {
        (void)string;
        count++;
    }

    OTAssertEqual(count, 0, @"fast enumeration must not enumerate a final return value");
    [self assertCoroutine: co hasStatus: CoroutineStatus_DEAD];
    OTAssertTrue(co.didReturnObject, @"fast enumeration must expose immediate return state");
    OTAssertEqualObjects(co.returnedObject, @"not-enumerated", @"fast enumeration must preserve immediate returned value");
}

- (void)testDefaultStackSizeRoundTripAppliesToNewCoroutines
{
    size_t originalStackSize = Coroutine.defaultStackSize;
    size_t requestedStackSize = originalStackSize + 16384;

    Coroutine.defaultStackSize = requestedStackSize;
    @try {
        OTAssertEqual(Coroutine.defaultStackSize, requestedStackSize, @"defaultStackSize setter must round-trip exactly");

        Coroutine *co = [Coroutine fromBlock: ^id (unretained Coroutine *blockCoroutine) {
            (void)blockCoroutine;
            return nilptr;
        }];
        OTAssertGreaterThanOrEqual(co.stackSize, requestedStackSize,
            @"new coroutine must use the updated default stack size");
    } @finally {
        Coroutine.defaultStackSize = originalStackSize;
    }

    OTAssertEqual(Coroutine.defaultStackSize, originalStackSize, @"defaultStackSize must be restored after test");
}

- (void)testTooSmallStackThrowsStackSetupException
{
    bool caught = false;

    @try {
        (void)[[Coroutine alloc] initWithBlock: ^id (unretained Coroutine *blockCoroutine) {
            (void)blockCoroutine;
            return nilptr;
        } stackSize: 0];
    } @catch (CoroutineStackSetupFailedException *exception) {
        caught = true;
        OTAssertEqualObjects(exception.operation, @"mco_desc_init", @"small stack failure must identify descriptor setup");
        OTAssertEqual(exception.errorCode, EINVAL, @"small stack failure must expose EINVAL");
    }

    OTAssertTrue(caught, @"too-small stack must throw CoroutineStackSetupFailedException");
}

- (void)testNestedCoroutinesRestoreOuterExecution
{
    Coroutine<OFString *> *outer = [Coroutine fromBlock: ^OFString *(unretained Coroutine *outerCoroutine) {
        Coroutine<OFString *> *inner = [Coroutine fromBlock: ^OFString *(unretained Coroutine *innerCoroutine) {
            [innerCoroutine yield: @"inner-yield"];
            return @"inner-return";
        }];

        OTAssertEqualObjects([inner resume], @"inner-yield", @"outer coroutine must be able to resume inner coroutine to yield");
        [self assertCoroutine: outerCoroutine hasStatus: CoroutineStatus_RUNNING];
        [self assertCoroutine: inner hasStatus: CoroutineStatus_SUSPENDED];
        [outerCoroutine yield: @"outer-yield"];
        [self assertCoroutine: outerCoroutine hasStatus: CoroutineStatus_RUNNING];
        OTAssertEqualObjects([inner resume], @"inner-return", @"outer coroutine must be able to resume inner coroutine to completion");
        [self assertCoroutine: inner hasStatus: CoroutineStatus_DEAD];
        return @"outer-return";
    }];

    OTAssertEqualObjects([outer resume], @"outer-yield", @"root resume must receive the outer yield");
    [self assertCoroutine: outer hasStatus: CoroutineStatus_SUSPENDED];
    OTAssertEqualObjects([outer resume], @"outer-return", @"root resume must receive the outer return");
    [self assertCoroutine: outer hasStatus: CoroutineStatus_DEAD];
}

- (void)testExceptionDescriptionsIncludeContext
{
    Coroutine *co = [Coroutine fromBlock: ^id (unretained Coroutine *blockCoroutine) {
        (void)blockCoroutine;
        return nilptr;
    }];

    CoroutineStateTransitionFailedException *stateException =
        [[[CoroutineStateTransitionFailedException alloc] initWithCoroutine: co fromState: CoroutineStatus_READY toState: CoroutineStatus_RUNNING] autorelease];
    OTAssertTrue([[stateException description] containsString: @"ready"], @"state exception description must include source state");
    OTAssertTrue([[stateException description] containsString: @"running"], @"state exception description must include destination state");
    OTAssertEqual(stateException.coroutine, co, @"state exception must expose coroutine");

    CoroutineMissingCallerException *missingCallerException =
        [[[CoroutineMissingCallerException alloc] initWithCoroutine: co operation: @"yield"] autorelease];
    OTAssertTrue([[missingCallerException description] containsString: @"yield"], @"missing caller description must include operation");
    OTAssertEqual(missingCallerException.coroutine, co, @"missing caller exception must expose coroutine");

    CoroutineStackSetupFailedException *stackException =
        [[[CoroutineStackSetupFailedException alloc] initWithCoroutine: co operation: @"mco_create" errorCode: 123] autorelease];
    OTAssertTrue([[stackException description] containsString: @"mco_create"], @"stack setup description must include operation");
    OTAssertTrue([[stackException description] containsString: @"123"], @"stack setup description must include error code");
    OTAssertEqual(stackException.coroutine, co, @"stack setup exception must expose coroutine");
}

@end

@interface CoroutineTestApplication : OFObject<OFApplicationDelegate>
@end

@implementation CoroutineTestApplication

- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
    (void)notification;

    OFArray<OFString *> *arguments = OFApplication.arguments;
    if (arguments.count != 1) {
        [OFStdErr writeFormat: @"Expected exactly one ObjFWTest selector, got %zu\n", arguments.count];
        [OFApplication terminateWithStatus: EXIT_FAILURE];
    }

    OFString *selectorName = [arguments objectAtIndex: 0];
    SEL selector = sel_registerName(selectorName.UTF8String);
    CoroutineTests *testCase = [[[CoroutineTests alloc] init] autorelease];

    if (selector == NULL || ![testCase respondsToSelector: selector]) {
        [OFStdErr writeFormat: @"Unknown CoroutineTests selector: %@\n", selectorName];
        [OFApplication terminateWithStatus: EXIT_FAILURE];
    }

    @try {
        [testCase setUp];
        @try {
            [testCase performSelector: selector];
        } @finally {
            [testCase tearDown];
        }
    } @catch (id exception) {
        [OFStdErr writeFormat: @"FAIL -[CoroutineTests %@]: %@\n", selectorName, exception];
        [OFApplication terminateWithStatus: EXIT_FAILURE];
    }

    [OFStdOut writeFormat: @"ok -[CoroutineTests %@]\n", selectorName];
    [OFApplication terminateWithStatus: EXIT_SUCCESS];
}

@end

#pragma clang assume_nonnull end

OF_APPLICATION_DELEGATE(CoroutineTestApplication)
