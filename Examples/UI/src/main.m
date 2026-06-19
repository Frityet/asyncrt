#import <AsyncRT/Application/Terminal/AsyncArgumentParser.h>
#import <AsyncRT/Application/Core/Application.h>
#import "Gelbooru.h"
#import "ITerm2ImageGallery.h"
#import "Realbooru.h"
#import "TerminalLoadingView.h"

#import <immintrin.h>




#pragma clang assume_nonnull begin

static OFString *const DEFAULT_GELBOORU_API_KEY = @"";
static OFString *const DEFAULT_GELBOORU_USER_ID = @"";

[[gnu::constructor]]
static void BooruCLIEnsureObjFWCryptographicHashingLoaded(void)
{
    volatile int hashingReference = _OFString_CryptographicHashing_reference;

    (void)hashingReference;
}

[[subclassing_restricted]]
@interface BooruFetchCommand : OFObject <AsyncCLICommand>

@property(readonly, nonatomic) AsyncCLIOption<OFString *> *booru;
@property(readonly, nonatomic) AsyncCLIOption<OFString *> *apiKey;
@property(readonly, nonatomic) AsyncCLIOption<OFString *> *userID;
@property(readonly, nonatomic) AsyncCLIOption<OFString *> *tags;
@property(readonly, nonatomic) AsyncCLIOption<OFString *> *exclude;
@property(readonly, nonatomic) AsyncCLIOption<OFNumber *> *page;
@property(readonly, nonatomic) AsyncCLIOption<OFNumber *> *limit;
@property(readonly, nonatomic) AsyncCLIOption<OFNumber *> *scale;
@property(readonly, nonatomic) AsyncCLIOption<OFNumber *> *columns;
@property(readonly, nonatomic) AsyncCLIOption<OFNumber *> *maxEdge;
@property(readonly, nonatomic) AsyncCLIOption<OFNumber *> *jpegQuality;
@property(readonly, nonatomic) AsyncCLIOption<OFString *> *graphicsProtocol;
@property(readonly, nonatomic) AsyncCLIOption<OFIRI *> *baseIRI;
@property(readonly, nonatomic) AsyncCLIOption<OFString *> *cacheDir;
@property(readonly, nonatomic) AsyncCLIOption<OFNumber *> *cacheOnly;

@end

@implementation BooruFetchCommand

