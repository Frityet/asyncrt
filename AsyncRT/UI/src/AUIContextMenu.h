#pragma once

#import "AUIContextMenuItem.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIContextMenu : OFObject

@property(readonly, copy, nonatomic) OFArray<AUIContextMenuItem *> *items;

+ (instancetype)withItems: (OFArray<AUIContextMenuItem *> *nonnil)items;
- (instancetype)initWithItems: (OFArray<AUIContextMenuItem *> *nonnil)items [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
