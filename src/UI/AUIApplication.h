#pragma once

#import "UI/AUIComponent.h"
#import "UI/Backend/AUIBackend.h"
#import "UI/AUIExceptions.h"
#import "UI/AUIRenderContext.h"

#pragma clang assume_nonnull begin

@interface AUIApplication : AsyncApplication

@property(readonly, nonatomic) AUIComponent *nillable rootComponent;

- (AUIComponent *)makeRootComponent;
- (AUIWindowOptions *)windowOptions;
- (AUIWindowBackend *)makeWindowBackend;
- (AUIRendererBackend *)makeRendererBackend;
- (void)setNeedsRender;

@end

#pragma clang assume_nonnull end
