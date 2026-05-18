#pragma once

#import <AsyncRT/Core.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPClientException : OFException

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

[[subclassing_restricted]]
@interface AsyncHTTPClient : OFObject

@property(nonatomic) bool allowsInsecureRedirects;
@property(weak, nonatomic) OFObject<OFHTTPClientDelegate> *nillable delegate;

+ (instancetype)client;
- (AsyncTask<OFHTTPResponse *> *)performRequest: (OFHTTPRequest *)request
                                    onScheduler: (AsyncScheduler *)scheduler;
- (AsyncTask<OFHTTPResponse *> *)performRequest: (OFHTTPRequest *)request
                                      redirects: (unsigned int)redirects
                                    onScheduler: (AsyncScheduler *)scheduler;

@end

#pragma clang assume_nonnull end
