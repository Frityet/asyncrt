#pragma once

#import <CoreGraphics/CoreGraphics.h>

#import "AUIRenderContext.h"
#import "clay.h"

#pragma clang assume_nonnull begin

typedef struct AUICoreGraphicsTextMeasureContext {
    CFStringRef _Nullable const * _Nullable fontFamilies;
} AUICoreGraphicsTextMeasureContext;

extern Clay_Dimensions AUICoreGraphicsMeasureText(Clay_StringSlice text,
                                                  Clay_TextElementConfig *config,
                                                  void *nillable userData);

@namespace(AUICoreGraphicsRenderSupport)

+ (void)renderCommands: (Clay_RenderCommandArray)commands
              onContext: (CGContextRef)context
           viewportSize: (AUISize)viewportSize
           fontFamilies: (CFStringRef _Nullable const * _Nullable)fontFamilies;

@end

#pragma clang assume_nonnull end
