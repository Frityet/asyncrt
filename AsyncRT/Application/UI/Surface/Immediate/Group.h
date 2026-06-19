#pragma once

#import <AsyncRT/Application/UI/Surface/Immediate/Content.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIGroup : OFObject<AsyncUIContent>

@property(readonly, copy, nonatomic) OFArray<id<AsyncUIContent>> *children;

+ (instancetype)withChildren: (OFArray<id<AsyncUIContent>> *)children;
- (instancetype)initWithChildren: (OFArray<id<AsyncUIContent>> *)children [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
