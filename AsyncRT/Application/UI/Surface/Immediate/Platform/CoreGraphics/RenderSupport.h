#pragma once

#import <CoreGraphics/CoreGraphics.h>

#import <AsyncRT/Application/UI/Surface/Immediate/ClaySupport.h>

#pragma clang assume_nonnull begin

typedef struct AsyncUICoreGraphicsTextMeasureContext {
    CFStringRef _Nullable const * _Nullable fontFamilies;
} AsyncUICoreGraphicsTextMeasureContext;

extern Clay_Dimensions AsyncUICoreGraphicsMeasureText(Clay_StringSlice text,
                                                  Clay_TextElementConfig *config,
                                                  void *nillable userData);

@namespace(AsyncUICoreGraphicsRenderSupport)

+ (void)renderCommands: (Clay_RenderCommandArray)commands
              onContext: (CGContextRef)context
           viewportSize: (AsyncUISize)viewportSize
           fontFamilies: (CFStringRef _Nullable const * _Nullable)fontFamilies;

@end

#pragma clang assume_nonnull end
