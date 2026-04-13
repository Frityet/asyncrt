#if !defined(__APPLE__)
#   error This file is only supported on Apple platforms.
#endif

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <ImageIO/ImageIO.h>

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#import "UI/Backend/AUICoreGraphicsRenderSupport.h"

#pragma clang assume_nonnull begin

typedef enum AUICoreGraphicsBorderSide {
    AUICoreGraphicsBorderSideTop,
    AUICoreGraphicsBorderSideRight,
    AUICoreGraphicsBorderSideBottom,
    AUICoreGraphicsBorderSideLeft
} AUICoreGraphicsBorderSide;

@interface AUICoreGraphicsRenderSupport ()

+ (CGFloat)channelForValue: (uint8_t)value;
+ (double)clampedRadius: (double)radius forBoundingBox: (Clay_BoundingBox)boundingBox;
+ (CFStringRef)fontFamilyInFamilies: (CFStringRef const *nillable)fontFamilies fontID: (uint16_t)fontID;
+ (CFStringRef nillable)copyString: (Clay_StringSlice)text;
+ (CTFontRef)createFontInFamilies: (CFStringRef const *nillable)fontFamilies
                            fontID: (uint16_t)fontID
                              size: (CGFloat)size;
+ (CGMutablePathRef)createRoundedRectPathForBoundingBox: (Clay_BoundingBox)boundingBox
                                                 radius: (Clay_CornerRadius)radius CF_RETURNS_RETAINED;
+ (void)setFillColor: (Clay_Color)color inContext: (CGContextRef)context;
+ (void)setStrokeColor: (Clay_Color)color inContext: (CGContextRef)context;
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
                                   side: (AUICoreGraphicsBorderSide)side;
+ (void)renderBorderWithContext: (CGContextRef)context
                         config: (Clay_BorderRenderData *)config
                    boundingBox: (Clay_BoundingBox)boundingBox;
+ (void)renderTextWithContext: (CGContextRef)context
                       config: (Clay_TextRenderData *)config
                  boundingBox: (Clay_BoundingBox)boundingBox
                 viewportSize: (AUISize)viewportSize
                 fontFamilies: (CFStringRef const *nillable)fontFamilies;
+ (void)renderImageWithContext: (CGContextRef)context
                        config: (Clay_ImageRenderData *)config
                   boundingBox: (Clay_BoundingBox)boundingBox;
+ (void)renderCommandWithContext: (CGContextRef)context
                            command: (Clay_RenderCommand *)command
                       viewportSize: (AUISize)viewportSize
                       fontFamilies: (CFStringRef const *nillable)fontFamilies;

@end

@namespace_implementation(AUICoreGraphicsRenderSupport)

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

+ (void)setFillColor: (Clay_Color)color inContext: (CGContextRef)context
{
    CGContextSetRGBFillColor(context,
                             [self channelForValue: color.r],
                             [self channelForValue: color.g],
                             [self channelForValue: color.b],
                             [self channelForValue: color.a]);
}

