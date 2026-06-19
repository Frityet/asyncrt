#pragma once

#import <AsyncRT/Application/UI/Surface/Immediate/Content.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIKeyedContent : OFObject<AsyncUIContent>

@property(readonly, copy, nonatomic) OFString *key;
@property(readonly, retain, nonatomic) id<AsyncUIContent> content;

+ (instancetype)withKey: (OFString *)key content: (id<AsyncUIContent>)content;
- (instancetype)initWithKey: (OFString *)key
                    content: (id<AsyncUIContent>)content [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
