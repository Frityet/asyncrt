#pragma once

#import "AUIContent.h"
#import "AUIStackLayout.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIStack : OFObject<AUIContent>

@property(readonly, retain, nonatomic) AUIStackLayout *layout;
@property(readonly, copy, nonatomic) OFArray<id<AUIContent>> *children;

+ (instancetype)withLayout: (AUIStackLayout *)layout
                  children: (OFArray<id<AUIContent>> *)children;
- (instancetype)initWithLayout: (AUIStackLayout *)layout
                      children: (OFArray<id<AUIContent>> *)children [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
