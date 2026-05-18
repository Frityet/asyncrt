#import "Realbooru.h"

#import <AsyncRT/Networking/HTTP/AsyncHTTPClient.h>
#import <AsyncRT/Core/AsyncRuntime.h>
#import <ObjFW/OFString+XMLUnescaping.h>

#pragma clang assume_nonnull begin

static size_t const realbooru_default_posts_per_page = 42;
static size_t const realbooru_listing_page_size = 42;

[[gnu::constructor]]
static void RealbooruEnsureObjFWXMLUnescapingLoaded(void)
{
    volatile int XMLReference = _OFString_XMLUnescaping_reference;

    (void)XMLReference;
}

@namespace(RealbooruHTML)

+ (OFArray<BooruPost *> *)postsFromHTML: (OFString *)HTML
                                  booru: (id<Booru>)booru
                                  limit: (size_t)limit;

@end

@implementation RealbooruAPIException

- (instancetype)initWithReason: (OFString *)reason
           underlyingException: (OFException *nillable)underlyingException
{
    self = [super init];
    _reason = [reason copy];
    _underlyingException = underlyingException;
    return self;
}

- (OFString *)description
{
    if (self.underlyingException == nilptr)
        return [OFString stringWithFormat: @"RealbooruAPIException: %@", self.reason];

    return [OFString stringWithFormat: @"RealbooruAPIException: %@ (%@)",
                                      self.reason,
                                      self.underlyingException];
}

@end

@namespace_implementation(RealbooruHTML)

+ (OFRange)rangeOfString: (OFString *)needle
                inString: (OFString *)haystack
               fromIndex: (size_t)index
{
    if (index >= haystack.length)
        return OFMakeRange(OFNotFound, 0);

    return [haystack rangeOfString: needle
                           options: (OFStringSearchOptions)0
                             range: OFMakeRange(index, haystack.length - index)];
}

+ (OFString *nillable)attributeNamed: (OFString *)attributeName
                           inFragment: (OFString *)fragment
{
    OFString *doubleQuotedPrefix = [OFString stringWithFormat: @"%@=\"", attributeName];
    OFString *singleQuotedPrefix = [OFString stringWithFormat: @"%@='", attributeName];
    OFRange prefixRange = [fragment rangeOfString: doubleQuotedPrefix];
    OFString *terminator = @"\"";

    if (prefixRange.location == OFNotFound) {
        prefixRange = [fragment rangeOfString: singleQuotedPrefix];
        terminator = @"'";
    }

    if (prefixRange.location == OFNotFound)
        return nilptr;

    size_t valueStart = prefixRange.location + prefixRange.length;
    OFRange terminatorRange = [fragment rangeOfString: terminator
                                              options: (OFStringSearchOptions)0
                                                range: OFMakeRange(valueStart, fragment.length - valueStart)];

    if (terminatorRange.location == OFNotFound)
        return nilptr;

    return [[fragment substringWithRange: OFMakeRange(valueStart, terminatorRange.location - valueStart)] stringByXMLUnescaping];
}

+ (OFString *nillable)postIDFromThumbID: (OFString *nillable)thumbID
                                    alt: (OFString *nillable)alt
{
    if (thumbID != nilptr and [thumbID hasPrefix: @"s"] and thumbID.length > 1)
        return [thumbID substringWithRange: OFMakeRange(1, thumbID.length - 1)];

    if (alt != nilptr) {
        OFRange labelRange = [$assert_nonnil(alt) rangeOfString: @"Image: "];

        if (labelRange.location != OFNotFound) {
            size_t idStart = labelRange.location + labelRange.length;

            return [$assert_nonnil(alt) substringWithRange: OFMakeRange(idStart, $assert_nonnil(alt).length - idStart)];
        }
    }

    return nilptr;
}

+ (OFArray<OFString *> *)tagsFromTitle: (OFString *nillable)title
{
    if (title == nilptr)
        return [OFArray array];

    auto tags = [OFMutableArray<OFString *> array];

    for (OFString *tag in [$assert_nonnil(title) componentsSeparatedByString: @","]) {
        OFString *trimmedTag = tag.stringByDeletingEnclosingWhitespaces;

        if (trimmedTag.length > 0)
            [tags addObject: trimmedTag];
    }

    return [tags copy];
}

