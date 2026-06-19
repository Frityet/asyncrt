#pragma once

#import <AsyncRT/Application/UI/Surface/Immediate/AxisSize.h>
#import <AsyncRT/Application/UI/Surface/Immediate/EdgeInsets.h>

#pragma clang assume_nonnull begin

typedef enum [[clang::enum_extensibility(closed)]] AsyncUIStackDirection {
    AsyncUIStackDirectionVertical,
    AsyncUIStackDirectionHorizontal
} AsyncUIStackDirection;

typedef enum [[clang::enum_extensibility(closed)]] AsyncUIContentAlignment {
    AsyncUIContentAlignmentStart,
    AsyncUIContentAlignmentCenter,
    AsyncUIContentAlignmentEnd
} AsyncUIContentAlignment;

typedef enum [[clang::enum_extensibility(closed)]] AsyncUIScrollBehavior {
    AsyncUIScrollBehaviorNone,
    AsyncUIScrollBehaviorHorizontal,
    AsyncUIScrollBehaviorVertical,
    AsyncUIScrollBehaviorBoth
} AsyncUIScrollBehavior;

[[subclassing_restricted, direct_members]]
@interface AsyncUIStackLayout : OFObject

@property(retain, nonatomic) AsyncUIAxisSize *width;
@property(retain, nonatomic) AsyncUIAxisSize *height;
@property(retain, nonatomic) AsyncUIEdgeInsets *padding;
@property(nonatomic) uint16_t spacing;
@property(nonatomic) AsyncUIContentAlignment horizontalAlignment;
@property(nonatomic) AsyncUIContentAlignment verticalAlignment;
@property(nonatomic) AsyncUIStackDirection direction;
@property(nonatomic) AsyncUIScrollBehavior scrollBehavior;
@property(class, readonly, nonatomic) AsyncUIStackLayout *vertical;
@property(class, readonly, nonatomic) AsyncUIStackLayout *horizontal;

+ (instancetype)vertical;
+ (instancetype)horizontal;
- (instancetype)sizedWidth: (AsyncUIAxisSize *)width
                    height: (AsyncUIAxisSize *)height;
- (instancetype)padded: (AsyncUIEdgeInsets *)padding;
- (instancetype)spaced: (uint16_t)spacing;
- (instancetype)alignedHorizontally: (AsyncUIContentAlignment)horizontalAlignment
                           vertical: (AsyncUIContentAlignment)verticalAlignment;
- (instancetype)scrolling: (AsyncUIScrollBehavior)scrollBehavior;

@end

#pragma clang assume_nonnull end
