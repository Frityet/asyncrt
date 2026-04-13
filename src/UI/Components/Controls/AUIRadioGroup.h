#pragma once

#import "UI/Components/AUIComponentSupport.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AUIRadioGroup : OFObject<AUIRenderable>

@property(readonly, copy, nonatomic) OFArray<OFString *> *options;
@property(readonly, nonatomic) size_t selectedIndex;
@property(readonly, copy, nonatomic) void (^nillable changeHandler)(size_t index);

+ (instancetype)options: (OFArray<OFString *> *nillable)options
          selectedIndex: (size_t)selectedIndex
               onChange: (void (^nillable)(size_t index))changeHandler;

@end

#pragma clang assume_nonnull end
