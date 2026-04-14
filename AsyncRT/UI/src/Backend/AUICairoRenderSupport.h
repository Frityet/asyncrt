#pragma once

#include <cairo.h>

#import "AUIInternal.h"

#pragma clang assume_nonnull begin

typedef struct AUICairoTextMeasureContext {
    cairo_t *context;
    char * _Nullable const * _Nullable fonts;
} AUICairoTextMeasureContext;

extern Clay_Dimensions AUICairoMeasureText(Clay_StringSlice text,
                                           Clay_TextElementConfig *config,
                                           void *nillable userData);

@namespace(AUICairoRenderSupport)

+ (void)renderCommands: (Clay_RenderCommandArray)commands
              onContext: (cairo_t *)context
                  fonts: (char * _Nullable const * _Nullable)fonts;

@end

#pragma clang assume_nonnull end
