#if !defined(__APPLE__)
#   error This file is only supported on Apple platforms.
#endif

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <ImageIO/ImageIO.h>
#import <dispatch/dispatch.h>

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#import <AsyncRT/Application/UI/Surface/Immediate/Platform/CoreGraphics/RenderSupport.h>

#pragma clang assume_nonnull begin

typedef enum AsyncUICoreGraphicsBorderSide {
    AsyncUICoreGraphicsBorderSideTop,
    AsyncUICoreGraphicsBorderSideRight,
    AsyncUICoreGraphicsBorderSideBottom,
    AsyncUICoreGraphicsBorderSideLeft
} AsyncUICoreGraphicsBorderSide;

[[subclassing_restricted, direct_members]]
@interface AsyncUICoreGraphicsTextLayout : OFObject

@property(readonly, nonatomic) CTLineRef line;
@property(readonly, nonatomic) double width;
@property(readonly, nonatomic) CGFloat ascent;
@property(readonly, nonatomic) CGFloat descent;
@property(readonly, nonatomic) CGFloat leading;

- (instancetype)initWithString: (CFStringRef)string
                        fontID: (uint16_t)fontID
                      fontSize: (uint16_t)fontSize
                 letterSpacing: (uint16_t)letterSpacing
                  fontFamilies: (CFStringRef const *nillable)fontFamilies [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[direct_members]]
@interface AsyncUICoreGraphicsRenderSupport ()

+ (CGFloat)channelForValue: (uint8_t)value;
+ (double)clampedRadius: (double)radius forBoundingBox: (Clay_BoundingBox)boundingBox;
+ (CFStringRef)fontFamilyInFamilies: (CFStringRef const *nillable)fontFamilies fontID: (uint16_t)fontID;
+ (CFStringRef nillable)copyString: (Clay_StringSlice)text;
+ (CTFontRef)createFontInFamilies: (CFStringRef const *nillable)fontFamilies
                            fontID: (uint16_t)fontID
                              size: (CGFloat)size;
+ (NSCache *)textLayoutCache;
+ (NSString *)textLayoutCacheKeyForString: (CFStringRef)string
                                   fontID: (uint16_t)fontID
                                 fontSize: (uint16_t)fontSize
                            letterSpacing: (uint16_t)letterSpacing
                                lineHeight: (uint16_t)lineHeight
                             fontFamilies: (CFStringRef const *nillable)fontFamilies;
+ (AsyncUICoreGraphicsTextLayout *nillable)textLayoutForString: (CFStringRef)string
                                                    fontID: (uint16_t)fontID
                                                  fontSize: (uint16_t)fontSize
                                             letterSpacing: (uint16_t)letterSpacing
                                                 lineHeight: (uint16_t)lineHeight
                                              fontFamilies: (CFStringRef const *nillable)fontFamilies;
+ (CGMutablePathRef)createRoundedRectPathForBoundingBox: (Clay_BoundingBox)boundingBox
                                                 radius: (Clay_CornerRadius)radius CF_RETURNS_RETAINED;
+ (void)applyFillColor: (Clay_Color)color inContext: (CGContextRef)context;
+ (void)applyStrokeColor: (Clay_Color)color inContext: (CGContextRef)context;
+ (void)renderRectangleWithContext: (CGContextRef)context
                            config: (Clay_RectangleRenderData *)config
                       boundingBox: (Clay_BoundingBox)boundingBox;
+ (void)renderBorderSideWithContext: (CGContextRef)context
                            boundingBox: (Clay_BoundingBox)boundingBox
                                 config: (Clay_BorderRenderData *)config
                                topLeft: (double)topLeft
                               topRight: (double)topRight
                            bottomRight: (double)bottomRight
                             bottomLeft: (double)bottomLeft
                                   side: (AsyncUICoreGraphicsBorderSide)side;
+ (void)renderBorderWithContext: (CGContextRef)context
                         config: (Clay_BorderRenderData *)config
                    boundingBox: (Clay_BoundingBox)boundingBox;
