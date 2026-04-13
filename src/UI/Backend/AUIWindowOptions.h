#pragma once

#import "UI/AUIRenderContext.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIWindowOptions : OFObject

@property(readonly, copy, nonatomic) OFString *title;
@property(readonly, nonatomic) AUISize initialSize;
@property(readonly, nonatomic) bool isResizable;

+ (instancetype)title: (OFString *nillable)title
                 size: (AUISize)initialSize
            resizable: (bool)resizable;
+ (instancetype)defaultOptions;

@end

#pragma clang assume_nonnull end
