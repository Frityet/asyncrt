#pragma once

#import "AUIBoxStyle.h"
#import "AUIContent.h"
#import "AUIInteraction.h"
#import "AUIStackLayout.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIBox : OFObject<AUIContent>

@property(readonly, retain, nonatomic) AUIBoxStyle *style;
@property(readonly, retain, nonatomic) AUIStackLayout *layout;
@property(readonly, retain, nonatomic) AUIInteraction *nillable interaction;
@property(readonly, copy, nonatomic) OFArray<id<AUIContent>> *children;

+ (instancetype)withLayout: (AUIStackLayout *)layout
                  styledBy: (AUIBoxStyle *)style
               interaction: (AUIInteraction *nillable)interaction
                  children: (OFArray<id<AUIContent>> *)children;
- (instancetype)initWithStyle: (AUIBoxStyle *)style
                       layout: (AUIStackLayout *)layout
                  interaction: (AUIInteraction *nillable)interaction
                     children: (OFArray<id<AUIContent>> *)children [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
