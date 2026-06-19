#pragma once

#import <AsyncRT/Application/UI/Surface/Immediate/ContextMenuItem.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncUIContextMenu : OFObject

@property(readonly, copy, nonatomic) OFArray<AsyncUIContextMenuItem *> *items;

+ (instancetype)withItems: (OFArray<AsyncUIContextMenuItem *> *nonnil)items;
- (instancetype)initWithItems: (OFArray<AsyncUIContextMenuItem *> *nonnil)items [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
