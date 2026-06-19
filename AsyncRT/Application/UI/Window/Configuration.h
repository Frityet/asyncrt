#pragma once

#import <AsyncRT/Application/UI/Geometry.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncUIWindowConfiguration : OFObject<OFCopying>

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
// - (id)copy;

@end

#pragma clang assume_nonnull end
