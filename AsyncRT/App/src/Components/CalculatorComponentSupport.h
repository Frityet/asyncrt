#pragma once

#import "CalculatorComponents.h"
#import "CalculatorModel.h"
#import "CalculatorTheme.h"

#pragma clang assume_nonnull begin

@interface AUIViewComponent (CalculatorSharedModelRefresh)

- (void)_refreshCalculatorInterfaceAfterSharedModelMutation;

@end

@namespace(CalculatorViews)

+ (AUIViewText *)text: (OFString *nonnil)text style: (AUITextStyle)style;
+ (AUIViewBox *)boxWithKey: (OFString *nonnil)key
                       props: (AUIBoxProps)props
                    children: (OFArray<id<AUIRenderable>> *nonnil)children;
+ (AUIViewBox *)rowWithKey: (OFString *nonnil)key
                      gap: (uint16_t)gap
                 children: (OFArray<id<AUIRenderable>> *nonnil)children;
+ (AUIViewBox *)columnWithKey: (OFString *nonnil)key
                         gap: (uint16_t)gap
                    children: (OFArray<id<AUIRenderable>> *nonnil)children;
+ (AUIViewBox *)fixedWidthWithKey: (OFString *nonnil)key
                            width: (float)width
                            child: (id<AUIRenderable>)child;
+ (AUIViewBox *)scrollColumnWithKey: (OFString *nonnil)key
                                children: (OFArray<id<AUIRenderable>> *nonnil)children;
+ (AUIViewBox *)metricTileWithKey: (OFString *nonnil)key
                               label: (OFString *nonnil)label
                               value: (OFString *nonnil)value;
+ (AUIViewBox *)historyTileWithKey: (OFString *nonnil)key
                                children: (OFArray<id<AUIRenderable>> *nonnil)children;
+ (AUIViewBox *)badgeWithKey: (OFString *nonnil)key
                             text: (OFString *nonnil)text
                          variant: (AUIControlVariant)variant;
+ (AUIViewBox *)dividerWithKey: (OFString *nonnil)key color: (AUIColor)color;
+ (AUIViewBox *)buttonWithKey: (OFString *nonnil)key
                     title: (OFString *nonnil)title
                   variant: (AUIControlVariant)variant
                      size: (AUIControlSize)size
                 isEnabled: (bool)isEnabled
                   onPress: (void (^nonnil)(void))onPress;

@end

[[subclassing_restricted]]
@interface CalculatorHeaderComponent : AUIViewComponent

- (instancetype)initWithModel: (CalculatorModel *nonnil)model [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface CalculatorDisplayComponent : AUIViewComponent

- (instancetype)initWithModel: (CalculatorModel *nonnil)model [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface CalculatorKeypadComponent : AUIViewComponent

- (instancetype)initWithModel: (CalculatorModel *nonnil)model [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted]]
@interface CalculatorSidebarComponent : AUIViewComponent

- (instancetype)initWithModel: (CalculatorModel *nonnil)model [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
