#pragma once

#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#import <ObjFWTest/ObjFWTest.h>
#import "AsyncRuntime.h"
#import "AsyncRuntimeInternal.h"
#import "Coroutine.h"
#import "Optional.h"
#import "Pointer.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncRuntimeTestCase : OTTestCase

- (void)runAsyncBlock: (void (^)(AsyncTaskGroup *rootTaskGroup))block;

@end

#define ASYNC_RUNTIME_SYNC_TEST(Name) \
    @interface test_##Name : OTTestCase @end \
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
        [self runAsyncBlock: ^(AsyncTaskGroup *rootTaskGroup) { \
            Name(rootTaskGroup); \
        }]; \
    } \
    @end

@namespace(AsyncRuntimeTestSupport)

+ (Task<OFString *> *)timerResolvedStringForScheduler: (AsyncScheduler *)scheduler
                                              seconds: (OFTimeInterval)seconds
                                                value: (OFString *)value;
+ (Task<OFString *> *)timerRejectedStringForScheduler: (AsyncScheduler *)scheduler
                                              seconds: (OFTimeInterval)seconds
                                            exception: (OFException *)exception;
+ (Task<OFHTTPResponse *> *)taskToPerformHTTPRequest: (OFHTTPRequest *)request
                                      withHTTPClient: (OFHTTPClient *)client
                                         onScheduler: (AsyncScheduler *)scheduler;
+ (Task<OFHTTPResponse *> *)taskToPerformHTTPRequest: (OFHTTPRequest *)request
                                      withHTTPClient: (OFHTTPClient *)client
                                           redirects: (unsigned int)redirects
                                         onScheduler: (AsyncScheduler *)scheduler;
+ (Task<OFHTTPResponse *> *)taskToPerformHTTPRequest: (OFHTTPRequest *)request
                                      withHTTPClient: (OFHTTPClient *)client
                                           redirects: (unsigned int)redirects
                                         onScheduler: (AsyncScheduler *)scheduler
                            cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
+ (AsyncTaskSnapshot *nillable)findTaskSnapshotNamed: (OFString *)name inSnapshot: (AsyncSchedulerSnapshot *)snapshot;
+ (uintptr_t)pointerValueFromBytes: (const void *)bytes;
+ (void)assertCondition: (bool)condition message: (OFString *)message;

@end

[[subclassing_restricted]]
@interface TestFailureException : OFException

@property(readonly, nonatomic) OFString *message;

- (instancetype)initWithMessage: (OFString *)message [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface TestRejectionException : OFException @end

[[subclassing_restricted]]
@interface CrossThreadResolverThread : OFThread

- (instancetype)initWithResolver: (AsyncCompletionSource<OFString *> *)resolver value: (OFString *)value delay: (OFTimeInterval)delay [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface TaskCancellationThread : OFThread

- (instancetype)initWithTask: (Task *)task delay: (OFTimeInterval)delay cancelIssuedFlag: (atomic_t(bool) *)cancelIssuedFlag [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface LocalHTTPTestServer : OFObject

@property(readonly, nonatomic) uint16_t port;

- (void)start;
- (void)stop;
- (OFIRI *)IRIForPath: (OFString *)path;

@end

#pragma clang assume_nonnull end
