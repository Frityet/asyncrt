#pragma once

#import "AUIRenderContext.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIWindowOptions : OFObject

@property(readonly, copy, nonatomic) OFString *title;
@property(readonly, nonatomic) AUISize initialSize;
@property(readonly, nonatomic) bool isResizable;
@property(readonly, nonatomic) bool automaticallyResizesToRootComponent;
@property(readonly, nonatomic) bool scalesWithWindowSize;
@property(readonly, nonatomic) double contentScale;

+ (instancetype)    title: (OFString *)title
                     size: (AUISize)initialSize
                resizable: (bool)resizable
autoResizeToRootComponent: (bool)automaticallyResizesToRootComponent
      scaleWithWindowSize: (bool)scaleWithWindowSize
             contentScale: (double)contentScale;

+ (instancetype)defaultOptions;

@end

#pragma clang assume_nonnull end