+ (OFIRI *)absoluteIRIForAttributeValue: (OFString *)value
                                relativeToBaseIRI: (OFIRI *)baseIRI
{
    return [OFIRI IRIWithString: value relativeToIRI: baseIRI];
}

+ (BooruPost *nillable)postFromThumbFragment: (OFString *)fragment
                                     baseIRI: (OFIRI *)baseIRI
{
    OFString *nillable thumbID = [self attributeNamed: @"id" inFragment: fragment];
    OFString *nillable source = [self attributeNamed: @"src" inFragment: fragment];
    OFString *nillable title = [self attributeNamed: @"title" inFragment: fragment];
    OFString *nillable alt = [self attributeNamed: @"alt" inFragment: fragment];
    OFString *nillable postID = [self postIDFromThumbID: thumbID alt: alt];

    if (source == nilptr or postID == nilptr)
        return nilptr;

    OFIRI *absoluteSource = [self absoluteIRIForAttributeValue: $assert_nonnil(source)
                                             relativeToBaseIRI: baseIRI];

    return [[BooruPost alloc] initWithID: $assert_nonnil(postID)
                              previewIRI: absoluteSource
                               sampleIRI: absoluteSource
                                 fileIRI: absoluteSource
                                    tags: [self tagsFromTitle: title]];
}

+ (OFArray<BooruPost *> *)postsFromHTML: (OFString *)HTML
                                  booru: (id<Booru>)booru
                                  limit: (size_t)limit
{
    auto posts = [OFMutableArray<BooruPost *> arrayWithCapacity: limit];
    size_t searchIndex = 0;

    while (posts.count < limit) {
        OFRange thumbRange = [self rangeOfString: @"<div class=\"col thumb\""
                                        inString: HTML
                                       fromIndex: searchIndex];

        if (thumbRange.location == OFNotFound)
            break;

        OFRange nextThumbRange = [self rangeOfString: @"<div class=\"col thumb\""
                                            inString: HTML
                                           fromIndex: thumbRange.location + thumbRange.length];
        size_t blockEnd = (nextThumbRange.location == OFNotFound)
            ? HTML.length
            : nextThumbRange.location;
        OFString *fragment = [HTML substringWithRange: OFMakeRange(thumbRange.location, blockEnd - thumbRange.location)];
        BooruPost *nillable post = [self postFromThumbFragment: fragment baseIRI: booru.baseIRI];

        if (post != nilptr)
            [posts addObject: $assert_nonnil(post)];

        searchIndex = blockEnd;
    }

    return [posts copy];
}

@end

@implementation Realbooru

- (instancetype)initWithAPIUserID: (OFString *)userID
                           andKey: (OFString *)apiKey
{
    (void)userID;
    (void)apiKey;

    return [self initWithBaseIRI: [OFIRI IRIWithString: @"https://realbooru.com/"]
                    postsPerPage: realbooru_default_posts_per_page];
}

- (instancetype)initWithBaseIRI: (OFIRI *)baseIRI
                   postsPerPage: (size_t)postsPerPage
{
    if (postsPerPage == 0 or postsPerPage > realbooru_listing_page_size)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _name = @"Realbooru";
    _httpClient = [AsyncHTTPClient client];
    _baseIRI = baseIRI;
    _postsPerPage = postsPerPage;
    return self;
}

- (AsyncTask<OFArray<OFString *> *> *)fetchAllTags
{
    return [AsyncTask rejected: [[RealbooruAPIException alloc] initWithReason: @"Realbooru tag listing is unavailable because Realbooru's DAPI is offline"
                                                     underlyingException: nilptr]];
}

- (AsyncTask<Optional<BooruPage *> *> *)fetchPage: (int)pageNumber forSearchWithTags: (OFArray<OFString *> *)tags
{
    return [self fetchPage: pageNumber forSearchWithTags: tags excludingTags: [OFArray array]];
}