- (instancetype)init
{
    self = [super init];
    _booru = [[[[AsyncCLIOption optional: OFString.class]
                       withLongName: @"booru"]
                           withHelp: @"Service to query: gelbooru or realbooru"]
                   withDefaultValue: @"gelbooru"];

    _apiKey = [[[AsyncCLIOption optional: OFString.class]
                       withLongName: @"api-key"]
                           withHelp: @"Gelbooru API key. Defaults to GELBOORU_API_KEY, then the local development default. Ignored for Realbooru."];

    _userID = [[[AsyncCLIOption optional: OFString.class]
                       withLongName: @"user-id"]
                           withHelp: @"Gelbooru user ID. Defaults to GELBOORU_USER_ID, then the local development default. Ignored for Realbooru."];

    _tags = [[[AsyncCLIOption optional: OFString.class]
                    withShortName: 't']
                         withHelp: @"Space-separated search tags. Defaults to rating:general for Gelbooru and all for Realbooru."];

    _exclude = [[[AsyncCLIOption optional: OFString.class]
                       withShortName: 'x']
                            withHelp: @"Space-separated tags to exclude"];

    _page = [[[[AsyncCLIOption optional: OFNumber.class]
                     withShortName: 'p']
                          withHelp: @"Zero-based result page"]
                  withDefaultValue: [OFNumber numberWithInt: 0]];

    _limit = [[[[AsyncCLIOption optional: OFNumber.class]
                      withShortName: 'l']
                           withHelp: @"Posts to request. Gelbooru supports 1 to 100; Realbooru supports 1 to 42."]
                   withDefaultValue: [OFNumber numberWithInt: 5]];

    _scale = [[[[AsyncCLIOption optional: OFNumber.class]
                       withLongName: @"scale"]
                           withHelp: @"Image width as a fraction of the terminal session, from 0.01 to 1. Row width is capped at 1."]
                   withDefaultValue: [OFNumber numberWithDouble: 1.0]];

    _columns = [[[[AsyncCLIOption optional: OFNumber.class]
                         withLongName: @"columns"]
                             withHelp: @"Images per gallery row, from 1 to 8"]
                     withDefaultValue: [OFNumber numberWithInt: 3]];

    _maxEdge = [[[[AsyncCLIOption optional: OFNumber.class]
        withLongName: @"max-edge"]
        withHelp: @"Base downscaled image maximum pixel edge before --scale. Use 0 to disable resizing."]
        withDefaultValue: [OFNumber numberWithInt: 512]];
    _jpegQuality = [[[[[AsyncCLIOption optional: OFNumber.class]
        withLongName: @"jpeg-quality"]
        withValueName: @"QUALITY"]
        withHelp: @"JPEG quality for resized gallery images, from 0.01 to 1"]
        withDefaultValue: [OFNumber numberWithDouble: 0.82]];
    _graphicsProtocol = [[[[AsyncCLIOption optional: OFString.class]
        withLongName: @"graphics-protocol"]
        withHelp: @"Terminal graphics protocol: auto, iterm2, or kitty"]
        withDefaultValue: @"auto"];
    _baseIRI = [[[AsyncCLIOption optional: OFIRI.class]
        withLongName: @"base-iri"]
        withHelp: @"Override the selected service base IRI"];
    _cacheDir = [[[AsyncCLIOption optional: OFString.class]
        withLongName: @"cache-dir"]
        withHelp: @"Directory for cached gallery images and search manifests"];
    _cacheOnly = [[[AsyncCLIOption flag]
        withLongName: @"cache-only"]
        withHelp: @"Render matching images from the cache without fetching posts or media"];
    return self;
}

+ (OFString *)cliCommandName
{
    return @"booruaggr";
}

+ (OFString *)cliCommandDescription
{
    return @"Fetch and render a booru gallery";
}

@end

[[subclassing_restricted, direct_members]]
@interface BooruImageCache : OFObject

@property(readonly, nonatomic) OFIRI *rootIRI;

