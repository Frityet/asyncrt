#import "ITerm2ImageGallery.h"

#import "AsyncHTTPClientBridge.h"

#include <limits.h>
#include <math.h>

#if defined(OF_MACOS)
# import <CoreFoundation/CoreFoundation.h>
# import <CoreGraphics/CoreGraphics.h>
# import <ImageIO/ImageIO.h>
#endif

#if defined(__unix__) || defined(__APPLE__)
# include <sys/ioctl.h>
# include <unistd.h>
#endif

#pragma clang assume_nonnull begin

#if defined(OF_MACOS)
[[subclassing_restricted, direct_members]]
@interface ITerm2DecodedImage : OFObject

@property(readonly, nonatomic) CGImageRef image;
@property(readonly, nonatomic) size_t width;
@property(readonly, nonatomic) size_t height;
@property(readonly, nonatomic) double duration;

- (instancetype)initTakingImage: (CGImageRef)image;
- (instancetype)initTakingImage: (CGImageRef)image
                        duration: (double)duration [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface ITerm2DecodedImageSequence : OFObject

@property(readonly, copy, nonatomic) OFArray<ITerm2DecodedImage *> *frames;
@property(readonly, nonatomic) size_t width;
@property(readonly, nonatomic) size_t height;
@property(readonly, nonatomic) bool isAnimated;

- (instancetype)initWithFrames: (OFArray<ITerm2DecodedImage *> *)frames
                         width: (size_t)width
                        height: (size_t)height
                    isAnimated: (bool)isAnimated [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end
#endif

@namespace(ITerm2ImageGallerySupport)

+ (OFString *)base64EncodedUTF8String: (OFString *)string;
+ (OFData *)imageDataByDownscalingImageData: (OFData *)data
                               maxPixelEdge: (size_t)maxPixelEdge
                                jpegQuality: (double)jpegQuality;
#if defined(OF_MACOS)
+ (CFDataRef nillable)newCFDataFromData: (OFData *)data;
+ (ITerm2DecodedImageSequence *nillable)decodedImageSequenceFromData: (OFData *)data;
+ (bool)imageSourceIsGIF: (CGImageSourceRef)source;
+ (bool)imageDataIsGIF: (OFData *)data;
+ (double)GIFDelayForImageSource: (CGImageSourceRef)source
                       frameIndex: (size_t)frameIndex;
+ (CFDictionaryRef nillable)newGIFFramePropertiesWithDelay: (double)delay;
+ (CFDictionaryRef nillable)newGIFLoopProperties;
+ (CGImageRef nillable)newImageFromSource: (CGImageSourceRef)source
                                frameIndex: (size_t)frameIndex
                              maxPixelEdge: (size_t)maxPixelEdge;
+ (OFData *)GIFDataByDownscalingImageSource: (CGImageSourceRef)source
                                 frameCount: (size_t)frameCount
                               maxPixelEdge: (size_t)maxPixelEdge;
+ (OFData *)JPEGDataWithImage: (CGImageRef)image
                  jpegQuality: (double)jpegQuality;
+ (OFData *)PNGDataWithImage: (CGImageRef)image;
+ (OFData *)animatedGIFContactSheetDataWithSequences: (OFArray<ITerm2DecodedImageSequence *> *)sequences
                                             cellGap: (size_t)cellGap;
+ (CGImageRef nillable)newContactSheetImageWithSequences: (OFArray<ITerm2DecodedImageSequence *> *)sequences
                                                cellWidth: (size_t)cellWidth
                                               cellHeight: (size_t)cellHeight
                                                  cellGap: (size_t)cellGap
                                               frameIndex: (size_t)frameIndex;
#endif
+ (size_t)terminalColumnCount;
+ (double)terminalCellWidthToHeightRatio;
+ (size_t)kittyColumnCountForDisplayWidth: (OFString *)displayWidth;
+ (size_t)kittyRowCountForImageWidth: (size_t)imageWidth
                               height: (size_t)imageHeight
                              columns: (size_t)columns;
+ (OFString *)kittyBaseControlDataForColumns: (size_t)columns
                                        rows: (size_t)rows
                                     imageID: (unsigned int)imageID;
+ (void)writeKittyGraphicsData: (OFData *)data
                   controlData: (OFString *)controlData
          continuedControlData: (OFString *)continuedControlData;
+ (void)writeKittyControlData: (OFString *)controlData;
+ (unsigned int)kittyFrameDelayMilliseconds: (double)duration;
+ (void)writeKittyImageData: (OFData *)data
               displayWidth: (OFString *)displayWidth
                    imageID: (unsigned int)imageID;
+ (OFData *)contactSheetDataWithImages: (OFArray<ITerm2InlineImage *> *)images
                              cellGap: (size_t)cellGap
                          jpegQuality: (double)jpegQuality;

@end

#if defined(OF_MACOS)
@implementation ITerm2DecodedImage {
    CGImageRef _image;
}

- (instancetype)initTakingImage: (CGImageRef)image
{
    return [self initTakingImage: image duration: 0.1];
}

- (instancetype)initTakingImage: (CGImageRef)image
                       duration: (double)duration
{
    self = [super init];
    _image = image;
    _width = CGImageGetWidth(image);
    _height = CGImageGetHeight(image);
    _duration = duration;
    return self;
}

- (void)dealloc
{
    if (_image != nullptr)
        CGImageRelease(_image);
}

@end

@implementation ITerm2DecodedImageSequence

- (instancetype)initWithFrames: (OFArray<ITerm2DecodedImage *> *)frames
                         width: (size_t)width
                        height: (size_t)height
                    isAnimated: (bool)isAnimated
{
    self = [super init];
    _frames = [frames copy];
    _width = width;
    _height = height;
    _isAnimated = isAnimated;
    return self;
}

@end
#endif

@implementation ITerm2InlineImage

- (instancetype)initWithFilename: (OFString *)filename
                            data: (OFData *)data
{
    self = [super init];
    _filename = [filename copy];
    _data = data;
    return self;
}

- (void)writeWithDisplayWidth: (OFString *)displayWidth
{
    auto base64Filename = [ITerm2ImageGallerySupport base64EncodedUTF8String: self.filename];

    [OFStdOut writeFormat: @"\033]1337;File=name=%@;inline=1;width=%@;height=auto;preserveAspectRatio=1:%@\a",
                              base64Filename,
                              displayWidth,
                              self.data.stringByBase64Encoding];
}

@end

@namespace_implementation(ITerm2ImageGallerySupport)

+ (OFString *)base64EncodedUTF8String: (OFString *)string
{
    return [OFData dataWithItems: string.UTF8String
                           count: string.UTF8StringLength].stringByBase64Encoding;
}

#if defined(OF_MACOS)
+ (CFDataRef nillable)newCFDataFromData: (OFData *)data
{
    if (data.items == nullptr or data.count == 0)
        return nullptr;

    size_t byteCount = data.count * data.itemSize;
    return CFDataCreate(kCFAllocatorDefault, data.items, (CFIndex)byteCount);
}

+ (bool)imageSourceIsGIF: (CGImageSourceRef)source
{
    CFStringRef nillable sourceType = CGImageSourceGetType(source);

    return sourceType != nullptr and CFEqual($assert_nonnil(sourceType), CFSTR("com.compuserve.gif"));
}

+ (bool)imageDataIsGIF: (OFData *)data
{
    CFDataRef nillable sourceData = [self newCFDataFromData: data];
    CGImageSourceRef nillable source = nullptr;

    if (sourceData == nullptr)
        return false;

    @try {
        source = CGImageSourceCreateWithData($assert_nonnil(sourceData), nullptr);
        if (source == nullptr)
            return false;

        return [self imageSourceIsGIF: $assert_nonnil(source)];
    } @finally {
        if (source != nullptr)
            CFRelease(source);
        CFRelease(sourceData);
    }
}

+ (double)GIFDelayForImageSource: (CGImageSourceRef)source
                       frameIndex: (size_t)frameIndex
{
    CFDictionaryRef nillable frameProperties = nullptr;
    double delay = 0.1;

    frameProperties = CGImageSourceCopyPropertiesAtIndex(source, frameIndex, nullptr);
    if (frameProperties == nullptr)
        return delay;

    @try {
        CFDictionaryRef nillable GIFProperties = (CFDictionaryRef)CFDictionaryGetValue($assert_nonnil(frameProperties),
                                                                                       kCGImagePropertyGIFDictionary);
        CFNumberRef nillable delayNumber = nullptr;

        if (GIFProperties == nullptr)
            return delay;

        delayNumber = (CFNumberRef)CFDictionaryGetValue($assert_nonnil(GIFProperties),
                                                        kCGImagePropertyGIFUnclampedDelayTime);
        if (delayNumber == nullptr)
            delayNumber = (CFNumberRef)CFDictionaryGetValue($assert_nonnil(GIFProperties),
                                                            kCGImagePropertyGIFDelayTime);
        if (delayNumber != nullptr)
            CFNumberGetValue($assert_nonnil(delayNumber), kCFNumberDoubleType, &delay);

        if (delay <= 0)
            return 0.1;
        if (delay < 0.02)
            return 0.02;

        return delay;
    } @finally {
        CFRelease(frameProperties);
    }
}

+ (CFDictionaryRef nillable)newGIFFramePropertiesWithDelay: (double)delay
{
    CFNumberRef nillable delayNumber = nullptr;
    CFDictionaryRef nillable GIFProperties = nullptr;
    CFDictionaryRef nillable frameProperties = nullptr;

    delayNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &delay);
    if (delayNumber == nullptr)
        return nullptr;

    @try {
        const void *GIFKeys[] = {
            kCGImagePropertyGIFDelayTime,
            kCGImagePropertyGIFUnclampedDelayTime
        };
        const void *GIFValues[] = {
            delayNumber,
            delayNumber
        };
        GIFProperties = CFDictionaryCreate(kCFAllocatorDefault,
                                           GIFKeys,
                                           GIFValues,
                                           2,
                                           &kCFTypeDictionaryKeyCallBacks,
                                           &kCFTypeDictionaryValueCallBacks);
        if (GIFProperties == nullptr)
            return nullptr;

        const void *frameKeys[] = { kCGImagePropertyGIFDictionary };
        const void *frameValues[] = { GIFProperties };
        frameProperties = CFDictionaryCreate(kCFAllocatorDefault,
                                             frameKeys,
                                             frameValues,
                                             1,
                                             &kCFTypeDictionaryKeyCallBacks,
                                             &kCFTypeDictionaryValueCallBacks);
        return frameProperties;
    } @finally {
        if (GIFProperties != nullptr)
            CFRelease(GIFProperties);
        CFRelease(delayNumber);
    }
}

+ (CFDictionaryRef nillable)newGIFLoopProperties
{
    int loopCount = 0;
    CFNumberRef nillable loopCountNumber = nullptr;
    CFDictionaryRef nillable GIFProperties = nullptr;
    CFDictionaryRef nillable containerProperties = nullptr;

    loopCountNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &loopCount);
    if (loopCountNumber == nullptr)
        return nullptr;

    @try {
        const void *GIFKeys[] = { kCGImagePropertyGIFLoopCount };
        const void *GIFValues[] = { loopCountNumber };
        GIFProperties = CFDictionaryCreate(kCFAllocatorDefault,
                                           GIFKeys,
                                           GIFValues,
                                           1,
                                           &kCFTypeDictionaryKeyCallBacks,
                                           &kCFTypeDictionaryValueCallBacks);
        if (GIFProperties == nullptr)
            return nullptr;

        const void *containerKeys[] = { kCGImagePropertyGIFDictionary };
        const void *containerValues[] = { GIFProperties };
        containerProperties = CFDictionaryCreate(kCFAllocatorDefault,
                                                 containerKeys,
                                                 containerValues,
                                                 1,
                                                 &kCFTypeDictionaryKeyCallBacks,
                                                 &kCFTypeDictionaryValueCallBacks);
        return containerProperties;
    } @finally {
        if (GIFProperties != nullptr)
            CFRelease(GIFProperties);
        CFRelease(loopCountNumber);
    }
}