+ (void)setStrokeColor: (Clay_Color)color inContext: (CGContextRef)context
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

    [self setFillColor: config->backgroundColor inContext: context];
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
                               side: (AUICoreGraphicsBorderSide)side
{
    CGContextBeginPath(context);

    switch (side) {
        case AUICoreGraphicsBorderSideTop:
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
        case AUICoreGraphicsBorderSideRight:
            CGContextMoveToPoint(context, boundingBox.x + boundingBox.width - topRight, boundingBox.y);
            if (topRight > 0.0)
                CGContextAddArc(context, boundingBox.x + boundingBox.width - topRight, boundingBox.y + topRight, topRight, 3.0 * M_PI_2, 0.0, false);
            CGContextAddLineToPoint(context, boundingBox.x + boundingBox.width, boundingBox.y + boundingBox.height - bottomRight);
            if (bottomRight > 0.0)
                CGContextAddArc(context, boundingBox.x + boundingBox.width - bottomRight, boundingBox.y + boundingBox.height - bottomRight, bottomRight, 0.0, M_PI_2, false);
            else
                CGContextAddLineToPoint(context, boundingBox.x + boundingBox.width, boundingBox.y + boundingBox.height);
            break;
        case AUICoreGraphicsBorderSideBottom:
            CGContextMoveToPoint(context, boundingBox.x + boundingBox.width, boundingBox.y + boundingBox.height - bottomRight);
            if (bottomRight > 0.0)
                CGContextAddArc(context, boundingBox.x + boundingBox.width - bottomRight, boundingBox.y + boundingBox.height - bottomRight, bottomRight, 0.0, M_PI_2, false);
            CGContextAddLineToPoint(context, boundingBox.x + bottomLeft, boundingBox.y + boundingBox.height);
            if (bottomLeft > 0.0)
                CGContextAddArc(context, boundingBox.x + bottomLeft, boundingBox.y + boundingBox.height - bottomLeft, bottomLeft, M_PI_2, M_PI, false);
            else
                CGContextAddLineToPoint(context, boundingBox.x, boundingBox.y + boundingBox.height);
            break;
        case AUICoreGraphicsBorderSideLeft:
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

    [self setStrokeColor: config->color inContext: context];
    CGContextSetLineJoin(context, kCGLineJoinRound);

    if (config->width.top > 0.0) {
        CGContextSetLineWidth(context, config->width.top);
        [self renderBorderSideWithContext: context boundingBox: boundingBox config: config topLeft: topLeft topRight: topRight bottomRight: bottomRight bottomLeft: bottomLeft side: AUICoreGraphicsBorderSideTop];
    }
    if (config->width.right > 0.0) {
        CGContextSetLineWidth(context, config->width.right);
        [self renderBorderSideWithContext: context boundingBox: boundingBox config: config topLeft: topLeft topRight: topRight bottomRight: bottomRight bottomLeft: bottomLeft side: AUICoreGraphicsBorderSideRight];
    }
    if (config->width.bottom > 0.0) {
        CGContextSetLineWidth(context, config->width.bottom);
        [self renderBorderSideWithContext: context boundingBox: boundingBox config: config topLeft: topLeft topRight: topRight bottomRight: bottomRight bottomLeft: bottomLeft side: AUICoreGraphicsBorderSideBottom];
    }
    if (config->width.left > 0.0) {
        CGContextSetLineWidth(context, config->width.left);
        [self renderBorderSideWithContext: context boundingBox: boundingBox config: config topLeft: topLeft topRight: topRight bottomRight: bottomRight bottomLeft: bottomLeft side: AUICoreGraphicsBorderSideLeft];
    }
}

+ (void)renderTextWithContext: (CGContextRef)context
                       config: (Clay_TextRenderData *)config
                  boundingBox: (Clay_BoundingBox)boundingBox
                 viewportSize: (AUISize)viewportSize
                 fontFamilies: (CFStringRef const *nillable)fontFamilies
{
    CFStringRef nillable string = [self copyString: config->stringContents];
    CTFontRef font;
    CFMutableAttributedStringRef attributedString;
    CFRange range;
    CTLineRef line;
    CGFloat ascent = 0.0;
    CGFloat descent = 0.0;
    CGFloat leading = 0.0;
    CGFloat lineHeight;
    double width;
    double baselineY;

    if (string == nullptr)
        return;

    font = [self createFontInFamilies: fontFamilies fontID: config->fontId size: config->fontSize];
    attributedString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
    CFAttributedStringReplaceString(attributedString, CFRangeMake(0, 0), string);
    range = CFRangeMake(0, CFStringGetLength(string));
    CFAttributedStringSetAttribute(attributedString, range, kCTFontAttributeName, font);
    CFAttributedStringSetAttribute(attributedString,
                                   range,
                                   kCTForegroundColorFromContextAttributeName,
                                   kCFBooleanTrue);
    if (config->letterSpacing != 0) {
        CFNumberRef kern = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloat32Type, &config->letterSpacing);

        CFAttributedStringSetAttribute(attributedString, range, kCTKernAttributeName, kern);
        CFRelease(kern);
    }

    line = CTLineCreateWithAttributedString(attributedString);
    width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    lineHeight = (config->lineHeight > 0 ? config->lineHeight : (ascent + descent + leading));
    baselineY = boundingBox.y + ((lineHeight - (ascent + descent)) / 2.0) + ascent;

    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0.0, viewportSize.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    [self setFillColor: config->textColor inContext: context];
    CGContextSetTextPosition(context,
                             boundingBox.x,
                             viewportSize.height - baselineY);
    CTLineDraw(line, context);
    CGContextRestoreGState(context);

    (void)width;
    CFRelease(line);
    CFRelease(attributedString);
    CFRelease(font);
    CFRelease(string);
}

