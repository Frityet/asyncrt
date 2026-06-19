#pragma once

#import <AsyncRT/Application/UI/Window/Input.h>
#import <AsyncRT/Application/UI/Window/Window.h>
#import <AsyncRT/Application/UI/Window/Configuration.h>
#import <AsyncRT/Application/UI/Window/Platform/Headless/Window.h>

#if !defined(AsyncUI_HAS_COCOA_WINDOW)
#   define AsyncUI_HAS_COCOA_WINDOW 0
#endif

#if AsyncUI_HAS_COCOA_WINDOW
#   import <AsyncRT/Application/UI/Window/Platform/Cocoa/Window.h>
#endif

#if !defined(AsyncUI_HAS_X11_WINDOW)
#   define AsyncUI_HAS_X11_WINDOW 0
#endif

#if AsyncUI_HAS_X11_WINDOW
#   import <AsyncRT/Application/UI/Window/Platform/X11/Window.h>
#endif

#pragma clang assume_nonnull begin

#pragma clang assume_nonnull end
