#pragma once

#import "AUIViewComponent.h"
#import "Backend/AUIBackend.h"
#import "AUIExceptions.h"
#import "AUIRenderContext.h"

#pragma clang assume_nonnull begin

@interface AUIApplication : AsyncApplication

@property(readonly, nonatomic) AUIViewComponent *nillable rootViewComponent;

- (AUIViewComponent *)makeRootViewComponent;
- (AUIWindowOptions *)windowOptions;
- (AUIWindow *)makeWindow;
- (void)setNeedsRender;

@end

#pragma clang assume_nonnull end
