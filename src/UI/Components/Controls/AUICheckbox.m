#import "UI/Components/Controls/AUICheckbox.h"
#import "UI/Components/Layout/AUIHStack.h"

#pragma clang assume_nonnull begin

@interface AUICheckbox ()

- (instancetype)initWithLabel: (OFString *nillable)label
                      checked: (bool)checked
                      enabled: (bool)enabled
                     onChange: (void (^nillable)(bool value))changeHandler designated_initaliser;

@end

@implementation AUICheckbox {
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

    style.alignment = AUITextAlignmentLeft;

    return [AUIHStack gap: 10 children: @[
        [AUIInteractiveBox layout: (AUILayout){
                                    .width = [AUI axisFixed: 22],
                                    .height = [AUI axisFixed: 22],
                                    .padding = [AUI insetsAll: 0],
                                    .childGap = 0,
                                    .childAlignment = [AUI childAlignmentX: AUIAlignmentCenter y: AUIAlignmentCenter],
                                    .direction = AUILayoutDirectionColumn
                                }
                             backgrounds: (_checked
                                ? [AUIComponents controlColorsForVariant: AUIControlVariantPrimary enabled: _enabled]
                                : [AUIComponents controlColorsForVariant: AUIControlVariantSecondary enabled: _enabled])
                                  radius: 6
                                  border: [AUIComponents controlBorderForVariant: AUIControlVariantSecondary enabled: _enabled]
                                 enabled: _enabled
                               focusable: false
                              onActivate: ^{
                                  if (_changeHandler != nilptr)
                                      _changeHandler(not _checked);
                              }
                                children: @[
            [AUIText string: (_checked ? @"x" : @"")
                      style: [AUIComponents controlTextStyleForSize: AUIControlSizeSmall
                                                             variant: (_checked ? AUIControlVariantPrimary : AUIControlVariantNeutral)
                                                             enabled: _enabled]]
        ]],
        [AUIText string: _label style: style]
    ]];
}

@end

#pragma clang assume_nonnull end