+ (void)renderImageWithContext: (CGContextRef)context
                        config: (Clay_ImageRenderData *)config
                   boundingBox: (Clay_BoundingBox)boundingBox
{
    CGDataProviderRef nillable provider;
    CGImageSourceRef nillable imageSource;
    CGImageRef nillable image;
    CGMutablePathRef clipPath;
    double imageWidth;
    double imageHeight;
    double scale;
    double scaledWidth;
    double scaledHeight;
    CGRect drawRect;

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

    imageWidth = CGImageGetWidth(image);
    imageHeight = CGImageGetHeight(image);
    if (imageWidth <= 0.0 or imageHeight <= 0.0) {
        CGImageRelease(image);
        CFRelease(imageSource);
        CGDataProviderRelease(provider);
        return;
    }

    scale = fmin(boundingBox.width / imageWidth, boundingBox.height / imageHeight);
    scaledWidth = imageWidth * scale;
    scaledHeight = imageHeight * scale;
    drawRect = CGRectMake(boundingBox.x + (boundingBox.width - scaledWidth) / 2.0,
                          boundingBox.y + (boundingBox.height - scaledHeight) / 2.0,
                          scaledWidth,
                          scaledHeight);
    clipPath = [self createRoundedRectPathForBoundingBox: boundingBox radius: config->cornerRadius];

    CGContextSaveGState(context);
    CGContextAddPath(context, clipPath);
    CGContextClip(context);

    if (config->backgroundColor.a > 0) {
        [self setFillColor: config->backgroundColor inContext: context];
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
                    viewportSize: (AUISize)viewportSize
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
           viewportSize: (AUISize)viewportSize
           fontFamilies: (CFStringRef const *nillable)fontFamilies
{
    for (int32_t index = 0; index < commands.length; index++)
        [self renderCommandWithContext: context
                               command: Clay_RenderCommandArray_Get(&commands, index)
                          viewportSize: viewportSize
                          fontFamilies: fontFamilies];
}

@end

Clay_Dimensions AUICoreGraphicsMeasureText(Clay_StringSlice text,
                                           Clay_TextElementConfig *config,
                                           void *nillable userData)
{
    AUICoreGraphicsTextMeasureContext *measureContext = userData;
    CFStringRef const *fontFamilies = (measureContext != nullptr ? measureContext->fontFamilies : nullptr);
    CFStringRef nillable string = [AUICoreGraphicsRenderSupport copyString: text];
    CTFontRef font;
    CFMutableAttributedStringRef attributedString;
    CFRange range;
    CTLineRef line;
    CGFloat ascent = 0.0;
    CGFloat descent = 0.0;
    CGFloat leading = 0.0;
    double width;

    if (string == nullptr)
        return (Clay_Dimensions){ 0, 0 };

    font = [AUICoreGraphicsRenderSupport createFontInFamilies: fontFamilies
                                                       fontID: config->fontId
                                                         size: config->fontSize];
    attributedString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
    CFAttributedStringReplaceString(attributedString, CFRangeMake(0, 0), string);
    range = CFRangeMake(0, CFStringGetLength(string));
    CFAttributedStringSetAttribute(attributedString, range, kCTFontAttributeName, font);
    if (config->letterSpacing != 0) {
        CFNumberRef kern = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloat32Type, &config->letterSpacing);

        CFAttributedStringSetAttribute(attributedString, range, kCTKernAttributeName, kern);
        CFRelease(kern);
    }

    line = CTLineCreateWithAttributedString(attributedString);
    width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);

    CFRelease(line);
    CFRelease(attributedString);
    CFRelease(font);
    CFRelease(string);

    return (Clay_Dimensions){
        .width = (float)width,
        .height = (float)(config->lineHeight > 0 ? config->lineHeight : (ascent + descent + leading))
    };
}

#pragma clang assume_nonnull end