+ (CGImageRef nillable)newImageFromSource: (CGImageSourceRef)source
                               frameIndex: (size_t)frameIndex
                             maxPixelEdge: (size_t)maxPixelEdge
{
    if (maxPixelEdge == 0)
        return CGImageSourceCreateImageAtIndex(source, frameIndex, nullptr);

    int maxPixelSize = (maxPixelEdge > INT_MAX ? INT_MAX : (int)maxPixelEdge);
    CFNumberRef nillable maxPixelSizeNumber = nullptr;
    CFDictionaryRef nillable thumbnailOptions = nullptr;

    maxPixelSizeNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &maxPixelSize);
    if (maxPixelSizeNumber == nullptr)
        return nullptr;

    @try {
        const void *thumbnailKeys[] = {
            kCGImageSourceCreateThumbnailFromImageAlways,
            kCGImageSourceCreateThumbnailWithTransform,
            kCGImageSourceThumbnailMaxPixelSize
        };
        const void *thumbnailValues[] = {
            kCFBooleanTrue,
            kCFBooleanTrue,
            maxPixelSizeNumber
        };
        thumbnailOptions = CFDictionaryCreate(kCFAllocatorDefault,
                                             thumbnailKeys,
                                             thumbnailValues,
                                             3,
                                             &kCFTypeDictionaryKeyCallBacks,
                                             &kCFTypeDictionaryValueCallBacks);
        if (thumbnailOptions == nullptr)
            return nullptr;

        return CGImageSourceCreateThumbnailAtIndex(source, frameIndex, thumbnailOptions);
    } @finally {
        if (thumbnailOptions != nullptr)
            CFRelease(thumbnailOptions);
        CFRelease(maxPixelSizeNumber);
    }
}

