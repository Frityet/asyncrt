#pragma once

#import "Async/Promise.h"
#import "Async/AsyncScheduler.h"

#pragma clang assume_nonnull begin

void AsyncEnsureObjFWBindingsLoaded(void);

@interface PromiseHTTPClientInvalidCompletionException : PromiseException {
@private
    OFHTTPClient *_client;
    OFHTTPRequest *_request;
    OFString *_reason;
}

@property(readonly, nonatomic) OFHTTPClient *client;
@property(readonly, nonatomic) OFHTTPRequest *request;
@property(readonly, nonatomic) OFString *reason;

- (instancetype)initWithPromise: (Promise *)future client: (OFHTTPClient *)client request: (OFHTTPRequest *)request reason: (OFString *)reason OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithPromise: (Promise *)future OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseHTTPClientCancelledException : PromiseException {
@private
    OFHTTPRequest *_request;
}

@property(readonly, nonatomic) OFHTTPRequest *request;

- (instancetype)initWithPromise: (Promise *)future request: (OFHTTPRequest *)request OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithPromise: (Promise *)future OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface OFHTTPClient (PromiseAdditions)

- (Promise<OFHTTPResponse *> *)promiseToPerformRequest: (OFHTTPRequest *)request onScheduler: (AsyncScheduler *)scheduler;
- (Promise<OFHTTPResponse *> *)promiseToPerformRequest: (OFHTTPRequest *)request redirects: (unsigned int)redirects onScheduler: (AsyncScheduler *)scheduler;
- (Promise<OFHTTPResponse *> *)promiseToPerformRequest: (OFHTTPRequest *)request redirects: (unsigned int)redirects onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end
