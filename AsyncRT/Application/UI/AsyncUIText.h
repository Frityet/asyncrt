#pragma once

#import <AsyncRT/Application/UI/AsyncUIContent.h>
#import <AsyncRT/Application/UI/AsyncUITextStyle.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIText : OFObject<AsyncUIContent>

@property(readonly, copy, nonatomic) OFString *string;
@property(readonly, retain, nonatomic) AsyncUITextStyle *style;

+ (instancetype)withString: (OFString *)string
                  styledBy: (AsyncUITextStyle *)style;
- (instancetype)initWithString: (OFString *)string
                         style: (AsyncUITextStyle *)style [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
