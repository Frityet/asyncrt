#pragma once

#import "Backend/AUIWindow.h"

#pragma clang assume_nonnull begin

typedef Clay_Dimensions (*AUITextMeasureFunction)(Clay_StringSlice text,
                                                  Clay_TextElementConfig *config,
                                                  void *nillable userData);

@interface AUIWindow ()

- (double)_contentScale;
- (bool)_scalesWithWindowSize;
- (AUISize)_viewportSizeForNativeSize: (AUISize)nativeSize;
- (AUISize)_nativeSizeForViewportSize: (AUISize)viewportSize;
- (void)_setViewportSize: (AUISize)viewportSize;
- (void)_setDarkMode: (bool)darkMode explicitly: (bool)explicitly;
- (bool)_hasExplicitDarkMode;
- (Clay_RenderCommandArray)_buildRenderCommandsForViewportSize: (AUISize)viewportSize
                                            textMeasureFunction: (AUITextMeasureFunction)textMeasureFunction
                                                       userData: (void *nillable)userData;

@end

#pragma clang assume_nonnull end