+ (ITerm2DecodedImageSequence *nillable)decodedImageSequenceFromData: (OFData *)data
{
    CFDataRef nillable sourceData = [self newCFDataFromData: data];
    CGImageSourceRef nillable source = nullptr;

    if (sourceData == nullptr)
        return nilptr;

    @try {
        source = CGImageSourceCreateWithData($assert_nonnil(sourceData), nullptr);
        if (source == nullptr)
            return nilptr;

        size_t sourceFrameCount = CGImageSourceGetCount($assert_nonnil(source));
        bool isAnimated = [self imageSourceIsGIF: $assert_nonnil(source)] and sourceFrameCount > 1;
        size_t framesToDecode = isAnimated ? sourceFrameCount : 1;
        auto frames = [OFMutableArray<ITerm2DecodedImage *> arrayWithCapacity: framesToDecode];
        size_t width = 0;
        size_t height = 0;

        for (size_t frameIndex = 0; frameIndex < framesToDecode; frameIndex++) {
            CGImageRef nillable frameImage = CGImageSourceCreateImageAtIndex($assert_nonnil(source), frameIndex, nullptr);

            if (frameImage == nullptr)
                continue;

            double duration = isAnimated
                ? [self GIFDelayForImageSource: $assert_nonnil(source) frameIndex: frameIndex]
                : 0.1;
            auto decodedFrame = [[ITerm2DecodedImage alloc] initTakingImage: $assert_nonnil(frameImage)
                                                                    duration: duration];
            frameImage = nullptr;

            [frames addObject: decodedFrame];
            if (decodedFrame.width > width)
                width = decodedFrame.width;
            if (decodedFrame.height > height)
                height = decodedFrame.height;
        }

        if (frames.count == 0 or width == 0 or height == 0)
            return nilptr;

        return [[ITerm2DecodedImageSequence alloc] initWithFrames: [frames copy]
                                                            width: width
                                                           height: height
                                                       isAnimated: isAnimated];
    } @finally {
        if (source != nullptr)
            CFRelease(source);
        CFRelease(sourceData);
    }
}

