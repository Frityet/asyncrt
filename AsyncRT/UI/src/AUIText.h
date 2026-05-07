#pragma once

#import "AUIContent.h"
#import "AUITextStyle.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIText : OFObject<AUIContent>

@property(readonly, copy, nonatomic) OFString *string;
@property(readonly, retain, nonatomic) AUITextStyle *style;

+ (instancetype)withString: (OFString *)string
                  styledBy: (AUITextStyle *)style;
- (instancetype)initWithString: (OFString *)string
                         style: (AUITextStyle *)style [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
