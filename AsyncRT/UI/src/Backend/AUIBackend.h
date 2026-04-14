#pragma once

#import "Backend/AUIInput.h"
#import "Backend/AUIWindow.h"
#import "Backend/AUIWindowOptions.h"
#import "Backend/Window/AUIHeadlessWindow.h"

#if !defined(AUI_HAS_CORE_GRAPHICS_WINDOW)
#   define AUI_HAS_CORE_GRAPHICS_WINDOW 0
#endif

#if AUI_HAS_CORE_GRAPHICS_WINDOW
#   import "Backend/Window/AUICoreGraphicsWindow.h"
#endif

#if !defined(AUI_HAS_CAIRO_X11_WINDOW)
#   define AUI_HAS_CAIRO_X11_WINDOW 0
#endif

#if AUI_HAS_CAIRO_X11_WINDOW
#   import "Backend/Window/AUICairoX11Window.h"
#endif

#pragma clang assume_nonnull begin

#pragma clang assume_nonnull end
