#pragma once

#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#import <ObjFWTest/ObjFWTest.h>
#import "Async/AsyncRuntime.h"
#import "Async/AsyncRuntimeInternal.h"
#import "Async/Coroutine.h"
#import "Utilities/Optional.h"
#import "Utilities/Pointer.h"
#import "Utilities/Signal.h"

#pragma clang assume_nonnull begin

@interface AsyncRuntimeTestCase : OTTestCase

- (void)runAsyncBlock: (void (^)(AsyncScope *rootScope))block;

@end

#define ASYNC_RUNTIME_SYNC_TEST(Name) \
    @interface test_##Name : AsyncRuntimeTestCase @end \
    @implementation test_##Name \
    - (void)test_case \
    { \
        Name(); \
    } \
    @end

#define ASYNC_RUNTIME_ASYNC_TEST(Name) \
    @interface test_##Name : AsyncRuntimeTestCase @end \
    @implementation test_##Name \
    - (void)test_case \
    { \
        [self runAsyncBlock: ^(AsyncScope *rootScope) { \
            Name(rootScope); \
        }]; \
    } \
    @end

@namespace(AsyncRuntimeTestSupport)

+ (Future<OFString *> *)timerResolvedStringForScheduler: (AsyncScheduler *)scheduler
                                                seconds: (OFTimeInterval)seconds
                                                  value: (OFString *)value;
+ (Future<OFString *> *)timerRejectedStringForScheduler: (AsyncScheduler *)scheduler
                                                seconds: (OFTimeInterval)seconds
                                              exception: (OFException *)exception;
+ (AsyncTaskSnapshot *nillable)findTaskSnapshotNamed: (OFString *)name inSnapshot: (AsyncSchedulerSnapshot *)snapshot;
+ (uintptr_t)pointerValueFromBytes: (const void *)bytes;
+ (void)assertCondition: (bool)condition message: (OFString *)message;

@end

@interface TestFailureException : OFException {
@private
    OFString *_message;
}

@property(readonly, nonatomic) OFString *message;

- (instancetype)initWithMessage: (OFString *)message OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface TestRejectionException : OFException @end

@interface CrossThreadResolverThread : OFThread

- (instancetype)initWithResolver: (FutureResolver<OFString *> *)resolver value: (OFString *)value delay: (OFTimeInterval)delay OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface TaskCancellationThread : OFThread

- (instancetype)initWithTask: (Task *)task delay: (OFTimeInterval)delay cancelIssuedFlag: (atomic_t(bool) *)cancelIssuedFlag OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface LocalHTTPTestServer : OFObject

@property(readonly, nonatomic) uint16_t port;

- (void)start;
- (void)stop;
- (OFIRI *)IRIForPath: (OFString *)path;

@end

#pragma clang assume_nonnull end
