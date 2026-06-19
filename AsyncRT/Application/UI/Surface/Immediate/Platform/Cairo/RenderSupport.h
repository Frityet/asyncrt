#pragma once

#include <cairo.h>

#import <AsyncRT/Application/UI/Surface/Immediate/ClaySupport.h>

#pragma clang assume_nonnull begin

typedef struct AsyncUICairoTextMeasureContext {
    cairo_t *context;
    char * _Nullable const * _Nullable fonts;
} AsyncUICairoTextMeasureContext;

extern Clay_Dimensions AsyncUICairoMeasureText(Clay_StringSlice text,
                                           Clay_TextElementConfig *config,
                                           void *nillable userData);

@namespace(AsyncUICairoRenderSupport)

+ (void)renderCommands: (Clay_RenderCommandArray)commands
              onContext: (cairo_t *)context
                  fonts: (char * _Nullable const * _Nullable)fonts;

@end

#pragma clang assume_nonnull end
