#pragma once

#import <AsyncRT/Application/UI/AsyncUIBoxStyle.h>
#import <AsyncRT/Application/UI/AsyncUIContent.h>
#import <AsyncRT/Application/UI/AsyncUIInteraction.h>
#import <AsyncRT/Application/UI/AsyncUIStackLayout.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIBox : OFObject<AsyncUIContent>

@property(readonly, retain, nonatomic) AsyncUIBoxStyle *style;
@property(readonly, retain, nonatomic) AsyncUIStackLayout *layout;
@property(readonly, retain, nonatomic) AsyncUIInteraction *nillable interaction;
@property(readonly, copy, nonatomic) OFArray<id<AsyncUIContent>> *children;

+ (instancetype)withLayout: (AsyncUIStackLayout *)layout
                  styledBy: (AsyncUIBoxStyle *)style
               interaction: (AsyncUIInteraction *nillable)interaction
                  children: (OFArray<id<AsyncUIContent>> *)children;
- (instancetype)initWithStyle: (AsyncUIBoxStyle *)style
                       layout: (AsyncUIStackLayout *)layout
                  interaction: (AsyncUIInteraction *nillable)interaction
                     children: (OFArray<id<AsyncUIContent>> *)children [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
