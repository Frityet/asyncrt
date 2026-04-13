#import "UI/AUI.h"
#import "Utilities/Signal.h"

#pragma clang assume_nonnull begin

@interface AppRootComponent : AUIComponent

+ (AUITextStyle)heroTitleStyle;
+ (AUITextStyle)bodyTextStyle;
+ (AUITextStyle)metricTextStyle;
+ (AUIControlVariant)variantForSelection: (size_t)selection;
+ (OFString *)variantNameForSelection: (size_t)selection;

@end

@implementation AppRootComponent {
    Signal<OFNumber *> *_tickCount, *_elapsedSeconds, *_tickerEnabled, *_showPreview, *_selectedVariant;
    Signal<OFString *> *_searchText, *_draftLabel;
}

+ (AUITextStyle)heroTitleStyle
{
    AUITextStyle style = AUI.textStyle;

    style.fontSize = 32;
    style.color = [AUI colorWithRed: 26 green: 31 blue: 37 alpha: 255];
    return style;
}

+ (AUITextStyle)bodyTextStyle
{
    AUITextStyle style = AUI.textStyle;

    style.fontSize = 18;
    style.color = [AUI colorWithRed: 78 green: 84 blue: 90 alpha: 255];
    return style;
}

+ (AUITextStyle)metricTextStyle
{
    AUITextStyle style = AUI.textStyle;

    style.fontSize = 28;
    style.color = [AUI colorWithRed: 26 green: 31 blue: 37 alpha: 255];
    return style;
}

+ (AUIControlVariant)variantForSelection: (size_t)selection
{
    switch (selection) {
        case 1:
            return AUIControlVariantSecondary;
        case 2:
            return AUIControlVariantDanger;
        case 0:
        default:
            return AUIControlVariantPrimary;
    }
}

+ (OFString *)variantNameForSelection: (size_t)selection
{
    switch (selection) {
        case 1:
            return @"Secondary";
        case 2:
            return @"Danger";
        case 0:
        default:
            return @"Primary";
    }
}

- (instancetype)init
{
    self = [super init];
    _tickCount = [Signal withValue: @12];
    _elapsedSeconds = [Signal withValue: @6];
    _tickerEnabled = [Signal withValue: @true];
    _showPreview = [Signal withValue: @true];
    _selectedVariant = [Signal withValue: @0];
    _searchText = [Signal withValue: @""];
    _draftLabel = [Signal withValue: @"AUI badge"];
    return self;
}

