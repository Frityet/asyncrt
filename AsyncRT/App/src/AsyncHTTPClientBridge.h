#pragma once

#import "AsyncRuntime.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPClientBridgeException : OFException

@property(readonly, copy, nonatomic) OFString *reason;

- (instancetype)initWithReason: (OFString *)reason [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPRequestCancelledException : OFException

@property(readonly, nonatomic) OFHTTPRequest *request;

- (instancetype)initWithRequest: (OFHTTPRequest *)request [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@interface OFHTTPClient (AsyncHTTPClientBridge)

- (Task<OFHTTPResponse *> *)taskToPerformHTTPRequest: (OFHTTPRequest *)request
                                         onScheduler: (AsyncScheduler *)scheduler;
- (Task<OFHTTPResponse *> *)taskToPerformHTTPRequest: (OFHTTPRequest *)request
                                           redirects: (unsigned int)redirects
                                         onScheduler: (AsyncScheduler *)scheduler;

@end

#pragma clang assume_nonnull end
