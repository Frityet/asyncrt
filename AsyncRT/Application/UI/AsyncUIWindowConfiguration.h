#pragma once

#import <AsyncRT/Application/UI/AsyncUIRenderContext.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIWindowConfiguration : OFObject

@property(copy, nonatomic) OFString *title;
@property(nonatomic) float initialWidth;
@property(nonatomic) float initialHeight;
@property(nonatomic) AsyncUISize initialSize;
@property(nonatomic) bool isResizable;
@property(nonatomic) bool automaticallyResizesToContent;
@property(nonatomic) bool scalesWithWindowSize;
@property(nonatomic) double contentScale;
@property(class, readonly, nonatomic) AsyncUIWindowConfiguration *defaults;

+ (instancetype)defaults;
+ (instancetype)withTitle: (OFString *)title
                    width: (float)width
                   height: (float)height;
+ (instancetype)withTitle: (OFString *)title
                     size: (AsyncUISize)initialSize
                resizable: (bool)isResizable
automaticallyResizesToContent: (bool)automaticallyResizesToContent
     scalesWithWindowSize: (bool)scalesWithWindowSize
             contentScale: (double)contentScale;

@end

#pragma clang assume_nonnull end
