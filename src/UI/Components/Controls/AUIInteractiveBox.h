#pragma once

#import "UI/Components/AUIValues.h"

#pragma clang assume_nonnull begin

@interface AUIInteractiveBox : OFObject<AUIRenderable>

@property(readonly, nonatomic) AUILayout layout;
@property(readonly, nonatomic) AUIControlColors backgrounds;
@property(readonly, nonatomic) float cornerRadius;
@property(readonly, nonatomic) AUIBorder border;
@property(readonly, nonatomic, getter=isEnabled) bool enabled;
@property(readonly, nonatomic, getter=isFocusable) bool focusable;
@property(readonly, copy, nonatomic) OFArray<id<AUIRenderable>> *children;
@property(readonly, copy, nonatomic) void (^nillable activateHandler)(void);

+ (instancetype)layout: (AUILayout)layout
           backgrounds: (AUIControlColors)backgrounds
                radius: (float)cornerRadius
                border: (AUIBorder)border
               enabled: (bool)enabled
             focusable: (bool)focusable
            onActivate: (void (^nillable)(void))activateHandler
              children: (OFArray<id<AUIRenderable>> *nillable)children;

@end

#pragma clang assume_nonnull end