+ (OFData *)GIFDataByDownscalingImageSource: (CGImageSourceRef)source
                                 frameCount: (size_t)frameCount
                               maxPixelEdge: (size_t)maxPixelEdge
{
    CFMutableDataRef nillable destinationData = nullptr;
    CGImageDestinationRef nillable destination = nullptr;
    CFDictionaryRef nillable loopProperties = nullptr;
    OFData *result = [OFData data];

    destinationData = CFDataCreateMutable(kCFAllocatorDefault, 0);
    if (destinationData == nullptr)
        return result;

    @try {
        destination = CGImageDestinationCreateWithData($assert_nonnil(destinationData), CFSTR("com.compuserve.gif"), frameCount, nullptr);
        if (destination == nullptr)
            return result;

        loopProperties = [self newGIFLoopProperties];
        if (loopProperties != nullptr)
            CGImageDestinationSetProperties($assert_nonnil(destination), loopProperties);

        for (size_t frameIndex = 0; frameIndex < frameCount; frameIndex++) {
            CGImageRef nillable frameImage = [self newImageFromSource: source
                                                           frameIndex: frameIndex
                                                         maxPixelEdge: maxPixelEdge];
            CFDictionaryRef nillable frameProperties = [self newGIFFramePropertiesWithDelay: [self GIFDelayForImageSource: source
                                                                                                                frameIndex: frameIndex]];

            if (frameImage != nullptr)
                CGImageDestinationAddImage($assert_nonnil(destination), $assert_nonnil(frameImage), frameProperties);

            if (frameProperties != nullptr)
                CFRelease(frameProperties);
            if (frameImage != nullptr)
                CGImageRelease(frameImage);
        }

        if (not CGImageDestinationFinalize($assert_nonnil(destination)))
            return result;

        return [OFData dataWithItems: CFDataGetBytePtr(destinationData)
                               count: (size_t)CFDataGetLength(destinationData)];
    } @finally {
        if (loopProperties != nullptr)
            CFRelease(loopProperties);
        if (destination != nullptr)
            CFRelease(destination);
        CFRelease(destinationData);
    }
}

+ (OFData *)JPEGDataWithImage: (CGImageRef)image
                  jpegQuality: (double)jpegQuality
{
    CFMutableDataRef nillable destinationData = nullptr;
    CGImageDestinationRef nillable destination = nullptr;
    CFNumberRef nillable qualityNumber = nullptr;
    CFDictionaryRef nillable destinationOptions = nullptr;
    OFData *result = [OFData data];

    destinationData = CFDataCreateMutable(kCFAllocatorDefault, 0);
    if (destinationData == nullptr)
        return result;

    @try {
        destination = CGImageDestinationCreateWithData($assert_nonnil(destinationData), CFSTR("public.jpeg"), 1, nullptr);
        if (destination == nullptr)
            return result;

        qualityNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &jpegQuality);
        if (qualityNumber == nullptr)
            return result;

        const void *destinationKeys[] = { kCGImageDestinationLossyCompressionQuality };
        const void *destinationValues[] = { qualityNumber };
        destinationOptions = CFDictionaryCreate(kCFAllocatorDefault,
                                               destinationKeys,
                                               destinationValues,
                                               1,
                                               &kCFTypeDictionaryKeyCallBacks,
                                               &kCFTypeDictionaryValueCallBacks);
        if (destinationOptions == nullptr)
            return result;

        CGImageDestinationAddImage($assert_nonnil(destination), image, destinationOptions);
        if (not CGImageDestinationFinalize($assert_nonnil(destination)))
            return result;

        return [OFData dataWithItems: CFDataGetBytePtr(destinationData)
                               count: (size_t)CFDataGetLength(destinationData)];
    } @finally {
        if (destinationOptions != nullptr)
            CFRelease(destinationOptions);
        if (qualityNumber != nullptr)
            CFRelease(qualityNumber);
        if (destination != nullptr)
            CFRelease(destination);
        CFRelease(destinationData);
    }
}

+ (OFData *)PNGDataWithImage: (CGImageRef)image
{
    CFMutableDataRef nillable destinationData = nullptr;
    CGImageDestinationRef nillable destination = nullptr;
    OFData *result = [OFData data];

    destinationData = CFDataCreateMutable(kCFAllocatorDefault, 0);
    if (destinationData == nullptr)
        return result;

    @try {
        destination = CGImageDestinationCreateWithData($assert_nonnil(destinationData), CFSTR("public.png"), 1, nullptr);
        if (destination == nullptr)
            return result;

        CGImageDestinationAddImage($assert_nonnil(destination), image, nullptr);
        if (not CGImageDestinationFinalize($assert_nonnil(destination)))
            return result;

        return [OFData dataWithItems: CFDataGetBytePtr(destinationData)
                               count: (size_t)CFDataGetLength(destinationData)];
    } @finally {
        if (destination != nullptr)
            CFRelease(destination);
        CFRelease(destinationData);
    }
}

