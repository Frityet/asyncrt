#pragma once

#import "Async/AsyncRuntime.h"
#import "UI/Components/Controls/AUIContextMenuItem.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AUIContextMenu : OFObject

@property(readonly, copy, nonatomic) OFArray<AUIContextMenuItem *> *items;

+ (instancetype)items: (OFArray<AUIContextMenuItem *> *nillable)items;

@end

#pragma clang assume_nonnull end
