#pragma once

#import <AsyncRT/Application/UI/Backend/AsyncUIInput.h>
#import <AsyncRT/Application/UI/Backend/AsyncUIWindow.h>
#import <AsyncRT/Application/UI/AsyncUIWindowConfiguration.h>
#import <AsyncRT/Application/UI/Backend/Window/AsyncUIHeadlessWindow.h>

#if !defined(AsyncUI_HAS_CORE_GRAPHICS_WINDOW)
#   define AsyncUI_HAS_CORE_GRAPHICS_WINDOW 0
#endif

#if AsyncUI_HAS_CORE_GRAPHICS_WINDOW
#   import <AsyncRT/Application/UI/Backend/Window/AsyncUICoreGraphicsWindow.h>
#endif

#if !defined(AsyncUI_HAS_CAIRO_X11_WINDOW)
#   define AsyncUI_HAS_CAIRO_X11_WINDOW 0
#endif

#if AsyncUI_HAS_CAIRO_X11_WINDOW
#   import <AsyncRT/Application/UI/Backend/Window/AsyncUICairoX11Window.h>
#endif

#pragma clang assume_nonnull begin

#pragma clang assume_nonnull end