- (instancetype)initWithRootIRI: (OFIRI *)rootIRI [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (OFString *)cacheFilenameForDisplayIRI: (OFIRI *)displayIRI
                                  postID: (OFString *)postID
                            maxPixelEdge: (size_t)maxPixelEdge
                             jpegQuality: (double)jpegQuality;
- (ITerm2InlineImage *nillable)cachedImageWithCacheFilename: (OFString *)cacheFilename
                                            displayFilename: (OFString *)displayFilename;
- (void)storeImage: (ITerm2InlineImage *)image
     cacheFilename: (OFString *)cacheFilename;
- (void)writeManifestEntries: (OFArray<OFPair<OFString *, OFString *> *> *)entries
                      forKey: (OFString *)manifestKey;
- (OFArray<ITerm2InlineImage *> *)cachedImagesForManifestKey: (OFString *)manifestKey
                                                       limit: (size_t)limit;

@end

@implementation BooruImageCache

- (instancetype)initWithRootIRI: (OFIRI *)rootIRI
{
    self = [super init];
    _rootIRI = rootIRI;
    return self;
}

- (OFIRI *)_imagesDirectoryIRI [[direct]]
{
    return [self.rootIRI IRIByAppendingPathComponent: @"images"
                                        isDirectory: true];
}

- (OFIRI *)_manifestsDirectoryIRI [[direct]]
{
    return [self.rootIRI IRIByAppendingPathComponent: @"manifests"
                                        isDirectory: true];
}

- (void)_ensureDirectories [[direct]]
{
    auto fileManager = OFFileManager.defaultManager;

    [fileManager createDirectoryAtIRI: self.rootIRI
                         createParents: true];
    [fileManager createDirectoryAtIRI: self._imagesDirectoryIRI
                         createParents: true];
    [fileManager createDirectoryAtIRI: self._manifestsDirectoryIRI
                         createParents: true];
}

- (OFIRI *)_IRIForImageCacheFilename: (OFString *)cacheFilename [[direct]]
{
    return [self._imagesDirectoryIRI IRIByAppendingPathComponent: cacheFilename
                                                     isDirectory: false];
}

- (OFIRI *)_IRIForManifestKey: (OFString *)manifestKey [[direct]]
{
    return [self._manifestsDirectoryIRI IRIByAppendingPathComponent: [OFString stringWithFormat: @"%@.tsv", manifestKey]
                                                        isDirectory: false];
}

- (OFString *)_extensionForDisplayIRI: (OFIRI *)displayIRI
                         maxPixelEdge: (size_t)maxPixelEdge [[direct]]
{
    OFString *lowercaseIRI = displayIRI.string.lowercaseString;

    if ([lowercaseIRI hasSuffix: @".gif"] or [lowercaseIRI containsString: @".gif?"])
        return @"gif";
    if (maxPixelEdge != 0)
        return @"jpg";
    if (displayIRI.pathExtension.length > 0)
        return displayIRI.pathExtension.lowercaseString;

    return @"img";
}

- (OFString *)cacheFilenameForDisplayIRI: (OFIRI *)displayIRI
                                  postID: (OFString *)postID
                            maxPixelEdge: (size_t)maxPixelEdge
                             jpegQuality: (double)jpegQuality
{
    OFString *key = [OFString stringWithFormat: @"v1\t%@\t%@\t%zu\t%.6f",
                                               postID,
                                               displayIRI.string,
                                               maxPixelEdge,
                                               jpegQuality];
    OFString *extension = [self _extensionForDisplayIRI: displayIRI
                                           maxPixelEdge: maxPixelEdge];

    return [OFString stringWithFormat: @"%@.%@",
                                      key.stringBySHA256Hashing,
                                      extension];
}

- (ITerm2InlineImage *nillable)cachedImageWithCacheFilename: (OFString *)cacheFilename
                                            displayFilename: (OFString *)displayFilename
{
    OFIRI *imageIRI = [self _IRIForImageCacheFilename: cacheFilename];

    @try {
        if (not [OFFileManager.defaultManager fileExistsAtIRI: imageIRI])
            return nilptr;

        return [[ITerm2InlineImage alloc] initWithFilename: displayFilename
                                                      data: [OFData dataWithContentsOfIRI: imageIRI]];
    } @catch (OFException *) {
        return nilptr;
    }
}

- (void)storeImage: (ITerm2InlineImage *)image
     cacheFilename: (OFString *)cacheFilename
{
    [self _ensureDirectories];
    [image.data writeToIRI: [self _IRIForImageCacheFilename: cacheFilename]];
}

- (void)writeManifestEntries: (OFArray<OFPair<OFString *, OFString *> *> *)entries
                      forKey: (OFString *)manifestKey
{
    if (entries.count == 0)
        return;

    auto manifest = [[OFMutableString alloc] init];

    for (OFPair<OFString *, OFString *> *entry in entries)
        [manifest appendFormat: @"%@\t%@\n", entry.firstObject, entry.secondObject];

    [self _ensureDirectories];
    [manifest writeToIRI: [self _IRIForManifestKey: manifestKey]
                encoding: OFStringEncodingUTF8];
}

- (OFArray<ITerm2InlineImage *> *)cachedImagesForManifestKey: (OFString *)manifestKey
                                                       limit: (size_t)limit
{
    OFIRI *manifestIRI = [self _IRIForManifestKey: manifestKey];
    auto images = [OFMutableArray<ITerm2InlineImage *> array];

    @try {
        if (not [OFFileManager.defaultManager fileExistsAtIRI: manifestIRI])
            return [images copy];

        OFString *manifest = [OFString stringWithContentsOfIRI: manifestIRI
                                                      encoding: OFStringEncodingUTF8];

        for (OFString *line in [manifest componentsSeparatedByString: @"\n"]) {
            if (limit > 0 and images.count >= limit)
                break;
            if (line.length == 0)
                continue;

            OFArray<OFString *> *fields = [line componentsSeparatedByString: @"\t"];
            if (fields.count < 2)
                continue;

            ITerm2InlineImage *nillable image = [self cachedImageWithCacheFilename: fields[0]
                                                                   displayFilename: fields[1]];
            if (image != nilptr)
                [images addObject: $assert_nonnil(image)];
        }
    } @catch (OFException *) {
        return [images copy];
    }

    return [images copy];
}

@end

[[subclassing_restricted]]
@interface Application : AsyncApplication
@end

@implementation Application

- (OFNumber *)_exitStatusValue: (int)status [[direct]]
{
    return [OFNumber numberWithInt: status];
}

- (OFString *nillable)_environmentValueForKey: (OFString *)key [[direct]]
{
    OFDictionary<OFString *, OFString *> *nillable environment = OFApplication.environment;

    if (environment == nilptr)
        return nilptr;

    return environment[key];
}

- (OFString *)_credentialFromOption: (AsyncCLIOption<OFString *> *)option
                     environmentKey: (OFString *)environmentKey
                       defaultValue: (OFString *)defaultValue [[direct]]
{
    OFString *nillable environmentValue;

    if (option.hasValue and option.value.length > 0)
        return option.value;

    environmentValue = [self _environmentValueForKey: environmentKey];
    if (environmentValue != nilptr and environmentValue.length > 0)
        return $assert_nonnil(environmentValue);

    return defaultValue;
}

- (OFArray<OFString *> *)_tagsFromSearchString: (OFString *)searchString [[direct]]
{
    auto tags = [OFMutableArray<OFString *> array];

    for (OFString *tag in [searchString componentsSeparatedByString: @" "]) {
        if (tag.length > 0)
            [tags addObject: tag];
    }

    return [tags copy];
}

- (OFString *)_normalizedBooruNameForCommand: (BooruFetchCommand *)command [[direct]]
{
    return command.booru.value.lowercaseString;
}

- (OFString *)_normalizedGraphicsProtocolNameForCommand: (BooruFetchCommand *)command [[direct]]
{
    return command.graphicsProtocol.value.lowercaseString;
}

- (bool)_booruNameIsRealbooru: (OFString *)booruName [[direct]]
{
    return [booruName isEqual: @"realbooru"];
}

- (bool)_environmentLooksKittyCompatible [[direct]]
{
    OFString *nillable kittyWindowID = [self _environmentValueForKey: @"KITTY_WINDOW_ID"];
    OFString *nillable term = [self _environmentValueForKey: @"TERM"];
    OFString *nillable termProgram = [self _environmentValueForKey: @"TERM_PROGRAM"];

    if (kittyWindowID != nilptr and kittyWindowID.length > 0)
        return true;
    if (term != nilptr and [term.lowercaseString containsString: @"kitty"])
        return true;
    if (termProgram != nilptr) {
        OFString *lowercaseTermProgram = termProgram.lowercaseString;

        if ([lowercaseTermProgram containsString: @"kitty"] or
            [lowercaseTermProgram containsString: @"ghostty"] or
            [lowercaseTermProgram containsString: @"wezterm"])
            return true;
    }

    return false;
}

- (TerminalGraphicsProtocol)_graphicsProtocolForCommand: (BooruFetchCommand *)command [[direct]]
{
    OFString *protocolName = [self _normalizedGraphicsProtocolNameForCommand: command];

    if ([protocolName isEqual: @"kitty"] or
        ([protocolName isEqual: @"auto"] and self._environmentLooksKittyCompatible))
        return TerminalGraphicsProtocolKitty;

    return TerminalGraphicsProtocolITerm2;
}

- (OFString *)_effectiveTagStringForCommand: (BooruFetchCommand *)command
                                  booruName: (OFString *)booruName [[direct]]
{
    if ([self _booruNameIsRealbooru: booruName] and not command.tags.hasValue)
        return @"all";
    if (not command.tags.hasValue)
        return @"rating:general";

    return command.tags.value;
}

- (OFIRI *)_defaultBaseIRIForBooruName: (OFString *)booruName [[direct]]
{
    if ([self _booruNameIsRealbooru: booruName])
        return [OFIRI IRIWithString: @"https://realbooru.com/"];

    return [OFIRI IRIWithString: @"https://gelbooru.com/"];
}

- (OFIRI *)_defaultCacheDirectoryIRI [[direct]]
{
    OFString *nillable cacheHome = [self _environmentValueForKey: @"XDG_CACHE_HOME"];
    OFString *nillable home = [self _environmentValueForKey: @"HOME"];

    if (cacheHome != nilptr and cacheHome.length > 0)
        return [[OFIRI fileIRIWithPath: $assert_nonnil(cacheHome)
                           isDirectory: true] IRIByAppendingPathComponent: @"booruaggr"
                                                              isDirectory: true];

    if (home != nilptr and home.length > 0) {
#if defined(OF_MACOS)
        OFString *path = [$assert_nonnil(home) stringByAppendingString: @"/Library/Caches/booruaggr"];
#else
        OFString *path = [$assert_nonnil(home) stringByAppendingString: @"/.cache/booruaggr"];
#endif
        return [OFIRI fileIRIWithPath: path
                          isDirectory: true];
    }

    OFIRI *nillable temporaryDirectoryIRI = OFSystemInfo.temporaryDirectoryIRI;
    if (temporaryDirectoryIRI != nilptr)
        return [$assert_nonnil(temporaryDirectoryIRI) IRIByAppendingPathComponent: @"booruaggr-cache"
                                                                      isDirectory: true];

    return [OFIRI fileIRIWithPath: @"/tmp/booruaggr-cache"
                      isDirectory: true];
}

- (OFIRI *)_cacheRootIRIForCommand: (BooruFetchCommand *)command [[direct]]
{
    if (command.cacheDir.hasValue)
        return [OFIRI fileIRIWithPath: command.cacheDir.value
                          isDirectory: true];

    return self._defaultCacheDirectoryIRI;
}

- (OFString *)_cacheManifestKeyForCommand: (BooruFetchCommand *)command
                                booruName: (OFString *)booruName
                                 baseIRI: (OFIRI *)baseIRI
                                    tags: (OFArray<OFString *> *)tags
                            excludedTags: (OFArray<OFString *> *)excludedTags [[direct]]
{
    OFString *key = [OFString stringWithFormat: @"v1\tbooru=%@\tbase=%@\tpage=%d\tlimit=%llu\ttags=%@\texclude=%@\tmax-edge=%zu\tjpeg-quality=%.6f",
                                               booruName,
                                               baseIRI.string,
                                               command.page.value.intValue,
                                               command.limit.value.unsignedLongLongValue,
                                               [tags componentsJoinedByString: @" "],
                                               [excludedTags componentsJoinedByString: @" "],
                                               [self _effectiveMaxPixelEdgeForCommand: command],
                                               command.jpegQuality.value.doubleValue];

    return key.stringBySHA256Hashing;
}

- (bool)_validateCommand: (BooruFetchCommand *)command [[direct]]
{
    OFString *booruName = [self _normalizedBooruNameForCommand: command];
    size_t maximumLimit;

    if (not [booruName isEqual: @"gelbooru"] and not [self _booruNameIsRealbooru: booruName]) {
        [OFStdErr writeLine: @"error: --booru must be gelbooru or realbooru"];
        return false;
    }

    if (command.page.value.intValue < 0) {
        [OFStdErr writeLine: @"error: --page must be >= 0"];
        return false;
    }

    maximumLimit = [self _booruNameIsRealbooru: booruName] ? 42 : 100;
    if (command.limit.value.unsignedLongValue == 0 or command.limit.value.unsignedLongValue > maximumLimit) {
        [OFStdErr writeFormat: @"error: --limit must be between 1 and %zu for %@\n",
                              maximumLimit,
                              booruName];
        return false;
    }

    if ([self _tagsFromSearchString: [self _effectiveTagStringForCommand: command booruName: booruName]].count == 0) {
        [OFStdErr writeLine: @"error: --tags must contain at least one tag"];
        return false;
    }

    if (command.scale.value.doubleValue < 0.01 or command.scale.value.doubleValue > 1) {
        [OFStdErr writeLine: @"error: --scale must be between 0.01 and 1"];
        return false;
    }

    if (command.columns.value.unsignedLongValue == 0 or command.columns.value.unsignedLongValue > 8) {
        [OFStdErr writeLine: @"error: --columns must be between 1 and 8"];
        return false;
    }

    if (command.maxEdge.value.unsignedLongValue > 4096) {
        [OFStdErr writeLine: @"error: --max-edge must be between 0 and 4096"];
        return false;
    }

    if (command.jpegQuality.value.doubleValue < 0.01 or command.jpegQuality.value.doubleValue > 1) {
        [OFStdErr writeLine: @"error: --jpeg-quality must be between 0.01 and 1"];
        return false;
    }

    OFString *graphicsProtocolName = [self _normalizedGraphicsProtocolNameForCommand: command];
    if (not [graphicsProtocolName isEqual: @"auto"] and
        not [graphicsProtocolName isEqual: @"iterm2"] and
        not [graphicsProtocolName isEqual: @"kitty"]) {
        [OFStdErr writeLine: @"error: --graphics-protocol must be auto, iterm2, or kitty"];
        return false;
    }

    if (command.cacheDir.hasValue and command.cacheDir.value.length == 0) {
        [OFStdErr writeLine: @"error: --cache-dir must not be empty"];
        return false;
    }

    return true;
}

- (size_t)_effectiveMaxPixelEdgeForCommand: (BooruFetchCommand *)command [[direct]]
{
    size_t maxPixelEdge = command.maxEdge.value.unsignedLongValue;

    if (maxPixelEdge == 0)
        return 0;

    double scaledMaxPixelEdge = (double)maxPixelEdge * command.scale.value.doubleValue;

    if (scaledMaxPixelEdge < 1.0)
        return 1;

    return (size_t)(scaledMaxPixelEdge + 0.5);
}

- (OFIRI *)_displayIRIForPost: (BooruPost *)post [[direct]]
{
    OFString *lowercaseFileIRI = post.fileIRI.string.lowercaseString;

    if ([lowercaseFileIRI hasSuffix: @".gif"] or [lowercaseFileIRI containsString: @".gif?"])
        return post.fileIRI;

    if (post.sampleIRI != nilptr)
        return $assert_nonnil(post.sampleIRI);

    return post.fileIRI;
}

- (ITerm2InlineImage *)_imageForPost: (BooruPost *)post
                                booru: (id<Booru>)booru
                              command: (BooruFetchCommand *)command
                                cache: (BooruImageCache *)cache
                        manifestEntry: (OFPair<OFString *, OFString *> *nillable *)manifestEntry
                            scheduler: (AsyncScheduler *)scheduler [[direct]]
{
    OFIRI *displayIRI = [self _displayIRIForPost: post];
    size_t maxPixelEdge = [self _effectiveMaxPixelEdgeForCommand: command];
    OFString *cacheFilename = [cache cacheFilenameForDisplayIRI: displayIRI
                                                        postID: post.id
                                                  maxPixelEdge: maxPixelEdge
                                                   jpegQuality: command.jpegQuality.value.doubleValue];
    OFString *displayFilename = displayIRI.lastPathComponent.length > 0
        ? displayIRI.lastPathComponent
        : [OFString stringWithFormat: @"post-%@", post.id];
    ITerm2InlineImage *nillable cachedImage = [cache cachedImageWithCacheFilename: cacheFilename
                                                                  displayFilename: displayFilename];

    if (cachedImage != nilptr) {
        *manifestEntry = [OFPair pairWithFirstObject: cacheFilename
                                        secondObject: $assert_nonnil(cachedImage).filename];
        return $assert_nonnil(cachedImage);
    }

    auto image = [[ITerm2ImageGallery taskToLoadImageAtIRI: displayIRI
                                                usingClient: booru.httpClient
                                                 refererIRI: booru.baseIRI
                                                maxPixelEdge: maxPixelEdge
                                                 jpegQuality: command.jpegQuality.value.doubleValue
                                                 onScheduler: scheduler] await];

    @try {
        [cache storeImage: image
            cacheFilename: cacheFilename];
        *manifestEntry = [OFPair pairWithFirstObject: cacheFilename
                                        secondObject: image.filename];
    } @catch (OFException *exception) {
        [OFStdErr writeFormat: @"\nwarning: failed to cache post %@: %@\n", post.id, exception];
        *manifestEntry = nilptr;
    }

    return image;
}

- (id<Booru>)_booruForCommand: (BooruFetchCommand *)command
                    booruName: (OFString *)booruName [[direct]]
{
    OFIRI *baseIRI = [command.baseIRI valueOr: [self _defaultBaseIRIForBooruName: booruName]];

    if ([self _booruNameIsRealbooru: booruName])
        return [[Realbooru alloc] initWithBaseIRI: baseIRI
                                    postsPerPage: command.limit.value.unsignedLongValue];

    return [[Gelbooru alloc] initWithAPIUserID: [self _credentialFromOption: command.userID
                                                             environmentKey: @"GELBOORU_USER_ID"
                                                               defaultValue: DEFAULT_GELBOORU_USER_ID]
                                        andKey: [self _credentialFromOption: command.apiKey
                                                             environmentKey: @"GELBOORU_API_KEY"
                                                               defaultValue: DEFAULT_GELBOORU_API_KEY]
                                       baseIRI: baseIRI
                                  postsPerPage: command.limit.value.unsignedLongValue];
}

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification taskGroup: (AsyncTaskGroup *)taskGroup
{
    (void)notification;

    auto command = [[BooruFetchCommand alloc] init];
    auto parser = [[AsyncArgumentParser<BooruFetchCommand *> alloc] initWithCommand: command];

    @try {
        [parser parseCommandLineArguments];
    } @catch (AsyncArgumentParserHelpException *exception) {
        [OFStdOut writeLine: exception.description];
        return [self _exitStatusValue: 0];
    } @catch (AsyncArgumentParserException *exception) {
        [OFStdErr writeLine: exception.description];
        return [self _exitStatusValue: 64];
    }

    if (not [self _validateCommand: command])
        return [self _exitStatusValue: 64];

    OFString *booruName = [self _normalizedBooruNameForCommand: command];
    OFIRI *baseIRI = [command.baseIRI valueOr: [self _defaultBaseIRIForBooruName: booruName]];
    OFArray<OFString *> *tags = [self _tagsFromSearchString: [self _effectiveTagStringForCommand: command
                                                                                       booruName: booruName]];
    OFArray<OFString *> *excludedTags = [self _tagsFromSearchString: [command.exclude valueOr: @""]];
    auto cache = [[BooruImageCache alloc] initWithRootIRI: [self _cacheRootIRIForCommand: command]];
    OFString *manifestKey = [self _cacheManifestKeyForCommand: command
                                                    booruName: booruName
                                                      baseIRI: baseIRI
                                                         tags: tags
                                                 excludedTags: excludedTags];

    if (command.cacheOnly.boolValue) {
        OFArray<ITerm2InlineImage *> *images = [cache cachedImagesForManifestKey: manifestKey
                                                                           limit: command.limit.value.unsignedLongValue];

        if (images.count == 0) {
            [OFStdOut writeLine: @"No cached images found."];
            return [self _exitStatusValue: 0];
        }

        [ITerm2ImageGallery writeImages: images
                                columns: command.columns.value.unsignedLongValue
                                  scale: command.scale.value.doubleValue
                            jpegQuality: command.jpegQuality.value.doubleValue
                        graphicsProtocol: [self _graphicsProtocolForCommand: command]];

        return [self _exitStatusValue: 0];
    }

    id<Booru> booru = [self _booruForCommand: command booruName: booruName];

    auto loadingView = [[TerminalLoadingView alloc] init];
    [loadingView updateWithIndex: 0 total: command.limit.value.unsignedLongValue status: @"Fetching" detail: @"posts"];

    Optional<BooruPage *> *pageOpt = [[booru fetchPage: command.page.value.intValue
                                     forSearchWithTags: tags
                                         excludingTags: excludedTags] await];

    if (not pageOpt.hasValue) {
        [loadingView clear];
        [OFStdOut writeLine: @"No posts found."];
        return [self _exitStatusValue: 0];
    }

    auto pg = pageOpt.value;
    auto images = [OFMutableArray<ITerm2InlineImage *> arrayWithCapacity: pg.posts.count];
    auto manifestEntries = [OFMutableArray<OFPair<OFString *, OFString *> *> arrayWithCapacity: pg.posts.count];
    size_t imageIndex = 0;

    for (BooruPost *post in pg.posts) {
        OFPair<OFString *, OFString *> *nillable manifestEntry = nilptr;

        imageIndex++;
        [loadingView updateWithIndex: imageIndex total: pg.posts.count status: @"Loading" detail: post.id];

        @try {
            auto image = [self _imageForPost: post
                                        booru: booru
                                      command: command
                                        cache: cache
                                manifestEntry: &manifestEntry
                                    scheduler: taskGroup.scheduler];
            [images addObject: image];
            if (manifestEntry != nilptr)
                [manifestEntries addObject: $assert_nonnil(manifestEntry)];
        } @catch (OFException *exception) {
            [OFStdErr writeFormat: @"\nwarning: skipped post %@: %@\n", post.id, exception];
        }
    }

    [loadingView finishWithMessage: [OFString stringWithFormat: @"Loaded %zu image(s).", images.count]];

    @try {
        [cache writeManifestEntries: manifestEntries
                              forKey: manifestKey];
    } @catch (OFException *exception) {
        [OFStdErr writeFormat: @"warning: failed to write cache manifest: %@\n", exception];
    }

    if (images.count == 0)
        return [self _exitStatusValue: 0];

    [ITerm2ImageGallery writeImages: images
                            columns: command.columns.value.unsignedLongValue
                              scale: command.scale.value.doubleValue
                        jpegQuality: command.jpegQuality.value.doubleValue
                    graphicsProtocol: [self _graphicsProtocolForCommand: command]];

    return [self _exitStatusValue: 0];
}

- (void)asyncApplicationDidFailWithException: (OFException *)exception
{
    

    [OFStdErr writeFormat: @"error: %@\n", exception];
}

- (int)someFunc{return 1;}

@end

#pragma clang assume_nonnull end

OF_APPLICATION_DELEGATE(Application)
