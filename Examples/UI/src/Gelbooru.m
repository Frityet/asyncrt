#import "Gelbooru.h"

#import <AsyncRT/Networking/HTTP/AsyncHTTPClient.h>
#import <AsyncRT/Core/AsyncRuntime.h>
#import <ObjFW/OFString+JSONParsing.h>

#pragma clang assume_nonnull begin

static size_t const gelbooru_default_posts_per_page = 100;
static size_t const gelbooru_max_posts_per_page = 100;
static size_t const TAG_FETCH_LIMIT = 1000;

[[gnu::constructor]]
static void GelbooruEnsureObjFWJSONParsingLoaded(void)
{
    volatile int JSONReference = _OFString_JSONParsing_reference;

    (void)JSONReference;
}

@namespace(GelbooruJSON)

+ (OFArray<id> *)collectionNamed: (OFString *)name inJSONObject: (id)JSONObject;
+ (OFString *nillable)stringForKey: (OFString *)key inDictionary: (OFDictionary<OFString *, id> *)dictionary;
+ (unsigned long long)unsignedLongLongForKey: (OFString *)key inDictionary: (OFDictionary<OFString *, id> *)dictionary fallback: (unsigned long long)fallback;

@end

@implementation GelbooruAPIException

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
        return [OFString stringWithFormat: @"GelbooruAPIException: %@", self.reason];

    return [OFString stringWithFormat: @"GelbooruAPIException: %@ (%@)",
                                      self.reason,
                                      self.underlyingException];
}

@end

@namespace_implementation(GelbooruJSON)

+ (OFArray<id> *)collectionNamed: (OFString *)name inJSONObject: (id)JSONObject
{
    id nillable collection = JSONObject;

    if ([JSONObject isKindOfClass: OFDictionary.class])
        collection = [(OFDictionary<OFString *, id> *)JSONObject objectForKey: name];

    if (collection == nilptr)
        return [OFArray array];
    if ([collection isKindOfClass: OFArray.class])
        return (OFArray<id> *)collection;
    if ([collection isKindOfClass: OFDictionary.class])
        return [OFArray arrayWithObject: $assert_nonnil(collection)];

    return [OFArray array];
}

+ (OFString *nillable)stringForKey: (OFString *)key inDictionary: (OFDictionary<OFString *, id> *)dictionary
{
    id nillable object = [dictionary objectForKey: key];

    if (object == nilptr)
        return nilptr;
    if ([object isKindOfClass: OFString.class])
        return (OFString *)object;
    if ([object isKindOfClass: OFNumber.class])
        return [(OFNumber *)object stringValue];

    return nilptr;
}

+ (unsigned long long)unsignedLongLongForKey: (OFString *)key inDictionary: (OFDictionary<OFString *, id> *)dictionary fallback: (unsigned long long)fallback
{
    id nillable object = [dictionary objectForKey: key];

    @try {
        if ([object isKindOfClass: OFNumber.class])
            return [(OFNumber *)object unsignedLongLongValue];
        if ([object isKindOfClass: OFString.class])
            return [(OFString *)object unsignedLongLongValue];
    } @catch (OFException *) {
    }

    return fallback;
}

@end

@implementation Gelbooru {
    OFString *_apiUserID;
    OFString *_apiKey;
}

- (instancetype)initWithAPIUserID: (OFString *)userID
                           andKey: (OFString *)apiKey
{
    return [self initWithAPIUserID: userID
                            andKey: apiKey
                           baseIRI: [OFIRI IRIWithString: @"https://gelbooru.com/"]
                      postsPerPage: gelbooru_default_posts_per_page];
}

- (instancetype)initWithAPIUserID: (OFString *)userID
                           andKey: (OFString *)apiKey
                          baseIRI: (OFIRI *)baseIRI
                     postsPerPage: (size_t)postsPerPage
{
    if (userID.length == 0 or apiKey.length == 0)
        @throw [OFInvalidArgumentException exception];
    if (postsPerPage == 0 or postsPerPage > gelbooru_max_posts_per_page)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _name = @"Gelbooru";
    _apiUserID = [userID copy];
    _apiKey = [apiKey copy];
    _httpClient = [AsyncHTTPClient client];
    _baseIRI = baseIRI;
    _postsPerPage = postsPerPage;
    return self;
}

