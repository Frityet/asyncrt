#pragma once

#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#import <ObjFWTest/ObjFWTest.h>
#import <AsyncRT/Core.h>
#import <AsyncRT/Core/AsyncRuntimeInternal.h>
#import <AsyncRT/Networking/HTTP.h>
#import <AsyncRT/Common/Optional.h>
#import <AsyncRT/Common/Pointer.h>

#pragma clang assume_nonnull begin

@interface AsyncRuntimeTestCase : OTTestCase

- (void)runAsyncBlock: (void (^)(void))block;

@end

@namespace(AsyncRuntimeTestSupport)

+ (AsyncTask<OFString *> *)timerResolvedStringAfter: (OFTimeInterval)seconds
                                                value: (OFString *)value;

+ (AsyncTask<OFString *> *)timerRejectedStringAfter: (OFTimeInterval)seconds
                                            exception: (OFException *)exception;

+ (AsyncTask<OFHTTPResponse *> *)taskToPerformHTTPRequest: (OFHTTPRequest *)request
                                      withHTTPClient: (AsyncHTTPClient *)client;

+ (AsyncTask<OFHTTPResponse *> *)taskToPerformHTTPRequest: (OFHTTPRequest *)request
                                      withHTTPClient: (AsyncHTTPClient *)client
                                           redirects: (unsigned int)redirects;

+ (AsyncTask<OFHTTPResponse *> *)taskToPerformHTTPRequest: (OFHTTPRequest *)request
                                      withHTTPClient: (AsyncHTTPClient *)client
                                           redirects: (unsigned int)redirects
                            cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
                            
+ (AsyncTaskSnapshot *nillable)findTaskSnapshotNamed: (OFString *)name inSnapshot: (AsyncSchedulerSnapshot *)snapshot;
+ (uintptr_t)pointerValueFromBytes: (const void *)bytes;

@end

[[subclassing_restricted]]
@interface TestRejectionException : OFException @end

[[subclassing_restricted]]
@interface CrossThreadResolverThread : OFThread

- (instancetype)initWithResolver: (AsyncCompletionSource<OFString *> *)resolver value: (OFString *)value delay: (OFTimeInterval)delay [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface AsyncTaskCancellationThread : OFThread

- (instancetype)initWithTask: (AsyncTask *)task delay: (OFTimeInterval)delay cancelIssuedFlag: (atomic_t(bool) *)cancelIssuedFlag [[designated_initailiser]];
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
