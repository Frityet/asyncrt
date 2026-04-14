#pragma once

#import "AsyncRuntime.h"
#import "Components/Controls/AUIContextMenuItem.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUIContextMenu : OFObject

@property(readonly, copy, nonatomic) OFArray<AUIContextMenuItem *> *items;

+ (instancetype)items: (OFArray<AUIContextMenuItem *> *nillable)items;

@end

#pragma clang assume_nonnull end