+ (void)renderTextWithContext: (CGContextRef)context
                       config: (Clay_TextRenderData *)config
                  boundingBox: (Clay_BoundingBox)boundingBox
                 viewportSize: (AsyncUISize)viewportSize
                 fontFamilies: (CFStringRef const *nillable)fontFamilies;
+ (void)renderImageWithContext: (CGContextRef)context
                        config: (Clay_ImageRenderData *)config
                   boundingBox: (Clay_BoundingBox)boundingBox;
+ (void)renderCommandWithContext: (CGContextRef)context
                            command: (Clay_RenderCommand *)command
                       viewportSize: (AsyncUISize)viewportSize
                       fontFamilies: (CFStringRef const *nillable)fontFamilies;

@end

[[direct_members]]
@implementation AsyncUICoreGraphicsTextLayout {
    CTLineRef _line;
    double _width;
    CGFloat _ascent;
    CGFloat _descent;
    CGFloat _leading;
}

- (instancetype)initWithString: (CFStringRef)string
                        fontID: (uint16_t)fontID
                      fontSize: (uint16_t)fontSize
                 letterSpacing: (uint16_t)letterSpacing
                  fontFamilies: (CFStringRef const *nillable)fontFamilies
{
    self = [super init];
    CTFontRef font = [AsyncUICoreGraphicsRenderSupport createFontInFamilies: fontFamilies
                                                                fontID: fontID
                                                                  size: fontSize];
    CFMutableAttributedStringRef attributedString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
    CFAttributedStringReplaceString(attributedString, CFRangeMake(0, 0), string);
    CFRange range = CFRangeMake(0, CFStringGetLength(string));
    CFAttributedStringSetAttribute(attributedString, range, kCTFontAttributeName, font);

    if (letterSpacing != 0) {
        CFNumberRef kern = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt16Type, &letterSpacing);

        CFAttributedStringSetAttribute(attributedString, range, kCTKernAttributeName, kern);
        CFRelease(kern);
    }

    _line = CTLineCreateWithAttributedString(attributedString);
    _width = CTLineGetTypographicBounds($assert_nonnil(_line), &_ascent, &_descent, &_leading);

    CFRelease(attributedString);
    CFRelease(font);
    return self;
}

- (void)dealloc
{
    if (_line != nullptr)
        CFRelease(_line);
}

@end

@namespace_implementation(AsyncUICoreGraphicsRenderSupport)

+ (CGFloat)channelForValue: (uint8_t)value
{
    return ((CGFloat)value) / 255.0f;
}

+ (double)clampedRadius: (double)radius forBoundingBox: (Clay_BoundingBox)boundingBox
{
    double maxRadius = fmax(0.0, fmin(boundingBox.width, boundingBox.height) / 2.0);

    if (radius < 0.0)
        return 0.0;
    if (radius > maxRadius)
        return maxRadius;
    return radius;
}

+ (CFStringRef)fontFamilyInFamilies: (CFStringRef const *nillable)fontFamilies fontID: (uint16_t)fontID
{
    if (fontFamilies == nullptr or fontFamilies[fontID] == nullptr)
        return CFSTR("Helvetica");

    return fontFamilies[fontID];
}

+ (CFStringRef nillable)copyString: (Clay_StringSlice)text
{
    return CFStringCreateWithBytes(kCFAllocatorDefault,
                                   (const UInt8 *)text.chars,
                                   (CFIndex)text.length,
                                   kCFStringEncodingUTF8,
                                   false);
}

+ (CTFontRef)createFontInFamilies: (CFStringRef const *nillable)fontFamilies
                            fontID: (uint16_t)fontID
                              size: (CGFloat)size
{
    return CTFontCreateWithName([self fontFamilyInFamilies: fontFamilies fontID: fontID], size, nullptr);
}

+ (NSCache *)textLayoutCache
{
    static NSCache *cache = nilptr;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.countLimit = 4096;
    });

    return $assert_nonnil(cache);
}

