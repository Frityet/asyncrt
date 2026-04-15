#pragma once

#import "AsyncRuntime.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIContextMenuItem : OFObject

@property(readonly, copy, nonatomic) OFString *title;
@property(readonly, nonatomic) bool isEnabled;
@property(readonly, copy, nonatomic) void (^nillable selectHandler)(void);

+ (instancetype)title: (OFString *nonnil)title
              enabled: (bool)enabled
             onSelect: (void (^nillable)(void))selectHandler;

@end

#pragma clang assume_nonnull end
