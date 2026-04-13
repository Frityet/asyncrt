#pragma once

#import "Async/AsyncRuntime.h"

#pragma clang assume_nonnull begin

@class AUIApplication;

@interface AUIRendererBackend : OFObject

@property(readonly, nonatomic) AUIApplication *application;

- (instancetype)initWithApplication: (AUIApplication *nillable)application [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