+ (NSString *)textLayoutCacheKeyForString: (CFStringRef)string
                                   fontID: (uint16_t)fontID
                                 fontSize: (uint16_t)fontSize
                            letterSpacing: (uint16_t)letterSpacing
                                lineHeight: (uint16_t)lineHeight
                             fontFamilies: (CFStringRef const *nillable)fontFamilies
{
    NSString *format = (__bridge NSString *)CFSTR("%@|%u|%u|%u|%u|%@");
    NSString *family = (__bridge NSString *)[self fontFamilyInFamilies: fontFamilies fontID: fontID];
    NSString *text = (__bridge NSString *)string;

    return [NSString stringWithFormat: format,
                                      family,
                                      (unsigned int)fontID,
                                      (unsigned int)fontSize,
                                      (unsigned int)letterSpacing,
                                      (unsigned int)lineHeight,
                                      text];
}

+ (AsyncUICoreGraphicsTextLayout *nillable)textLayoutForString: (CFStringRef)string
                                                    fontID: (uint16_t)fontID
                                                  fontSize: (uint16_t)fontSize
                                             letterSpacing: (uint16_t)letterSpacing
                                                 lineHeight: (uint16_t)lineHeight
                                              fontFamilies: (CFStringRef const *nillable)fontFamilies
{
    NSCache *cache;
    NSString *key;
    AsyncUICoreGraphicsTextLayout *nillable layout;

    cache = self.textLayoutCache;
    key = [self textLayoutCacheKeyForString: string
                                     fontID: fontID
                                   fontSize: fontSize
                              letterSpacing: letterSpacing
                                  lineHeight: lineHeight
                               fontFamilies: fontFamilies];
    layout = [cache objectForKey: key];
    if (layout != nilptr)
        return layout;

    layout = [[AsyncUICoreGraphicsTextLayout alloc] initWithString: string
                                                        fontID: fontID
                                                      fontSize: fontSize
                                                 letterSpacing: letterSpacing
                                                  fontFamilies: fontFamilies];
    [cache setObject: $assert_nonnil(layout) forKey: key];
    return layout;
}

+ (CGMutablePathRef)createRoundedRectPathForBoundingBox: (Clay_BoundingBox)boundingBox
                                                 radius: (Clay_CornerRadius)radius
{
    double topLeft = [self clampedRadius: radius.topLeft forBoundingBox: boundingBox];
    double topRight = [self clampedRadius: radius.topRight forBoundingBox: boundingBox];
    double bottomRight = [self clampedRadius: radius.bottomRight forBoundingBox: boundingBox];
    double bottomLeft = [self clampedRadius: radius.bottomLeft forBoundingBox: boundingBox];
    CGMutablePathRef path = CGPathCreateMutable();

    CGPathMoveToPoint(path, nullptr, boundingBox.x + topLeft, boundingBox.y);
    CGPathAddLineToPoint(path, nullptr, boundingBox.x + boundingBox.width - topRight, boundingBox.y);
    if (topRight > 0.0)
        CGPathAddArc(path, nullptr, boundingBox.x + boundingBox.width - topRight, boundingBox.y + topRight, topRight, -M_PI_2, 0.0, false);
    else
        CGPathAddLineToPoint(path, nullptr, boundingBox.x + boundingBox.width, boundingBox.y);

    CGPathAddLineToPoint(path, nullptr, boundingBox.x + boundingBox.width, boundingBox.y + boundingBox.height - bottomRight);
    if (bottomRight > 0.0)
        CGPathAddArc(path, nullptr, boundingBox.x + boundingBox.width - bottomRight, boundingBox.y + boundingBox.height - bottomRight, bottomRight, 0.0, M_PI_2, false);
    else
        CGPathAddLineToPoint(path, nullptr, boundingBox.x + boundingBox.width, boundingBox.y + boundingBox.height);

    CGPathAddLineToPoint(path, nullptr, boundingBox.x + bottomLeft, boundingBox.y + boundingBox.height);
    if (bottomLeft > 0.0)
        CGPathAddArc(path, nullptr, boundingBox.x + bottomLeft, boundingBox.y + boundingBox.height - bottomLeft, bottomLeft, M_PI_2, M_PI, false);
    else
        CGPathAddLineToPoint(path, nullptr, boundingBox.x, boundingBox.y + boundingBox.height);

    CGPathAddLineToPoint(path, nullptr, boundingBox.x, boundingBox.y + topLeft);
    if (topLeft > 0.0)
        CGPathAddArc(path, nullptr, boundingBox.x + topLeft, boundingBox.y + topLeft, topLeft, M_PI, 3.0 * M_PI_2, false);
    else
        CGPathAddLineToPoint(path, nullptr, boundingBox.x, boundingBox.y);

    CGPathCloseSubpath(path);
    return path;
}