+ (CGImageRef nillable)newContactSheetImageWithSequences: (OFArray<ITerm2DecodedImageSequence *> *)sequences
                                                cellWidth: (size_t)cellWidth
                                               cellHeight: (size_t)cellHeight
                                                  cellGap: (size_t)cellGap
                                               frameIndex: (size_t)frameIndex
{
    if (sequences.count == 0 or cellWidth == 0 or cellHeight == 0)
        return nullptr;

    size_t sheetWidth = (cellWidth * sequences.count) + (cellGap * (sequences.count - 1));
    size_t sheetHeight = cellHeight;
    CGColorSpaceRef nillable colorSpace = nullptr;
    CGContextRef nillable context = nullptr;

    colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == nullptr)
        return nullptr;

    @try {
        context = CGBitmapContextCreate(nullptr,
                                        sheetWidth,
                                        sheetHeight,
                                        8,
                                        0,
                                        $assert_nonnil(colorSpace),
                                        kCGImageAlphaPremultipliedLast);
        if (context == nullptr)
            return nullptr;

        CGContextSetRGBFillColor($assert_nonnil(context), 1.0, 1.0, 1.0, 1.0);
        CGContextFillRect($assert_nonnil(context), CGRectMake(0, 0, sheetWidth, sheetHeight));

        size_t column = 0;
        for (ITerm2DecodedImageSequence *sequence in sequences) {
            size_t sequenceFrameIndex = sequence.isAnimated
                ? frameIndex % sequence.frames.count
                : 0;
            ITerm2DecodedImage *decodedImage = sequence.frames[sequenceFrameIndex];
            CGFloat x = (CGFloat)(column * (cellWidth + cellGap)) + ((CGFloat)cellWidth - (CGFloat)decodedImage.width) / 2.0;
            CGFloat y = (CGFloat)sheetHeight - (CGFloat)decodedImage.height;
            CGRect rect = CGRectMake(x, y, decodedImage.width, decodedImage.height);

            CGContextDrawImage($assert_nonnil(context), rect, decodedImage.image);
            column++;
        }

        return CGBitmapContextCreateImage($assert_nonnil(context));
    } @finally {
        if (context != nullptr)
            CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
    }
}

+ (OFData *)animatedGIFContactSheetDataWithSequences: (OFArray<ITerm2DecodedImageSequence *> *)sequences
                                             cellGap: (size_t)cellGap
{
    ITerm2DecodedImageSequence *nillable driverSequence = nilptr;
    size_t cellWidth = 0;
    size_t cellHeight = 0;

    for (ITerm2DecodedImageSequence *sequence in sequences) {
        if (sequence.width > cellWidth)
            cellWidth = sequence.width;
        if (sequence.height > cellHeight)
            cellHeight = sequence.height;
        if (sequence.isAnimated and
            (driverSequence == nilptr or sequence.frames.count > $assert_nonnil(driverSequence).frames.count))
            driverSequence = sequence;
    }

    if (driverSequence == nilptr)
        return [OFData data];

    size_t frameCount = $assert_nonnil(driverSequence).frames.count;
    CFMutableDataRef nillable destinationData = nullptr;
    CGImageDestinationRef nillable destination = nullptr;
    CFDictionaryRef nillable loopProperties = nullptr;
    OFData *result = [OFData data];

    destinationData = CFDataCreateMutable(kCFAllocatorDefault, 0);
    if (destinationData == nullptr)
        return result;

    @try {
        destination = CGImageDestinationCreateWithData($assert_nonnil(destinationData), CFSTR("com.compuserve.gif"), frameCount, nullptr);
        if (destination == nullptr)
            return result;

        loopProperties = [self newGIFLoopProperties];
        if (loopProperties != nullptr)
            CGImageDestinationSetProperties($assert_nonnil(destination), loopProperties);

        for (size_t frameIndex = 0; frameIndex < frameCount; frameIndex++) {
            CGImageRef nillable sheetImage = [self newContactSheetImageWithSequences: sequences
                                                                            cellWidth: cellWidth
                                                                           cellHeight: cellHeight
                                                                              cellGap: cellGap
                                                                           frameIndex: frameIndex];
            ITerm2DecodedImage *driverFrame = $assert_nonnil(driverSequence).frames[frameIndex];
            CFDictionaryRef nillable frameProperties = [self newGIFFramePropertiesWithDelay: driverFrame.duration];

            if (sheetImage != nullptr)
                CGImageDestinationAddImage($assert_nonnil(destination), $assert_nonnil(sheetImage), frameProperties);

            if (frameProperties != nullptr)
                CFRelease(frameProperties);
            if (sheetImage != nullptr)
                CGImageRelease(sheetImage);
        }

        if (not CGImageDestinationFinalize($assert_nonnil(destination)))
            return result;

        return [OFData dataWithItems: CFDataGetBytePtr(destinationData)
                               count: (size_t)CFDataGetLength(destinationData)];
    } @finally {
        if (loopProperties != nullptr)
            CFRelease(loopProperties);
        if (destination != nullptr)
            CFRelease(destination);
        CFRelease(destinationData);
    }
}
#endif

