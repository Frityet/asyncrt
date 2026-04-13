#import "UI/Components/Controls/AUIRadioGroup.h"
#import "UI/Components/Layout/AUIHStack.h"

#pragma clang assume_nonnull begin

@interface AUIRadioGroup ()

- (instancetype)initWithOptions: (OFArray<OFString *> *nillable)options
                  selectedIndex: (size_t)selectedIndex
                       onChange: (void (^nillable)(size_t index))changeHandler designated_initaliser;

@end

@implementation AUIRadioGroup {
    OFArray<OFString *> *_options;
    size_t _selectedIndex;
    void (^nillable _changeHandler)(size_t index);
}

@synthesize options = _options;
@synthesize selectedIndex = _selectedIndex;
@synthesize changeHandler = _changeHandler;

+ (instancetype)options: (OFArray<OFString *> *nillable)options
          selectedIndex: (size_t)selectedIndex
               onChange: (void (^nillable)(size_t index))changeHandler
{
    return [[self alloc] initWithOptions: options selectedIndex: selectedIndex onChange: changeHandler];
}

- (instancetype)initWithOptions: (OFArray<OFString *> *nillable)options
                  selectedIndex: (size_t)selectedIndex
                       onChange: (void (^nillable)(size_t index))changeHandler
{
    if (options == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _options = [$assert_nonnil(options) copy];
    _selectedIndex = selectedIndex;
    _changeHandler = [changeHandler copy];
    return self;
}

- (id<AUIRenderable>)renderableBody
{
    OFMutableArray<id<AUIRenderable>> *rows = [OFMutableArray array];
    AUITextStyle style = [AUIComponents controlTextStyleForSize: AUIControlSizeMedium
                                                        variant: AUIControlVariantNeutral
                                                        enabled: true];

    style.alignment = AUITextAlignmentLeft;

    for (size_t index = 0; index < _options.count; index++) {
        bool selected = (index == _selectedIndex);

        [rows addObject: [AUIHStack gap: 10 children: @[
            [AUIInteractiveBox layout: (AUILayout){
                                        .width = [AUI axisFixed: 22],
                                        .height = [AUI axisFixed: 22],
                                        .padding = [AUI insetsAll: 4],
                                        .childGap = 0,
                                        .childAlignment = [AUI childAlignmentX: AUIAlignmentCenter y: AUIAlignmentCenter],
                                        .direction = AUILayoutDirectionColumn
                                    }
                                 backgrounds: [AUIComponents controlColorsForVariant: (selected ? AUIControlVariantPrimary : AUIControlVariantSecondary)
                                                                               enabled: true]
                                      radius: 999
                                      border: [AUIComponents controlBorderForVariant: AUIControlVariantSecondary enabled: true]
                                     enabled: true
                                   focusable: false
                                  onActivate: ^{
                                      if (_changeHandler != nilptr)
                                          _changeHandler(index);
                                  }
                                    children: @[
                [AUIBox layout: (AUILayout){
                                    .width = [AUI axisGrow: 0],
                                    .height = [AUI axisGrow: 0],
                                    .padding = [AUI insetsAll: 0],
                                    .childGap = 0,
                                    .childAlignment = [AUI childAlignmentX: AUIAlignmentCenter y: AUIAlignmentCenter],
                                    .direction = AUILayoutDirectionColumn
                                }
                     background: (selected
                        ? [AUI colorWithRed: 255 green: 255 blue: 255 alpha: 255]
                        : [AUI colorWithRed: 0 green: 0 blue: 0 alpha: 0])
                         radius: 999
                         border: [AUI borderNone]
                       children: @[]]
            ]],
            [AUIText string: [_options objectAtIndex: index] style: style]
        ]]];
    }

    return [AUIVStack gap: 8 children: rows];
}

@end

#pragma clang assume_nonnull end