+ (void)applyFillColor: (Clay_Color)color inContext: (CGContextRef)context
{
    CGContextSetRGBFillColor(context,
                             [self channelForValue: color.r],
                             [self channelForValue: color.g],
                             [self channelForValue: color.b],
                             [self channelForValue: color.a]);
}

+ (void)applyStrokeColor: (Clay_Color)color inContext: (CGContextRef)context
{
    CGContextSetRGBStrokeColor(context,
                               [self channelForValue: color.r],
                               [self channelForValue: color.g],
                               [self channelForValue: color.b],
                               [self channelForValue: color.a]);
}

+ (void)renderRectangleWithContext: (CGContextRef)context
                            config: (Clay_RectangleRenderData *)config
                       boundingBox: (Clay_BoundingBox)boundingBox
{
    CGMutablePathRef path = [self createRoundedRectPathForBoundingBox: boundingBox radius: config->cornerRadius];

    [self applyFillColor: config->backgroundColor inContext: context];
    CGContextAddPath(context, path);
    CGContextFillPath(context);
    CGPathRelease(path);
}

+ (void)renderBorderSideWithContext: (CGContextRef)context
                        boundingBox: (Clay_BoundingBox)boundingBox
                             config: (Clay_BorderRenderData *)config
                            topLeft: (double)topLeft
                           topRight: (double)topRight
                        bottomRight: (double)bottomRight
                         bottomLeft: (double)bottomLeft
                               side: (AsyncUICoreGraphicsBorderSide)side
{
    CGContextBeginPath(context);

    switch (side) {
        case AsyncUICoreGraphicsBorderSideTop:
            CGContextMoveToPoint(context, boundingBox.x, boundingBox.y + topLeft);
            if (topLeft > 0.0)
                CGContextAddArc(context, boundingBox.x + topLeft, boundingBox.y + topLeft, topLeft, M_PI, 3.0 * M_PI_2, false);
            else
                CGContextAddLineToPoint(context, boundingBox.x, boundingBox.y);
            CGContextAddLineToPoint(context, boundingBox.x + boundingBox.width - topRight, boundingBox.y);
            if (topRight > 0.0)
                CGContextAddArc(context, boundingBox.x + boundingBox.width - topRight, boundingBox.y + topRight, topRight, 3.0 * M_PI_2, 0.0, false);
            else
                CGContextAddLineToPoint(context, boundingBox.x + boundingBox.width, boundingBox.y);
            break;
        case AsyncUICoreGraphicsBorderSideRight:
            CGContextMoveToPoint(context, boundingBox.x + boundingBox.width - topRight, boundingBox.y);
            if (topRight > 0.0)
                CGContextAddArc(context, boundingBox.x + boundingBox.width - topRight, boundingBox.y + topRight, topRight, 3.0 * M_PI_2, 0.0, false);
            CGContextAddLineToPoint(context, boundingBox.x + boundingBox.width, boundingBox.y + boundingBox.height - bottomRight);
            if (bottomRight > 0.0)
                CGContextAddArc(context, boundingBox.x + boundingBox.width - bottomRight, boundingBox.y + boundingBox.height - bottomRight, bottomRight, 0.0, M_PI_2, false);
            else
                CGContextAddLineToPoint(context, boundingBox.x + boundingBox.width, boundingBox.y + boundingBox.height);
            break;
        case AsyncUICoreGraphicsBorderSideBottom:
            CGContextMoveToPoint(context, boundingBox.x + boundingBox.width, boundingBox.y + boundingBox.height - bottomRight);
            if (bottomRight > 0.0)
                CGContextAddArc(context, boundingBox.x + boundingBox.width - bottomRight, boundingBox.y + boundingBox.height - bottomRight, bottomRight, 0.0, M_PI_2, false);
            CGContextAddLineToPoint(context, boundingBox.x + bottomLeft, boundingBox.y + boundingBox.height);
            if (bottomLeft > 0.0)
                CGContextAddArc(context, boundingBox.x + bottomLeft, boundingBox.y + boundingBox.height - bottomLeft, bottomLeft, M_PI_2, M_PI, false);
            else
                CGContextAddLineToPoint(context, boundingBox.x, boundingBox.y + boundingBox.height);
            break;
        case AsyncUICoreGraphicsBorderSideLeft:
            CGContextMoveToPoint(context, boundingBox.x + bottomLeft, boundingBox.y + boundingBox.height);
            if (bottomLeft > 0.0)
                CGContextAddArc(context, boundingBox.x + bottomLeft, boundingBox.y + boundingBox.height - bottomLeft, bottomLeft, M_PI_2, M_PI, false);
            CGContextAddLineToPoint(context, boundingBox.x, boundingBox.y + topLeft);
            if (topLeft > 0.0)
                CGContextAddArc(context, boundingBox.x + topLeft, boundingBox.y + topLeft, topLeft, M_PI, 3.0 * M_PI_2, false);
            else
                CGContextAddLineToPoint(context, boundingBox.x, boundingBox.y);
            break;
    }

    CGContextStrokePath(context);
}