- (AsyncTask<OFArray<OFString *> *> *)fetchAllTags
{
    AsyncTaskGroup *nillable taskGroup = AsyncTaskGroup.currentTaskGroup;

    if (taskGroup == nilptr)
        return [AsyncTask rejected: [[GelbooruAPIException alloc] initWithReason: @"fetchAllTags requires an active AsyncTaskGroup"
                                                        underlyingException: nilptr]];

    AsyncTaskGroup *activeTaskGroup = $assert_nonnil(taskGroup);

    return (AsyncTask<OFArray<OFString *> *> *)[activeTaskGroup spawnTask: ^id {
        auto tagNames = [OFMutableArray<OFString *> array];
        unsigned long long afterID = 0;

        while (true) {
            [AsyncTask checkCancellation];

            id JSONObject = [[self _fetchJSONAtIRI: [self _tagListIRIAfterID: afterID]
                                       onScheduler: activeTaskGroup.scheduler] await];
            OFArray<id> *tags = [GelbooruJSON collectionNamed: @"tag" inJSONObject: JSONObject];
            bool advanced = false;

            if (tags.count == 0)
                break;

            for (id tag in tags) {
                if (not [tag isKindOfClass: OFDictionary.class])
                    continue;

                auto tagDictionary = (OFDictionary<OFString *, id> *)tag;
                OFString *nillable name = [GelbooruJSON stringForKey: @"name" inDictionary: tagDictionary];
                unsigned long long tagID = [GelbooruJSON unsignedLongLongForKey: @"id"
                                                                    inDictionary: tagDictionary
                                                                        fallback: afterID];

                if (name != nilptr and name.length > 0)
                    [tagNames addObject: $assert_nonnil(name)];
                if (tagID > afterID) {
                    afterID = tagID;
                    advanced = true;
                }
            }

            if (not advanced)
                break;
        }

        return [tagNames copy];
    } name: @"Gelbooru.fetchAllTags"];
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
        return [AsyncTask rejected: [[GelbooruAPIException alloc] initWithReason: @"fetchPage requires an active AsyncTaskGroup"
                                                        underlyingException: nilptr]];

    AsyncTaskGroup *activeTaskGroup = $assert_nonnil(taskGroup);
    searchTags = [tags copy];
    searchExcludedTags = [excludedTags copy];

    return [activeTaskGroup spawnTask: ^id {
        id JSONObject = [[self _fetchJSONAtIRI: [self _postSearchIRIForPage: pageNumber
                                                                        tags: searchTags
                                                                excludedTags: searchExcludedTags]
                                   onScheduler: activeTaskGroup.scheduler] await];
        return [self _pageFromJSONObject: JSONObject pageNumber: pageNumber];
    } name: @"Gelbooru.fetchPage"];
}

- (AsyncTask<id> *)_fetchJSONAtIRI: (OFIRI *)IRI onScheduler: (AsyncScheduler *)scheduler [[direct]]
{
    auto request = [[OFHTTPRequest alloc] initWithIRI: IRI];
    request.headers = [OFDictionary dictionaryWithObject: @"BooruAggr/1.0" forKey: @"User-Agent"];

    return [[_httpClient performRequest: request onScheduler: scheduler] mapOnScheduler: scheduler transform: ^id(OFHTTPResponse *response) {
        return response.readString.objectByParsingJSON;
    }];
}

- (OFIRI *)_postSearchIRIForPage: (int)pageNumber
                            tags: (OFArray<OFString *> *)tags
                    excludedTags: (OFArray<OFString *> *)excludedTags [[direct]]
{
    return [self _IRIWithQueryItems: [OFArray arrayWithObjects:
        [self _queryItemWithKey: @"page" value: @"dapi"],
        [self _queryItemWithKey: @"s" value: @"post"],
        [self _queryItemWithKey: @"q" value: @"index"],
        [self _queryItemWithKey: @"json" value: @"1"],
        [self _queryItemWithKey: @"limit" value: [OFString stringWithFormat: @"%zu", self.postsPerPage]],
        [self _queryItemWithKey: @"pid" value: [OFString stringWithFormat: @"%d", pageNumber]],
        [self _queryItemWithKey: @"tags" value: [self _searchStringWithTags: tags excludedTags: excludedTags]],
        [self _queryItemWithKey: @"api_key" value: _apiKey],
        [self _queryItemWithKey: @"user_id" value: _apiUserID],
        nil]];
}