+ (OFData *)contactSheetDataWithImages: (OFArray<ITerm2InlineImage *> *)images
                              cellGap: (size_t)cellGap
                          jpegQuality: (double)jpegQuality
{
#if defined(OF_MACOS)
    auto sequences = [OFMutableArray<ITerm2DecodedImageSequence *> arrayWithCapacity: images.count];
    size_t cellWidth = 0;
    size_t cellHeight = 0;
    bool hasAnimatedSequence = false;

    for (ITerm2InlineImage *image in images) {
        ITerm2DecodedImageSequence *nillable sequence = [self decodedImageSequenceFromData: image.data];

        if (sequence == nilptr)
            continue;

        [sequences addObject: $assert_nonnil(sequence)];
        if (sequence.width > cellWidth)
            cellWidth = sequence.width;
        if (sequence.height > cellHeight)
            cellHeight = sequence.height;
        if (sequence.isAnimated)
            hasAnimatedSequence = true;
    }

    if (sequences.count == 0 or cellWidth == 0 or cellHeight == 0)
        return [OFData data];

    if (hasAnimatedSequence)
        return [self animatedGIFContactSheetDataWithSequences: sequences
                                                      cellGap: cellGap];

    CGImageRef nillable sheetImage = [self newContactSheetImageWithSequences: sequences
                                                                    cellWidth: cellWidth
                                                                   cellHeight: cellHeight
                                                                      cellGap: cellGap
                                                                   frameIndex: 0];
    if (sheetImage == nullptr)
        return [OFData data];

    @try {
        return [self JPEGDataWithImage: $assert_nonnil(sheetImage)
                           jpegQuality: jpegQuality];
    } @finally {
        CGImageRelease(sheetImage);
    }
#else
    (void)cellGap;
    (void)jpegQuality;
    if (images.count == 0)
        return [OFData data];

    return images[0].data;
#endif
}

+ (size_t)terminalColumnCount
{
#if defined(TIOCGWINSZ)
    struct winsize windowSize = {0};

    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &windowSize) == 0 and windowSize.ws_col > 0)
        return windowSize.ws_col;
#endif

    OFDictionary<OFString *, OFString *> *nillable environment = OFApplication.environment;
    OFString *nillable columns = environment == nilptr ? nilptr : [environment objectForKey: @"COLUMNS"];

    @try {
        if (columns != nilptr and columns.length > 0) {
            unsigned long long value = [$assert_nonnil(columns) unsignedLongLongValue];

            if (value > 0)
                return (size_t)value;
        }
    } @catch (OFException *) {
    }

    return 80;
}

+ (double)terminalCellWidthToHeightRatio
{
#if defined(TIOCGWINSZ)
    struct winsize windowSize = {0};

    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &windowSize) == 0 and
        windowSize.ws_col > 0 and windowSize.ws_row > 0 and
        windowSize.ws_xpixel > 0 and windowSize.ws_ypixel > 0) {
        double cellWidth = (double)windowSize.ws_xpixel / (double)windowSize.ws_col;
        double cellHeight = (double)windowSize.ws_ypixel / (double)windowSize.ws_row;

        if (cellWidth > 0 and cellHeight > 0)
            return cellWidth / cellHeight;
    }
#endif

    return 0.5;
}

+ (size_t)kittyColumnCountForDisplayWidth: (OFString *)displayWidth
{
    double terminalColumns = (double)[self terminalColumnCount];
    double requestedColumns = terminalColumns;

    @try {
        if ([displayWidth hasSuffix: @"%"]) {
            OFString *percentage = [displayWidth substringWithRange: OFMakeRange(0, displayWidth.length - 1)];
            requestedColumns = terminalColumns * (percentage.doubleValue / 100.0);
        } else {
            requestedColumns = displayWidth.doubleValue;
        }
    } @catch (OFException *) {
        requestedColumns = terminalColumns;
    }

    if (requestedColumns < 1)
        requestedColumns = 1;
    if (requestedColumns > terminalColumns)
        requestedColumns = terminalColumns;

    return (size_t)(requestedColumns + 0.5);
}

+ (size_t)kittyRowCountForImageWidth: (size_t)imageWidth
                               height: (size_t)imageHeight
                              columns: (size_t)columns
{
    if (imageWidth == 0 or imageHeight == 0 or columns == 0)
        return 1;

    double rows = ceil((double)columns *
                       ((double)imageHeight / (double)imageWidth) *
                       [self terminalCellWidthToHeightRatio]);

    if (rows < 1)
        return 1;

    return (size_t)rows;
}

+ (OFString *)kittyBaseControlDataForColumns: (size_t)columns
                                        rows: (size_t)rows
                                     imageID: (unsigned int)imageID
{
    return [OFString stringWithFormat: @"a=T,f=100,I=%u,c=%zu,r=%zu,q=2",
                                      imageID,
                                      columns,
                                      rows];
}

+ (void)writeKittyGraphicsData: (OFData *)data
                   controlData: (OFString *)controlData
          continuedControlData: (OFString *)continuedControlData
{
    OFString *encoded = data.stringByBase64Encoding;
    size_t const chunkSize = 4096;
    bool isFirstChunk = true;

    if (encoded.length == 0)
        return;

    for (size_t offset = 0; offset < encoded.length; offset += chunkSize) {
        size_t length = encoded.length - offset;

        if (length > chunkSize)
            length = chunkSize;

        bool hasMore = (offset + length) < encoded.length;
        OFString *chunk = [encoded substringWithRange: OFMakeRange(offset, length)];
        OFString *chunkControlData = isFirstChunk ? controlData : continuedControlData;

        [OFStdOut writeFormat: @"\033_G%@,m=%u;%@\033\\",
                              chunkControlData,
                              hasMore ? 1 : 0,
                              chunk];
        isFirstChunk = false;
    }
}

+ (void)writeKittyControlData: (OFString *)controlData
{
    [OFStdOut writeFormat: @"\033_G%@;\033\\", controlData];
}

+ (unsigned int)kittyFrameDelayMilliseconds: (double)duration
{
    unsigned int milliseconds = (unsigned int)(duration * 1000.0 + 0.5);

    if (milliseconds == 0)
        milliseconds = 1;

    return milliseconds;
}

