#pragma once

#import "Async/AsyncRuntime.h"

#pragma clang assume_nonnull begin

@protocol AUIRenderable
@optional

- (id<AUIRenderable>)renderableBody;
@end

@interface AUIComponent : OFObject<AUIRenderable>

- (id<AUIRenderable>)body;
- (void)mountInScope: (AsyncScope *)scope;
- (void)unmount;
- (void)setNeedsRender;

@end

#pragma clang assume_nonnull end
