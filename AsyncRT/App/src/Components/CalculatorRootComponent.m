#import "CalculatorComponentSupport.h"

#pragma clang assume_nonnull begin

@interface CalculatorRootComponent ()

- (void)_setNeedsViewUpdateForAllCalculatorPanels [[direct]];

@end

@implementation CalculatorRootComponent {
    CalculatorModel *_model;
    CalculatorHeaderComponent *_headerComponent;
    CalculatorDisplayComponent *_displayComponent;
    CalculatorKeypadComponent *_keypadComponent;
    CalculatorSidebarComponent *_sidebarComponent;
}

- (instancetype)init
{
    self = [super init];
    _model = [[CalculatorModel alloc] init];
    _headerComponent = [[CalculatorHeaderComponent alloc] initWithModel: _model];
    _displayComponent = [[CalculatorDisplayComponent alloc] initWithModel: _model];
    _keypadComponent = [[CalculatorKeypadComponent alloc] initWithModel: _model];
    _sidebarComponent = [[CalculatorSidebarComponent alloc] initWithModel: _model];
    return self;
}

- (AUIView *)renderView
{
    AUIBoxProps props = AUI.defaultBoxProps;

    props.layout.width = [AUI axisGrow: 0];
    props.layout.height = [AUI axisGrow: 0];
    props.layout.padding = [AUI insetsAll: 28];
    props.layout.childGap = 22;
    props.layout.direction = AUILayoutDirectionColumn;
    props.backgroundColor = [CalculatorTheme canvasColor];

    return [AUIViewBox boxWithKey: @"calculator-root"
                         boxProps: props
           interactionConfiguration: nilptr
                         children: @[
        [self renderChildViewComponent: _headerComponent key: @"header"],
        [CalculatorViews rowWithKey: @"content-row" gap: 20 children: @[
            [CalculatorViews boxWithKey: @"main-column"
                                  props: (AUIBoxProps){
                                      .layout = (AUILayout){
                                          .width = [AUI axisGrow: 0],
                                          .height = [AUI axisGrow: 0],
                                          .padding = [AUI insetsAll: 0],
                                          .childGap = 18,
                                          .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                                          .direction = AUILayoutDirectionColumn
                                      },
                                      .backgroundColor = [AUI colorWithRed: 0 green: 0 blue: 0 alpha: 0],
                                      .cornerRadius = 0,
                                      .border = [AUI borderNone],
                                      .scrollAxis = AUIScrollAxisNone
                                  }
                               children: @[
                [self renderChildViewComponent: _displayComponent key: @"display"],
                [self renderChildViewComponent: _keypadComponent key: @"keypad"]
            ]],
            [CalculatorViews fixedWidthWithKey: @"sidebar-frame"
                                         width: 340
                                         child: [self renderChildViewComponent: _sidebarComponent key: @"sidebar"]]
        ]]
    ]];
}

- (void)_setNeedsViewUpdateForAllCalculatorPanels
{
    [_headerComponent setNeedsViewUpdate];
    [_displayComponent setNeedsViewUpdate];
    [_keypadComponent setNeedsViewUpdate];
    [_sidebarComponent setNeedsViewUpdate];
    [self setNeedsViewUpdate];
}

@end

@implementation AUIViewComponent (CalculatorSharedModelRefresh)

- (void)_refreshCalculatorInterfaceAfterSharedModelMutation
{
    if ([self.parentViewComponent isKindOfClass: CalculatorRootComponent.class]) {
        [((CalculatorRootComponent *)self.parentViewComponent) _setNeedsViewUpdateForAllCalculatorPanels];
        return;
    }

    [self setNeedsViewUpdate];
}

@end

#pragma clang assume_nonnull end
