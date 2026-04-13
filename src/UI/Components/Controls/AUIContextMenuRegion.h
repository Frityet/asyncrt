#pragma once

#import "UI/Components/Controls/AUIContextMenu.h"
#import "UI/Components/Layout/AUILayout.h"

#pragma clang assume_nonnull begin

@interface AUIContextMenuRegion : OFObject<AUICompositeRenderable>

@property(readonly, nonatomic) id<AUIRenderable> child;
@property(readonly, nonatomic) AUIContextMenu *menu;

+ (instancetype)child: (id<AUIRenderable> nillable)child
                 menu: (AUIContextMenu *nillable)menu;

@end

#pragma clang assume_nonnull end