+ (void)writeKittyImageData: (OFData *)data
               displayWidth: (OFString *)displayWidth
                    imageID: (unsigned int)imageID
{
#if defined(OF_MACOS)
    ITerm2DecodedImageSequence *nillable sequence = [self decodedImageSequenceFromData: data];

    if (sequence == nilptr)
        return;

    size_t columns = [self kittyColumnCountForDisplayWidth: displayWidth];
    size_t rows = [self kittyRowCountForImageWidth: $assert_nonnil(sequence).width
                                            height: $assert_nonnil(sequence).height
                                           columns: columns];
    OFString *baseControlData = [self kittyBaseControlDataForColumns: columns
                                                                rows: rows
                                                             imageID: imageID];
    ITerm2DecodedImage *rootFrame = $assert_nonnil(sequence).frames[0];
    OFData *rootPNGData = [self PNGDataWithImage: rootFrame.image];

    if (rootPNGData.count == 0)
        return;

    [self writeKittyGraphicsData: rootPNGData
                     controlData: baseControlData
            continuedControlData: @"q=2"];

    if (not $assert_nonnil(sequence).isAnimated or $assert_nonnil(sequence).frames.count <= 1)
        return;

    [self writeKittyControlData: [OFString stringWithFormat: @"a=a,I=%u,r=1,z=%u,q=2",
                                                            imageID,
                                                            [self kittyFrameDelayMilliseconds: rootFrame.duration]]];

    for (size_t frameIndex = 1; frameIndex < $assert_nonnil(sequence).frames.count; frameIndex++) {
        ITerm2DecodedImage *frame = $assert_nonnil(sequence).frames[frameIndex];
        OFData *framePNGData = [self PNGDataWithImage: frame.image];

        if (framePNGData.count == 0)
            continue;

        [self writeKittyGraphicsData: framePNGData
                         controlData: [OFString stringWithFormat: @"a=f,f=100,I=%u,z=%u,q=2",
                                                                  imageID,
                                                                  [self kittyFrameDelayMilliseconds: frame.duration]]
                continuedControlData: [OFString stringWithFormat: @"a=f,I=%u,q=2", imageID]];
    }

    [self writeKittyControlData: [OFString stringWithFormat: @"a=a,I=%u,s=3,v=1,q=2", imageID]];
#else
    (void)displayWidth;
    [self writeKittyGraphicsData: data
                     controlData: [OFString stringWithFormat: @"a=T,f=100,I=%u,q=2", imageID]
            continuedControlData: @"q=2"];
#endif
}

+ (OFData *)imageDataByDownscalingImageData: (OFData *)data
                               maxPixelEdge: (size_t)maxPixelEdge
                                jpegQuality: (double)jpegQuality
{
#if defined(OF_MACOS)
    if (data.items == nullptr or data.count == 0)
        return data;

    CFDataRef nillable sourceData = [self newCFDataFromData: data];
    CGImageSourceRef nillable source = nullptr;
    CGImageRef nillable thumbnail = nullptr;
    OFData *result = data;

    if (sourceData == nullptr)
        return data;

    @try {
        source = CGImageSourceCreateWithData($assert_nonnil(sourceData), nullptr);
        if (source == nullptr)
            return data;

        size_t frameCount = CGImageSourceGetCount($assert_nonnil(source));
        if ([self imageSourceIsGIF: $assert_nonnil(source)]) {
            if (maxPixelEdge == 0)
                return data;

            OFData *GIFData = [self GIFDataByDownscalingImageSource: $assert_nonnil(source)
                                                         frameCount: frameCount
                                                       maxPixelEdge: maxPixelEdge];
            return GIFData.count > 0 ? GIFData : data;
        }

        if (maxPixelEdge == 0)
            return data;

        thumbnail = [self newImageFromSource: $assert_nonnil(source)
                                  frameIndex: 0
                                maxPixelEdge: maxPixelEdge];
        if (thumbnail == nullptr)
            return data;

        result = [self JPEGDataWithImage: $assert_nonnil(thumbnail)
                             jpegQuality: jpegQuality];
        if (result.count == 0)
            result = data;
    } @finally {
        if (thumbnail != nullptr)
            CGImageRelease(thumbnail);
        if (source != nullptr)
            CFRelease(source);
        CFRelease(sourceData);
    }

    return result;
#else
    (void)maxPixelEdge;
    (void)jpegQuality;
    return data;
#endif
}

@end

@namespace_implementation(ITerm2ImageGallery)

+ (Task<ITerm2InlineImage *> *)taskToLoadImageAtIRI: (OFIRI *)iri
                                       usingClient: (OFHTTPClient *)client
                                        refererIRI: (OFIRI *)refererIRI
                                       maxPixelEdge: (size_t)maxPixelEdge
                                        jpegQuality: (double)jpegQuality
                                        onScheduler: (AsyncScheduler *)scheduler
{
    auto request = [[OFHTTPRequest alloc] initWithIRI: iri];
    request.headers = @{
        @"Accept": @"image/*,*/*;q=0.8",
        @"Referer": refererIRI.string,
        @"User-Agent": @"BooruAggr/1.0"
    };

    return [[client taskToPerformHTTPRequest: request onScheduler: scheduler] mapOnScheduler: scheduler transform: ^ITerm2InlineImage *(OFHTTPResponse *response) {
        auto originalData = [response readDataUntilEndOfStream];
        auto imageData = [ITerm2ImageGallerySupport imageDataByDownscalingImageData: originalData
                                                                       maxPixelEdge: maxPixelEdge
                                                                        jpegQuality: jpegQuality];

        return [[ITerm2InlineImage alloc] initWithFilename: iri.lastPathComponent
                                                      data: imageData];
    }];
}

