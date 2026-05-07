#pragma once

#import "AUIContent.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIGroup : OFObject<AUIContent>

@property(readonly, copy, nonatomic) OFArray<id<AUIContent>> *children;

+ (instancetype)withChildren: (OFArray<id<AUIContent>> *)children;
- (instancetype)initWithChildren: (OFArray<id<AUIContent>> *)children [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
