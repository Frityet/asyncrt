#pragma once

#import "Async/Promise.h"
#import "Async/AsyncScheduler.h"

#pragma clang assume_nonnull begin

void AsyncEnsureObjFWBindingsLoaded(void);

@interface PromiseHTTPClientInvalidCompletionException : PromiseException

@property(readonly, nonatomic) OFHTTPClient *client;
@property(readonly, nonatomic) OFHTTPRequest *request;
@property(readonly, nonatomic) OFString *reason;

- (instancetype)initWithPromise: (Promise *)promise client: (OFHTTPClient *)client request: (OFHTTPRequest *)request reason: (OFString *)reason designated_initaliser;
- (instancetype)initWithPromise: (Promise *)promise OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseHTTPClientCancelledException : PromiseException

@property(readonly, nonatomic) OFHTTPRequest *request;

- (instancetype)initWithPromise: (Promise *)promise request: (OFHTTPRequest *)request designated_initaliser;
- (instancetype)initWithPromise: (Promise *)promise OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface OFHTTPClient (PromiseAdditions)

- (Promise<OFHTTPResponse *> *)promiseToPerformRequest: (OFHTTPRequest *)request onScheduler: (AsyncScheduler *)scheduler;
- (Promise<OFHTTPResponse *> *)promiseToPerformRequest: (OFHTTPRequest *)request redirects: (unsigned int)redirects onScheduler: (AsyncScheduler *)scheduler;
- (Promise<OFHTTPResponse *> *)promiseToPerformRequest: (OFHTTPRequest *)request redirects: (unsigned int)redirects onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end
