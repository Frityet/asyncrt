#import "UI/Components/Controls/AUIToggle.h"
#import "UI/Components/Layout/AUIHStack.h"
#import "UI/Components/Layout/AUISpacer.h"

#pragma clang assume_nonnull begin

@interface AUIToggle ()

- (instancetype)initWithLabel: (OFString *nillable)label
                      checked: (bool)checked
                      enabled: (bool)enabled
                     onChange: (void (^nillable)(bool value))changeHandler designated_initaliser;

@end

@implementation AUIToggle {
    OFString *_label;
    bool _checked;
    bool _enabled;
    void (^nillable _changeHandler)(bool value);
}

@synthesize label = _label;
@synthesize checked = _checked;
@synthesize enabled = _enabled;
@synthesize changeHandler = _changeHandler;

+ (instancetype)label: (OFString *nillable)label
              checked: (bool)checked
              enabled: (bool)enabled
             onChange: (void (^nillable)(bool value))changeHandler
{
    return [[self alloc] initWithLabel: label checked: checked enabled: enabled onChange: changeHandler];
}

- (instancetype)initWithLabel: (OFString *nillable)label
                      checked: (bool)checked
                      enabled: (bool)enabled
                     onChange: (void (^nillable)(bool value))changeHandler
{
    if (label == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _label = [$assert_nonnil(label) copy];
    _checked = checked;
    _enabled = enabled;
    _changeHandler = [changeHandler copy];
    return self;
}

- (id<AUIRenderable>)renderableBody
{
    AUITextStyle style = [AUIComponents controlTextStyleForSize: AUIControlSizeMedium
                                                        variant: AUIControlVariantNeutral
                                                        enabled: _enabled];
    AUIControlColors trackColors = (_checked
        ? [AUIComponents controlColorsForVariant: AUIControlVariantPrimary enabled: _enabled]
        : [AUIComponents controlColorsForVariant: AUIControlVariantSecondary enabled: _enabled]);

    style.alignment = AUITextAlignmentLeft;

    return [AUIHStack gap: 10 children: @[
        [AUIInteractiveBox layout: (AUILayout){
                                    .width = [AUI axisFixed: 44],
                                    .height = [AUI axisFixed: 24],
                                    .padding = [AUI insetsWithLeft: (_checked ? 22 : 2)
                                                                right: (_checked ? 2 : 22)
                                                                  top: 2
                                                               bottom: 2],
                                    .childGap = 0,
                                    .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentCenter],
                                    .direction = AUILayoutDirectionRow
                                }
                             backgrounds: trackColors
                                  radius: 999
                                  border: [AUIComponents controlBorderForVariant: AUIControlVariantSecondary enabled: _enabled]
                                 enabled: _enabled
                               focusable: false
                              onActivate: ^{
                                  if (_changeHandler != nilptr)
                                      _changeHandler(not _checked);
                              }
                                children: @[
            [AUIBox layout: (AUILayout){
                                .width = [AUI axisFixed: 18],
                                .height = [AUI axisFixed: 18],
                                .padding = [AUI insetsAll: 0],
                                .childGap = 0,
                                .childAlignment = [AUI childAlignmentX: AUIAlignmentCenter y: AUIAlignmentCenter],
                                .direction = AUILayoutDirectionColumn
                            }
                 background: [AUI colorWithRed: 255 green: 255 blue: 255 alpha: 255]
                     radius: 999
                     border: [AUI borderNone]
                   children: @[]]
        ]],
        [AUIText string: _label style: style]
    ]];
}

@end

#pragma clang assume_nonnull end
