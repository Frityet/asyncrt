#pragma once

#import "Booru.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface GelbooruAPIException : OFException

@property(readonly, copy, nonatomic) OFString *reason;
@property(readonly, nonatomic) OFException *nillable underlyingException;

- (instancetype)initWithReason: (OFString *)reason
           underlyingException: (OFException *nillable)underlyingException [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface Gelbooru : OFObject <Booru>

@property(readonly, copy, nonatomic) OFString *name;
@property(readonly, nonatomic) OFIRI *baseIRI;
@property(readonly, nonatomic) size_t postsPerPage;
@property(readonly, nonatomic) AsyncHTTPClient *httpClient;

- (instancetype)initWithAPIUserID: (OFString *)userID
                           andKey: (OFString *)apiKey;
- (instancetype)initWithAPIUserID: (OFString *)userID
                           andKey: (OFString *)apiKey
                          baseIRI: (OFIRI *)baseIRI
                     postsPerPage: (size_t)postsPerPage [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
