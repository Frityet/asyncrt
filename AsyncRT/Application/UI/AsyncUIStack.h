#pragma once

#import <AsyncRT/Application/UI/AsyncUIContent.h>
#import <AsyncRT/Application/UI/AsyncUIStackLayout.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIStack : OFObject<AsyncUIContent>

@property(readonly, retain, nonatomic) AsyncUIStackLayout *layout;
@property(readonly, copy, nonatomic) OFArray<id<AsyncUIContent>> *children;

+ (instancetype)withLayout: (AsyncUIStackLayout *)layout
                  children: (OFArray<id<AsyncUIContent>> *)children;
- (instancetype)initWithLayout: (AsyncUIStackLayout *)layout
                      children: (OFArray<id<AsyncUIContent>> *)children [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