- (OFIRI *)_tagListIRIAfterID: (unsigned long long)afterID [[direct]]
{
    return [self _IRIWithQueryItems: [OFArray arrayWithObjects:
        [self _queryItemWithKey: @"page" value: @"dapi"],
        [self _queryItemWithKey: @"s" value: @"tag"],
        [self _queryItemWithKey: @"q" value: @"index"],
        [self _queryItemWithKey: @"json" value: @"1"],
        [self _queryItemWithKey: @"limit" value: [OFString stringWithFormat: @"%zu", TAG_FETCH_LIMIT]],
        [self _queryItemWithKey: @"after_id" value: [OFString stringWithFormat: @"%llu", afterID]],
        [self _queryItemWithKey: @"api_key" value: _apiKey],
        [self _queryItemWithKey: @"user_id" value: _apiUserID],
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

    return [terms componentsJoinedByString: @" "];
}

- (Optional<BooruPage *> *)_pageFromJSONObject: (id)JSONObject pageNumber: (int)pageNumber [[direct]]
{
    OFArray<id> *postObjects = [GelbooruJSON collectionNamed: @"post" inJSONObject: JSONObject];
    auto posts = [OFMutableArray<BooruPost *> arrayWithCapacity: postObjects.count];

    for (id postObject in postObjects) {
        BooruPost *nillable post = [self _postFromJSONObject: postObject];

        if (post != nilptr)
            [posts addObject: $assert_nonnil(post)];
    }

    if (posts.count == 0)
        return Optional.none;

    return [Optional some: [[BooruPage alloc] initWithBooru: self
                                                      posts: posts
                                                 pageNumber: pageNumber
                                                       next: Optional.none]];
}

- (BooruPost *nillable)_postFromJSONObject: (id)JSONObject [[direct]]
{
    if (not [JSONObject isKindOfClass: OFDictionary.class])
        return nilptr;

    auto postDictionary = (OFDictionary<OFString *, id> *)JSONObject;
    OFString *nillable postID = [GelbooruJSON stringForKey: @"id" inDictionary: postDictionary];
    OFString *nillable previewIRIString = [GelbooruJSON stringForKey: @"preview_url" inDictionary: postDictionary];
    OFString *nillable sampleIRIString = [GelbooruJSON stringForKey: @"sample_url" inDictionary: postDictionary];
    OFString *nillable fileIRIString = [GelbooruJSON stringForKey: @"file_url" inDictionary: postDictionary];
    OFArray<OFString *> *tags = [self _tagsFromObject: [postDictionary objectForKey: @"tags"]];
    OFIRI *nillable previewIRI;
    OFIRI *nillable sampleIRI;
    OFIRI *nillable fileIRI;

    if (postID == nilptr or previewIRIString == nilptr or fileIRIString == nilptr)
        return nilptr;

    previewIRI = [self _IRIFromAPIString: $assert_nonnil(previewIRIString)];
    sampleIRI = sampleIRIString == nilptr ? nilptr : [self _IRIFromAPIString: $assert_nonnil(sampleIRIString)];
    fileIRI = [self _IRIFromAPIString: $assert_nonnil(fileIRIString)];

    if (previewIRI == nilptr or fileIRI == nilptr)
        return nilptr;

    return [[BooruPost alloc] initWithID: $assert_nonnil(postID)
                              previewIRI: $assert_nonnil(previewIRI)
                               sampleIRI: sampleIRI
                                 fileIRI: $assert_nonnil(fileIRI)
                                    tags: tags];
}

- (OFIRI *nillable)_IRIFromAPIString: (OFString *)string [[direct]]
{
    @try {
        return [OFIRI IRIWithString: string].IRIByAddingPercentEncodingForUnicodeCharacters;
    } @catch (OFException *) {
        return nilptr;
    }
}

- (OFArray<OFString *> *)_tagsFromObject: (id nillable)object [[direct]]
{
    if (object == nilptr)
        return [OFArray array];
    if ([object isKindOfClass: OFArray.class])
        return (OFArray<OFString *> *)object;
    if (not [object isKindOfClass: OFString.class])
        return [OFArray array];

    auto parsedTags = [OFMutableArray<OFString *> array];

    for (OFString *tag in [(OFString *)object componentsSeparatedByString: @" "]) {
        if (tag.length > 0)
            [parsedTags addObject: tag];
    }

    return [parsedTags copy];
}

@end

#pragma clang assume_nonnull end
