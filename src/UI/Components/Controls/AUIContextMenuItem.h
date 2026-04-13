#pragma once

#import "Async/AsyncRuntime.h"

#pragma clang assume_nonnull begin

@interface AUIContextMenuItem : OFObject

@property(readonly, copy, nonatomic) OFString *title;
@property(readonly, nonatomic, getter=isEnabled) bool enabled;
@property(readonly, copy, nonatomic) void (^nillable selectHandler)(void);

+ (instancetype)title: (OFString *nillable)title
              enabled: (bool)enabled
             onSelect: (void (^nillable)(void))selectHandler;

@end

#pragma clang assume_nonnull end
