#pragma once

#import "Async/Future.h"
#import "Async/AsyncScheduler.h"

#pragma clang assume_nonnull begin

void AsyncEnsureObjFWBindingsLoaded(void);

@interface FutureHTTPClientInvalidCompletionException : FutureException {
@private
    OFHTTPClient *_client;
    OFHTTPRequest *_request;
    OFString *_reason;
}

@property(readonly, nonatomic) OFHTTPClient *client;
@property(readonly, nonatomic) OFHTTPRequest *request;
@property(readonly, nonatomic) OFString *reason;

- (instancetype)initWithFuture: (Future *)future client: (OFHTTPClient *)client request: (OFHTTPRequest *)request reason: (OFString *)reason OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithFuture: (Future *)future OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface FutureHTTPClientCancelledException : FutureException {
@private
    OFHTTPRequest *_request;
}

@property(readonly, nonatomic) OFHTTPRequest *request;

- (instancetype)initWithFuture: (Future *)future request: (OFHTTPRequest *)request OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithFuture: (Future *)future OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface OFHTTPClient (FutureAdditions)

- (Future<OFHTTPResponse *> *)futurePerformRequest: (OFHTTPRequest *)request onScheduler: (AsyncScheduler *)scheduler;
- (Future<OFHTTPResponse *> *)futurePerformRequest: (OFHTTPRequest *)request redirects: (unsigned int)redirects onScheduler: (AsyncScheduler *)scheduler;
- (Future<OFHTTPResponse *> *)futurePerformRequest: (OFHTTPRequest *)request redirects: (unsigned int)redirects onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end