+ (void)renderBorderWithContext: (CGContextRef)context
                         config: (Clay_BorderRenderData *)config
                    boundingBox: (Clay_BoundingBox)boundingBox
{
    double topLeft = [self clampedRadius: config->cornerRadius.topLeft forBoundingBox: boundingBox] / 2.0;
    double topRight = [self clampedRadius: config->cornerRadius.topRight forBoundingBox: boundingBox] / 2.0;
    double bottomRight = [self clampedRadius: config->cornerRadius.bottomRight forBoundingBox: boundingBox] / 2.0;
    double bottomLeft = [self clampedRadius: config->cornerRadius.bottomLeft forBoundingBox: boundingBox] / 2.0;

    [self applyStrokeColor: config->color inContext: context];
    CGContextSetLineJoin(context, kCGLineJoinRound);

    if (config->width.top > 0.0) {
        CGContextSetLineWidth(context, config->width.top);
        [self renderBorderSideWithContext: context boundingBox: boundingBox config: config topLeft: topLeft topRight: topRight bottomRight: bottomRight bottomLeft: bottomLeft side: AsyncUICoreGraphicsBorderSideTop];
    }
    if (config->width.right > 0.0) {
        CGContextSetLineWidth(context, config->width.right);
        [self renderBorderSideWithContext: context boundingBox: boundingBox config: config topLeft: topLeft topRight: topRight bottomRight: bottomRight bottomLeft: bottomLeft side: AsyncUICoreGraphicsBorderSideRight];
    }
    if (config->width.bottom > 0.0) {
        CGContextSetLineWidth(context, config->width.bottom);
        [self renderBorderSideWithContext: context boundingBox: boundingBox config: config topLeft: topLeft topRight: topRight bottomRight: bottomRight bottomLeft: bottomLeft side: AsyncUICoreGraphicsBorderSideBottom];
    }
    if (config->width.left > 0.0) {
        CGContextSetLineWidth(context, config->width.left);
        [self renderBorderSideWithContext: context boundingBox: boundingBox config: config topLeft: topLeft topRight: topRight bottomRight: bottomRight bottomLeft: bottomLeft side: AsyncUICoreGraphicsBorderSideLeft];
    }
}

