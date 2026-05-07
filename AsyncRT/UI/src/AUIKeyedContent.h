#pragma once

#import "AUIContent.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIKeyedContent : OFObject<AUIContent>

@property(readonly, copy, nonatomic) OFString *key;
@property(readonly, retain, nonatomic) id<AUIContent> content;

+ (instancetype)withKey: (OFString *)key content: (id<AUIContent>)content;
- (instancetype)initWithKey: (OFString *)key
                    content: (id<AUIContent>)content [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
