#import "Booru.h"

#pragma clang assume_nonnull begin

@implementation BooruPost

- (instancetype)initWithID: (OFString *)id
                previewIRI: (OFIRI *)previewIRI
                   fileIRI: (OFIRI *)fileIRI
                      tags: (OFArray<OFString *> *)tags
{
    return [self initWithID: id
                 previewIRI: previewIRI
                  sampleIRI: (OFIRI *)nullptr
                    fileIRI: fileIRI
                       tags: tags];
}

- (instancetype)initWithID: (OFString *)id
                previewIRI: (OFIRI *)previewIRI
                 sampleIRI: (OFIRI *nillable)sampleIRI
                   fileIRI: (OFIRI *)fileIRI
                      tags: (OFArray<OFString *> *)tags
{
    self = [super init];
    _id = [id copy];
    _previewIRI = previewIRI;
    _sampleIRI = sampleIRI;
    _fileIRI = fileIRI;
    _tags = [tags copy];
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"<%@: %p; id = %@; tags = %zu>",
                                      self.className,
                                      self,
                                      self.id,
                                      self.tags.count];
}

@end

@implementation BooruPage

- (instancetype)initWithBooru: (id<Booru>)booru
                        posts: (OFArray<BooruPost *> *)posts
                   pageNumber: (int)pageNumber
                         next: (Optional<BooruPage *> *)next
{
    self = [super init];
    _booru = booru;
    _posts = [posts copy];
    _pageNumber = pageNumber;
    _next = next;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"<%@: %p; booru = %@; pageNumber = %d; posts = %zu>",
                                      self.className,
                                      self,
                                      self.booru.name,
                                      self.pageNumber,
                                      self.posts.count];
}

@end

#pragma clang assume_nonnull end
