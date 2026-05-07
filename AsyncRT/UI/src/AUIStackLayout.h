#pragma once

#import "AUIAxisSize.h"
#import "AUIEdgeInsets.h"

#pragma clang assume_nonnull begin

typedef enum [[clang::enum_extensibility(closed)]] AUIStackDirection {
    AUIStackDirectionVertical,
    AUIStackDirectionHorizontal
} AUIStackDirection;

typedef enum [[clang::enum_extensibility(closed)]] AUIContentAlignment {
    AUIContentAlignmentStart,
    AUIContentAlignmentCenter,
    AUIContentAlignmentEnd
} AUIContentAlignment;

typedef enum [[clang::enum_extensibility(closed)]] AUIScrollBehavior {
    AUIScrollBehaviorNone,
    AUIScrollBehaviorHorizontal,
    AUIScrollBehaviorVertical,
    AUIScrollBehaviorBoth
} AUIScrollBehavior;

[[subclassing_restricted, direct_members]]
@interface AUIStackLayout : OFObject

@property(retain, nonatomic) AUIAxisSize *width;
@property(retain, nonatomic) AUIAxisSize *height;
@property(retain, nonatomic) AUIEdgeInsets *padding;
@property(nonatomic) uint16_t spacing;
@property(nonatomic) AUIContentAlignment horizontalAlignment;
@property(nonatomic) AUIContentAlignment verticalAlignment;
@property(nonatomic) AUIStackDirection direction;
@property(nonatomic) AUIScrollBehavior scrollBehavior;
@property(class, readonly, nonatomic) AUIStackLayout *vertical;
@property(class, readonly, nonatomic) AUIStackLayout *horizontal;

+ (instancetype)vertical;
+ (instancetype)horizontal;
- (instancetype)sizedWidth: (AUIAxisSize *)width
                    height: (AUIAxisSize *)height;
- (instancetype)padded: (AUIEdgeInsets *)padding;
- (instancetype)spaced: (uint16_t)spacing;
- (instancetype)alignedHorizontally: (AUIContentAlignment)horizontalAlignment
                           vertical: (AUIContentAlignment)verticalAlignment;
- (instancetype)scrolling: (AUIScrollBehavior)scrollBehavior;

@end

#pragma clang assume_nonnull end