+ (void)renderTextWithContext: (CGContextRef)context
                       config: (Clay_TextRenderData *)config
                  boundingBox: (Clay_BoundingBox)boundingBox
                 viewportSize: (AsyncUISize)viewportSize
                 fontFamilies: (CFStringRef const *nillable)fontFamilies
{
    CFStringRef nillable string = [self copyString: config->stringContents];

    if (string == nullptr)
        return;

    AsyncUICoreGraphicsTextLayout *nillable layout = [self textLayoutForString: $assert_nonnil(string)
                                                                    fontID: config->fontId
                                                                  fontSize: config->fontSize
                                                             letterSpacing: config->letterSpacing
                                                                lineHeight: config->lineHeight
                                                              fontFamilies: fontFamilies];
    if (layout == nilptr) {
        CFRelease(string);
        return;
    }

    const CGFloat lineHeight = (config->lineHeight > 0 ? config->lineHeight : (layout.ascent + layout.descent + layout.leading));
    const double baselineY = boundingBox.y + ((lineHeight - (layout.ascent + layout.descent)) / 2.0) + layout.ascent;

    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0.0, viewportSize.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    [self applyFillColor: config->textColor inContext: context];
    CGContextSetTextPosition(context,
                             boundingBox.x,
                             viewportSize.height - baselineY);
    CTLineDraw($assert_nonnil(layout.line), context);
    CGContextRestoreGState(context);

    CFRelease(string);
}

+ (void)renderImageWithContext: (CGContextRef)context
                        config: (Clay_ImageRenderData *)config
                   boundingBox: (Clay_BoundingBox)boundingBox
{
    CGDataProviderRef nillable provider = nullptr;
    CGImageSourceRef nillable imageSource = nullptr;
    CGImageRef nillable image = nullptr;

    if (boundingBox.width <= 0.0 or boundingBox.height <= 0.0 or config->imageData == nullptr)
        return;

    provider = CGDataProviderCreateWithFilename((const char *)config->imageData);
    if (provider == nullptr)
        return;

    imageSource = CGImageSourceCreateWithDataProvider($assert_nonnil(provider), nullptr);
    if (imageSource == nullptr) {
        CGDataProviderRelease(provider);
        return;
    }

    image = CGImageSourceCreateImageAtIndex($assert_nonnil(imageSource), 0, nullptr);
    if (image == nullptr) {
        CFRelease(imageSource);
        CGDataProviderRelease(provider);
        return;
    }

    const double imageWidth = CGImageGetWidth(image);
    const double imageHeight = CGImageGetHeight(image);
    if (imageWidth <= 0.0 or imageHeight <= 0.0) {
        CGImageRelease(image);
        CFRelease(imageSource);
        CGDataProviderRelease(provider);
        return;
    }

    const double scale = fmin(boundingBox.width / imageWidth, boundingBox.height / imageHeight);
    const double scaledWidth = imageWidth * scale;
    const double scaledHeight = imageHeight * scale;
    const CGRect drawRect = CGRectMake(boundingBox.x + (boundingBox.width - scaledWidth) / 2.0,
                                       boundingBox.y + (boundingBox.height - scaledHeight) / 2.0,
                                       scaledWidth,
                                       scaledHeight);
    CGMutablePathRef clipPath = [self createRoundedRectPathForBoundingBox: boundingBox radius: config->cornerRadius];

    CGContextSaveGState(context);
    CGContextAddPath(context, clipPath);
    CGContextClip(context);

    if (config->backgroundColor.a > 0) {
        [self applyFillColor: config->backgroundColor inContext: context];
        CGContextFillRect(context, CGRectMake(boundingBox.x, boundingBox.y, boundingBox.width, boundingBox.height));
    }

    CGContextDrawImage(context, drawRect, image);
    CGContextRestoreGState(context);

    CGPathRelease(clipPath);
    CGImageRelease(image);
    CFRelease(imageSource);
    CGDataProviderRelease(provider);
}