- (AsyncTask<Optional<BooruPage *> *> *)fetchPage: (int)pageNumber
                           forSearchWithTags: (OFArray<OFString *> *)tags
                               excludingTags: (OFArray<OFString *> *)excludedTags
{
    AsyncTaskGroup *nillable taskGroup = AsyncTaskGroup.currentTaskGroup;
    OFArray<OFString *> *searchTags;
    OFArray<OFString *> *searchExcludedTags;

    if (pageNumber < 0)
        @throw [OFInvalidArgumentException exception];
    if (taskGroup == nilptr)
        return [AsyncTask rejected: [[RealbooruAPIException alloc] initWithReason: @"fetchPage requires an active AsyncTaskGroup"
                                                         underlyingException: nilptr]];

    AsyncTaskGroup *activeTaskGroup = $assert_nonnil(taskGroup);
    searchTags = [tags copy];
    searchExcludedTags = [excludedTags copy];

    return [activeTaskGroup spawnTask: ^id {
        OFString *HTML = [[self _fetchHTMLAtIRI: [self _postSearchIRIForPage: pageNumber
                                                                         tags: searchTags
                                                                 excludedTags: searchExcludedTags]
                                    onScheduler: activeTaskGroup.scheduler] await];
        return [self _pageFromHTML: HTML pageNumber: pageNumber];
    } name: @"Realbooru.fetchPage"];
}

- (AsyncTask<OFString *> *)_fetchHTMLAtIRI: (OFIRI *)IRI onScheduler: (AsyncScheduler *)scheduler [[direct]]
{
    auto request = [[OFHTTPRequest alloc] initWithIRI: IRI];
    request.headers = [OFDictionary dictionaryWithKeysAndObjects:
        @"Accept", @"text/html,*/*;q=0.8",
        @"User-Agent", @"BooruAggr/1.0",
        nil];

    return [[_httpClient performRequest: request onScheduler: scheduler] mapOnScheduler: scheduler transform: ^OFString *(OFHTTPResponse *response) {
        if (response.statusCode < 200 or response.statusCode >= 300)
            @throw [[RealbooruAPIException alloc] initWithReason: [OFString stringWithFormat: @"Realbooru returned AsyncHTTP status %hd", response.statusCode]
                                             underlyingException: nilptr];

        return response.readString;
    }];
}

- (OFIRI *)_postSearchIRIForPage: (int)pageNumber
                            tags: (OFArray<OFString *> *)tags
                    excludedTags: (OFArray<OFString *> *)excludedTags [[direct]]
{
    return [self _IRIWithQueryItems: [OFArray arrayWithObjects:
        [self _queryItemWithKey: @"page" value: @"post"],
        [self _queryItemWithKey: @"s" value: @"list"],
        [self _queryItemWithKey: @"tags" value: [self _searchStringWithTags: tags excludedTags: excludedTags]],
        [self _queryItemWithKey: @"pid" value: [OFString stringWithFormat: @"%d", pageNumber * (int)realbooru_listing_page_size]],
        nil]];
}

- (OFPair<OFString *, OFString *> *)_queryItemWithKey: (OFString *)key value: (OFString *)value [[direct]]
{
    return [OFPair pairWithFirstObject: key secondObject: value];
}

- (OFIRI *)_IRIWithQueryItems: (OFArray<OFPair<OFString *, OFString *> *> *)queryItems [[direct]]
{
    OFMutableIRI *IRI = [self.baseIRI mutableCopy];

    [IRI appendPathComponent: @"index.php"];
    IRI.queryItems = queryItems;
    [IRI makeImmutable];
    return IRI;
}

- (OFString *)_searchStringWithTags: (OFArray<OFString *> *)tags
                       excludedTags: (OFArray<OFString *> *)excludedTags [[direct]]
{
    auto terms = [OFMutableArray<OFString *> arrayWithCapacity: tags.count + excludedTags.count];

    for (OFString *tag in tags) {
        if (tag.length > 0)
            [terms addObject: tag];
    }

    for (OFString *tag in excludedTags) {
        if (tag.length == 0)
            continue;
        if ([tag hasPrefix: @"-"])
            [terms addObject: tag];
        else
            [terms addObject: [OFString stringWithFormat: @"-%@", tag]];
    }

    if (terms.count == 0)
        return @"all";

    return [terms componentsJoinedByString: @" "];
}

- (Optional<BooruPage *> *)_pageFromHTML: (OFString *)HTML pageNumber: (int)pageNumber [[direct]]
{
    OFArray<BooruPost *> *posts = [RealbooruHTML postsFromHTML: HTML
                                                         booru: self
                                                         limit: self.postsPerPage];

    if (posts.count == 0)
        return Optional.none;

    return [Optional some: [[BooruPage alloc] initWithBooru: self
                                                      posts: posts
                                                 pageNumber: pageNumber
                                                       next: Optional.none]];
}

@end

#pragma clang assume_nonnull end
