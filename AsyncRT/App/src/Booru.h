#pragma once

#include "Optional.h"
#import "common.h"
#import "Task.h"

#pragma clang assume_nonnull begin


[[subclassing_restricted, direct_members]]
@interface BooruPost : OFObject

@property(readonly, copy, nonatomic) OFString *id;
@property(readonly, nonatomic) OFIRI *previewIRI;
@property(readonly, nonatomic) OFIRI *nillable sampleIRI;
@property(readonly, nonatomic) OFIRI *fileIRI;
@property(readonly, copy, nonatomic) OFArray<OFString *> *tags;

- (instancetype)initWithID: (OFString *)id
                previewIRI: (OFIRI *)previewIRI
                   fileIRI: (OFIRI *)fileIRI
                      tags: (OFArray<OFString *> *)tags;
- (instancetype)initWithID: (OFString *)id
                previewIRI: (OFIRI *)previewIRI
                 sampleIRI: (OFIRI *nillable)sampleIRI
                   fileIRI: (OFIRI *)fileIRI
                      tags: (OFArray<OFString *> *)tags [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@protocol Booru;

[[subclassing_restricted, direct_members]]
@interface BooruPage : OFObject

@property(readonly, weak, nonatomic) id<Booru> booru;

@property(readonly, copy, nonatomic) OFArray<BooruPost *> *posts;
@property(readonly, nonatomic) int pageNumber;
@property(readonly, nonatomic) Optional<BooruPage *> *next;

- (instancetype)initWithBooru: (id<Booru>)booru
                        posts: (OFArray<BooruPost *> *)posts
                   pageNumber: (int)pageNumber
                         next: (Optional<BooruPage *> *)next [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@protocol Booru

@property(readonly, copy, nonatomic) OFString *name;
@property(readonly, nonatomic) OFIRI *baseIRI;
@property(readonly, nonatomic) OFHTTPClient *httpClient;

- (Task<OFArray<OFString *> *> *)fetchAllTags;
- (Task<Optional<BooruPage *> *> *)fetchPage: (int)pageNumber forSearchWithTags: (OFArray<OFString *> *)tags;
- (Task<Optional<BooruPage *> *> *)fetchPage: (int)pageNumber forSearchWithTags: (OFArray<OFString *> *)tags excludingTags: (OFArray<OFString *> *)excludedTags;

- (instancetype)initWithAPIUserID: (OFString *)userID andKey: (OFString *)apiKey;

@end

#pragma clang assume_nonnull end