+ (void)renderCommandWithContext: (CGContextRef)context
                         command: (Clay_RenderCommand *)command
                    viewportSize: (AsyncUISize)viewportSize
                    fontFamilies: (CFStringRef const *nillable)fontFamilies
{
    switch (command->commandType) {
        case CLAY_RENDER_COMMAND_TYPE_RECTANGLE:
            [self renderRectangleWithContext: context config: &command->renderData.rectangle boundingBox: command->boundingBox];
            break;
        case CLAY_RENDER_COMMAND_TYPE_TEXT:
            [self renderTextWithContext: context
                                 config: &command->renderData.text
                            boundingBox: command->boundingBox
                           viewportSize: viewportSize
                           fontFamilies: fontFamilies];
            break;
        case CLAY_RENDER_COMMAND_TYPE_BORDER:
            [self renderBorderWithContext: context config: &command->renderData.border boundingBox: command->boundingBox];
            break;
        case CLAY_RENDER_COMMAND_TYPE_SCISSOR_START: {
            Clay_BoundingBox boundingBox = command->boundingBox;

            CGContextSaveGState(context);
            CGContextClipToRect(context, CGRectMake(boundingBox.x, boundingBox.y, boundingBox.width, boundingBox.height));
            break;
        }
        case CLAY_RENDER_COMMAND_TYPE_SCISSOR_END:
            CGContextRestoreGState(context);
            break;
        case CLAY_RENDER_COMMAND_TYPE_IMAGE:
            [self renderImageWithContext: context config: &command->renderData.image boundingBox: command->boundingBox];
            break;
        case CLAY_RENDER_COMMAND_TYPE_CUSTOM:
            break;
        default:
            fprintf(stderr, "Unknown Clay command type %d\n", (int)command->commandType);
            break;
    }
}

+ (void)renderCommands: (Clay_RenderCommandArray)commands
              onContext: (CGContextRef)context
           viewportSize: (AsyncUISize)viewportSize
           fontFamilies: (CFStringRef const *nillable)fontFamilies
{
    for (int32_t index = 0; index < commands.length; index++)
        [self renderCommandWithContext: context
                               command: Clay_RenderCommandArray_Get(&commands, index)
                          viewportSize: viewportSize
                          fontFamilies: fontFamilies];
}

@end

Clay_Dimensions AsyncUICoreGraphicsMeasureText(Clay_StringSlice text,
                                           Clay_TextElementConfig *config,
                                           void *nillable userData)
{
    AsyncUICoreGraphicsTextMeasureContext *measureContext = userData;
    CFStringRef const *fontFamilies = (measureContext != nullptr ? measureContext->fontFamilies : nullptr);
    CFStringRef nillable string = [AsyncUICoreGraphicsRenderSupport copyString: text];
    AsyncUICoreGraphicsTextLayout *nillable layout;

    if (string == nullptr)
        return (Clay_Dimensions){ 0, 0 };

    layout = [AsyncUICoreGraphicsRenderSupport textLayoutForString: $assert_nonnil(string)
                                                        fontID: config->fontId
                                                      fontSize: config->fontSize
                                                 letterSpacing: config->letterSpacing
                                                     lineHeight: config->lineHeight
                                                  fontFamilies: fontFamilies];
    CFRelease(string);

    return (Clay_Dimensions){
        .width = (float)(layout != nilptr ? layout.width : 0.0),
        .height = (float)(config->lineHeight > 0
            ? config->lineHeight
            : (layout != nilptr ? (layout.ascent + layout.descent + layout.leading) : 0.0))
    };
}

#pragma clang assume_nonnull end
