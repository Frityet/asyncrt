#pragma once

#import "UI/AUIViewComponent.h"
#import "UI/Backend/AUIBackend.h"
#import "UI/AUIExceptions.h"
#import "UI/AUIRenderContext.h"

#pragma clang assume_nonnull begin

@interface AUIApplication : AsyncApplication

@property(readonly, nonatomic) AUIViewComponent *nillable rootViewComponent;

- (AUIViewComponent *)makeRootViewComponent;
- (AUIWindowOptions *)windowOptions;
- (AUIWindow *)makeWindow;
- (void)setNeedsRender;

@end

#pragma clang assume_nonnull end