+ (OFString *)displayWidthForColumns: (size_t)columns
                                scale: (double)scale
{
    return [self displayWidthForImageCount: columns
                                     scale: scale];
}

+ (OFString *)displayWidthForImageCount: (size_t)imageCount
                                  scale: (double)scale
{
    double rowPercent = scale * (double)imageCount * 100.0;
    unsigned int rowWidthPercent;

    if (imageCount == 0)
        imageCount = 1;
    if (rowPercent < 1.0)
        rowPercent = 1.0;
    if (rowPercent > 100.0)
        rowPercent = 100.0;

    rowWidthPercent = (unsigned int)(rowPercent + 0.5);
    if (rowWidthPercent == 0)
        rowWidthPercent = 1;

    return [OFString stringWithFormat: @"%u%%", rowWidthPercent];
}

+ (void)writeImages: (OFArray<ITerm2InlineImage *> *)images
            columns: (size_t)columns
       displayWidth: (OFString *)displayWidth
        jpegQuality: (double)jpegQuality
{
    [self writeImages: images
              columns: columns
         displayWidth: displayWidth
          jpegQuality: jpegQuality
      graphicsProtocol: TerminalGraphicsProtocolITerm2];
}

+ (void)writeImages: (OFArray<ITerm2InlineImage *> *)images
            columns: (size_t)columns
              scale: (double)scale
        jpegQuality: (double)jpegQuality
    graphicsProtocol: (TerminalGraphicsProtocol)graphicsProtocol
{
    if (columns == 0)
        columns = 1;

    for (size_t rowStart = 0; rowStart < images.count; rowStart += columns) {
        size_t rowEnd = rowStart + columns;
        auto rowImages = [OFMutableArray<ITerm2InlineImage *> array];
        OFString *rowDisplayWidth;

        if (rowEnd > images.count)
            rowEnd = images.count;

        for (size_t index = rowStart; index < rowEnd; index++)
            [rowImages addObject: images[index]];

        rowDisplayWidth = [self displayWidthForImageCount: rowImages.count
                                                    scale: scale];

        auto rowData = [ITerm2ImageGallerySupport contactSheetDataWithImages: rowImages
                                                                     cellGap: 12
                                                                 jpegQuality: jpegQuality];
        if (rowData.count == 0)
            continue;

        if (graphicsProtocol == TerminalGraphicsProtocolKitty) {
            [ITerm2ImageGallerySupport writeKittyImageData: rowData
                                              displayWidth: rowDisplayWidth
                                                   imageID: (unsigned int)(rowStart / columns + 1)];
            [OFStdOut writeLine: @""];
            continue;
        }

        OFString *rowExtension = @"jpg";
#if defined(OF_MACOS)
        if ([ITerm2ImageGallerySupport imageDataIsGIF: rowData])
            rowExtension = @"gif";
#endif

        auto rowImage = [[ITerm2InlineImage alloc] initWithFilename: [OFString stringWithFormat: @"gallery-row-%zu.%@", rowStart / columns + 1, rowExtension]
                                                               data: rowData];
        [rowImage writeWithDisplayWidth: rowDisplayWidth];
        [OFStdOut writeLine: @""];
    }
}

+ (void)writeImages: (OFArray<ITerm2InlineImage *> *)images
            columns: (size_t)columns
       displayWidth: (OFString *)displayWidth
        jpegQuality: (double)jpegQuality
    graphicsProtocol: (TerminalGraphicsProtocol)graphicsProtocol
{
    if (columns == 0)
        columns = 1;

    for (size_t rowStart = 0; rowStart < images.count; rowStart += columns) {
        size_t rowEnd = rowStart + columns;
        auto rowImages = [OFMutableArray<ITerm2InlineImage *> array];

        if (rowEnd > images.count)
            rowEnd = images.count;

        for (size_t index = rowStart; index < rowEnd; index++)
            [rowImages addObject: images[index]];

        auto rowData = [ITerm2ImageGallerySupport contactSheetDataWithImages: rowImages
                                                                     cellGap: 12
                                                                 jpegQuality: jpegQuality];
        if (rowData.count == 0)
            continue;

        if (graphicsProtocol == TerminalGraphicsProtocolKitty) {
            [ITerm2ImageGallerySupport writeKittyImageData: rowData
                                              displayWidth: displayWidth
                                                   imageID: (unsigned int)(rowStart / columns + 1)];
            [OFStdOut writeLine: @""];
            continue;
        }

        OFString *rowExtension = @"jpg";
#if defined(OF_MACOS)
        if ([ITerm2ImageGallerySupport imageDataIsGIF: rowData])
            rowExtension = @"gif";
#endif

        auto rowImage = [[ITerm2InlineImage alloc] initWithFilename: [OFString stringWithFormat: @"gallery-row-%zu.%@", rowStart / columns + 1, rowExtension]
                                                               data: rowData];
        [rowImage writeWithDisplayWidth: displayWidth];
        [OFStdOut writeLine: @""];
    }
}

@end

#pragma clang assume_nonnull end
