#pragma once

#import "UI/AUIRenderContext.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIWindowOptions : OFObject

@property(readonly, copy, nonatomic) OFString *title;
@property(readonly, nonatomic) AUISize initialSize;
@property(readonly, nonatomic) bool isResizable;
@property(readonly, nonatomic) bool automaticallyResizesToRootComponent;

+ (instancetype)title: (OFString *nillable)title
                 size: (AUISize)initialSize
            resizable: (bool)resizable;
+ (instancetype)title: (OFString *nillable)title
                 size: (AUISize)initialSize
            resizable: (bool)resizable
          autoResizeToRootComponent: (bool)automaticallyResizesToRootComponent;
+ (instancetype)defaultOptions;

@end

#pragma clang assume_nonnull end