- (id<AUIRenderable>)body
{
    uint32_t tickCount = _tickCount.value.unsignedIntValue;
    uint32_t elapsedSeconds = _elapsedSeconds.value.unsignedIntValue;
    bool tickerEnabled = _tickerEnabled.value.boolValue;
    bool showPreview = _showPreview.value.boolValue;
    size_t selectedVariant = _selectedVariant.value.unsignedIntValue;
    AUIControlVariant tone = [self.class variantForSelection: selectedVariant];
    OFString *searchText = (_searchText.value ?: @"");
    OFString *draftLabel = (_draftLabel.value ?: @"");
    OFString *searchSummary = (searchText.length > 0 ? searchText : @"No active filter");
    OFString *badgeTitle = (draftLabel.length > 0 ? draftLabel : @"AUI badge");
    OFString *toneName = [self.class variantNameForSelection: selectedVariant];
    float progress = (float)(tickCount % 12) / 12.0f;
    auto content = [OFMutableArray<id<AUIRenderable>> array];

    [content addObject: [AUICard children: @[
        [AUIVStack gap: 16 children: @[
            [AUIHStack gap: 12 children: @[
                [AUIVStack gap: 6 children: @[
                    [AUILabel text: @"AUI Component Catalog" style: self.class.heroTitleStyle],
                    [AUILabel text: @"The sample app now uses the higher-level layout, surface, display, controls, and forms wrappers instead of manually building the whole tree from primitives."
                              style: self.class.bodyTextStyle]
                ]],
                [AUISpacer grow],
                [AUIBadge text: @"Catalog preview"
                       variant: tone]
            ]],
            [AUIProgressBar progress: progress variant: tone],
            [AUIHStack gap: 10 children: @[
                [AUIButton title: @"Tick now"
                         variant: AUIControlVariantPrimary
                            size: AUIControlSizeMedium
                         enabled: true
                         onPress: ^{
                             _tickCount.value = @(tickCount + 1);
                         }],
                [AUIButton title: (tickerEnabled ? @"Pause ticker" : @"Resume ticker")
                         variant: AUIControlVariantSecondary
                            size: AUIControlSizeMedium
                         enabled: true
                         onPress: ^{
                             _tickerEnabled.value = @(not tickerEnabled);
                         }],
                [AUIButton title: @"Clear query"
                         variant: AUIControlVariantNeutral
                            size: AUIControlSizeMedium
                         enabled: (searchText.length > 0)
                         onPress: ^{
                             _searchText.value = @"";
                         }]
            ]]
        ]]
    ]]];

    [content addObject: [AUIDivider horizontalWithThickness: 1
                                                      color: [AUI colorWithRed: 214 green: 207 blue: 193 alpha: 255]]];

    [content addObject: [AUIHStack gap: 16 children: @[
        [AUIFrame width: [AUI axisGrow: 0]
                 height: [AUI axisFit: 0]
                  child: [AUICard children: @[
            [AUISection title: @"Overview" children: @[
                [AUIHStack gap: 12 children: @[
                    [AUIFrame width: [AUI axisGrow: 0]
                             height: [AUI axisFit: 0]
                              child: [AUIVStack gap: 4 children: @[
                        [AUILabel text: @"Ticks"],
                        [AUILabel text: [OFString stringWithFormat: @"%u", tickCount]
                                  style: self.class.metricTextStyle]
                    ]]],
                    [AUIFrame width: [AUI axisGrow: 0]
                             height: [AUI axisFit: 0]
                              child: [AUIVStack gap: 4 children: @[
                        [AUILabel text: @"Elapsed"],
                        [AUILabel text: [OFString stringWithFormat: @"%us", elapsedSeconds]
                                  style: self.class.metricTextStyle]
                    ]]]
                ]],
                [AUIDivider horizontalWithThickness: 1
                                              color: [AUI colorWithRed: 230 green: 233 blue: 237 alpha: 255]],
                [AUIHStack gap: 8 children: @[
                    [AUILabel text: @"Active tone:"],
                    [AUIBadge text: toneName variant: tone]
                ]],
                [AUILabel text: [OFString stringWithFormat: @"Search filter: %@", searchSummary]
                          style: self.class.bodyTextStyle],
                [AUILabel text: @"Close the window to exit the catalog preview."
                          style: self.class.bodyTextStyle]
            ]]
        ]]],
        [AUIFrame width: [AUI axisGrow: 0]
                 height: [AUI axisFit: 0]
                  child: [AUICard children: @[
            [AUISection title: @"Controls" children: @[
                [AUISearchField text: searchText
                         placeholder: @"Filter components"
                             enabled: true
                            onChange: ^(OFString *value) {
                                _searchText.value = [value copy];
                            }
                            onSubmit: nilptr],
                [AUITextField text: draftLabel
                         placeholder: @"Badge label"
                             enabled: true
                            onChange: ^(OFString *value) {
                                _draftLabel.value = [value copy];
                            }
                            onSubmit: nilptr],
                [AUIToggle label: @"Live ticker updates"
                          checked: tickerEnabled
                          enabled: true
                         onChange: ^(bool value) {
                             _tickerEnabled.value = @(value);
                         }],
                [AUICheckbox label: @"Show preview card"
                            checked: showPreview
                            enabled: true
                           onChange: ^(bool value) {
                               _showPreview.value = @(value);
                           }],
                [AUIRadioGroup options: @[ @"Primary", @"Secondary", @"Danger" ]
                          selectedIndex: selectedVariant
                               onChange: ^(size_t index) {
                                   _selectedVariant.value = @(index);
                               }]
            ]]
        ]]]
    ]]];

    if (showPreview) {
        [content addObject: [AUICard children: @[
            [AUISection title: @"Preview" children: @[
                [AUIHStack gap: 10 children: @[
                    [AUIBadge text: badgeTitle variant: tone],
                    [AUILabel text: [OFString stringWithFormat: @"Rendered with the %@ component theme.", toneName]
                              style: self.class.bodyTextStyle]
                ]],
                [AUILabel text: [OFString stringWithFormat: @"Current query: %@", searchSummary]
                          style: self.class.bodyTextStyle],
                [AUIProgressBar progress: progress variant: tone],
                [AUIHStack gap: 10 children: @[
                    [AUIButton title: @"Clear draft"
                             variant: AUIControlVariantNeutral
                                size: AUIControlSizeSmall
                             enabled: (draftLabel.length > 0)
                             onPress: ^{
                                 _draftLabel.value = @"";
                             }],
                    [AUIButton title: @"Inject tick"
                             variant: AUIControlVariantSecondary
                                size: AUIControlSizeSmall
                             enabled: true
                             onPress: ^{
                                 _tickCount.value = @(tickCount + 5);
                             }]
                ]]
            ]]
        ]]];
    }

    return [AUIBox layout: (AUILayout){
                        .width = [AUI axisGrow: 0],
                        .height = [AUI axisGrow: 0],
                        .padding = [AUI insetsAll: 24],
                        .childGap = 0,
                        .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                        .direction = AUILayoutDirectionColumn
                    }
               background: [AUI colorWithRed: 245 green: 241 blue: 233 alpha: 255]
                   radius: 0
                   border: AUI.borderNone
                 children: @[
        [AUIFrame width: [AUI axisGrow: 0]
                 height: [AUI axisGrow: 0]
                  child: [AUIScrollView axis: AUIScrollAxisVertical
                                       child: [AUIVStack gap: 18 children: content]]]
    ]];
}

- (void)mountInScope: (AsyncScope *)scope
{
    (void)scope;
}

- (void)unmount
{
}

@end

@interface App : AUIApplication @end

@implementation App

- (AUIComponent *)makeRootComponent
{
    return [[AppRootComponent alloc] init];
}

@end

#pragma clang assume_nonnull end

ASYNC_APPLICATION_DELEGATE(App);
