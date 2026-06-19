#pragma once

#import <AsyncRT/Application/UI/Surface/Immediate/ClaySupport.h>
#import <AsyncRT/Application/UI/Window/Window.h>

#pragma clang assume_nonnull begin

typedef Clay_Dimensions (*AsyncUITextMeasureFunction)(Clay_StringSlice text,
                                                  Clay_TextElementConfig *config,
                                                  void *nillable userData);

@interface AsyncUIWindow ()

- (double)_contentScale;
- (bool)_scalesWithWindowSize;
- (AsyncUISize)_viewportSizeForNativeSize: (AsyncUISize)nativeSize;
- (AsyncUISize)_nativeSizeForViewportSize: (AsyncUISize)viewportSize;
- (void)_setViewportSize: (AsyncUISize)viewportSize;
- (void)_setDarkMode: (bool)darkMode explicitly: (bool)explicitly;
- (bool)_hasExplicitDarkMode;
- (Clay_RenderCommandArray)_buildRenderCommandsForViewportSize: (AsyncUISize)viewportSize
                                            textMeasureFunction: (AsyncUITextMeasureFunction)textMeasureFunction
                                                       userData: (void *nillable)userData;

@end

#pragma clang assume_nonnull end
