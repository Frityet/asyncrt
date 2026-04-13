#include <cairo.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

#import "TestSupport.h"
#import "UI/UI.h"
#import "UI/AUIClaySupport.h"
#import "UI/AUIInternal.h"
#import "UI/Backend/AUICairoRenderSupport.h"
#import "UI/Backend/Window/AUIHeadlessWindow.h"
#import "UI/Components/AUIComponents.h"
#import "UI/Components/Controls/AUIControls.h"
#import "UI/Components/Display/AUIDisplay.h"
#import "UI/Components/Forms/AUIForms.h"
#import "UI/Components/Layout/AUILayout.h"
#import "UI/Components/Surface/AUISurface.h"
#import "Async/AsyncSignal.h"

#if AUI_HAS_CORE_GRAPHICS_WINDOW
@interface AUICoreGraphicsWindow (AUITestingBridge)
+ (bool)_prepareSharedApplicationForTesting;
+ (bool)_sharedApplicationIsForegroundForTesting;
+ (bool)_sharedApplicationIsActiveForTesting;
+ (bool)_sharedApplicationHasMainMenuForTesting;
+ (size_t)_sharedApplicationWindowCountForTesting;
+ (OFString *nillable)_roundTripBridgedStringForTesting: (OFString *nillable)string;
- (void)_performCloseForTesting;
- (void)_sendPointerMoveForTestingWithViewX: (float)x y: (float)y;
- (void)_sendMouseDownForTestingWithViewX: (float)x y: (float)y;
- (void)_sendMouseUpForTestingWithViewX: (float)x y: (float)y;
- (bool)_windowIsVisibleForTesting;
- (bool)_windowIsKeyForTesting;
- (bool)_windowIsMainForTesting;
- (bool)_renderViewIsFirstResponderForTesting;
@end
#endif

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AUITestComponent : AUIComponent

@property(readonly, nonatomic) size_t mountCount;
@property(readonly, nonatomic) size_t unmountCount;

@end

@implementation AUITestComponent {
    size_t _mountCount;
    size_t _unmountCount;
}

@synthesize mountCount = _mountCount;
@synthesize unmountCount = _unmountCount;

- (void)mountInScope: (AsyncScope *)scope
{
    (void)scope;
    _mountCount++;
}

- (void)unmount
{
    _unmountCount++;
}

@end

[[subclassing_restricted]]
@interface AUITestGroupComponent : AUITestComponent

@property(copy, nonatomic) OFArray<id<AUIRenderable>> *bodyChildren;

@end

@implementation AUITestGroupComponent {
    OFArray<id<AUIRenderable>> *_bodyChildren;
}

@synthesize bodyChildren = _bodyChildren;

- (instancetype)init
{
    self = [super init];
    _bodyChildren = [OFArray array];
    return self;
}

- (void)setBodyChildren: (OFArray<id<AUIRenderable>> *)bodyChildren
{
    _bodyChildren = [bodyChildren copy];
}

- (id<AUIRenderable>)body
{
    return [AUIGroup children: _bodyChildren];
}

@end

[[subclassing_restricted]]
@interface AUITestSignalComponent : AUIComponent

@property(readonly, nonatomic) Signal<OFString *> *signal;

- (instancetype)initWithSignal: (Signal<OFString *> *nillable)signal [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@implementation AUITestSignalComponent {
    Signal<OFString *> *_signal;
}

@synthesize signal = _signal;

- (instancetype)initWithSignal: (Signal<OFString *> *nillable)signal
{
    if (signal == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _signal = signal;
    return self;
}

- (id<AUIRenderable>)body
{
    (void)_signal.value;
    return [AUIGroup children: @[]];
}

@end

[[subclassing_restricted]]
@interface AUITestAsyncSignalComponent : AUIComponent

@property(readonly, nonatomic) AsyncSignal<OFString *> *signal;

- (instancetype)initWithSignal: (AsyncSignal<OFString *> *nillable)signal [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@implementation AUITestAsyncSignalComponent {
    AsyncSignal<OFString *> *_signal;
}

@synthesize signal = _signal;

- (instancetype)initWithSignal: (AsyncSignal<OFString *> *nillable)signal
{
    if (signal == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _signal = signal;
    return self;
}

- (id<AUIRenderable>)body
{
    (void)_signal.value;
    return [AUIGroup children: @[]];
}

@end

[[subclassing_restricted]]
@interface AUITestAsyncRenderLoopComponent : AUIComponent

@property(readonly, nonatomic) uint32_t lastRenderedPhase;

@end

@implementation AUITestAsyncRenderLoopComponent {
    Signal<OFNumber *> *_phase;
    uint32_t _lastRenderedPhase;
}

@synthesize lastRenderedPhase = _lastRenderedPhase;

- (instancetype)init
{
    self = [super init];
    _phase = [Signal withValue: @0];
    _lastRenderedPhase = 0;
    return self;
}

- (void)mountInScope: (AsyncScope *)scope
{
    [scope spawn: ^{
        [[scope.scheduler sleepForTimeInterval: 0.08] await];
        _phase.value = @1;
        [[scope.scheduler sleepForTimeInterval: 0.08] await];
        _phase.value = @2;
        return AsyncUnit.unit;
    } name: @"ui-test-async-render-loop"];
}

- (id<AUIRenderable>)body
{
    uint32_t phase = _phase.value.unsignedIntValue;

    _lastRenderedPhase = phase;
    return [AUILabel text: [OFString stringWithFormat: @"phase %u", phase]];
}

@end

[[subclassing_restricted]]
@interface AUITestCatalogComponent : AUIComponent @end

@implementation AUITestCatalogComponent

- (id<AUIRenderable>)body
{
    return [AUIBox layout: (AUILayout){
                        .width = [AUI axisGrow: 0],
                        .height = [AUI axisGrow: 0],
                        .padding = [AUI insetsAll: 18],
                        .childGap = 0,
                        .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                        .direction = AUILayoutDirectionColumn
                    }
               background: [AUI colorWithRed: 250 green: 247 blue: 241 alpha: 255]
                   radius: 0
                   border: [AUI borderNone]
                 children: @[
        [AUIVStack gap: 14 children: @[
            [AUICard children: @[
                [AUISection title: @"Overview" children: @[
                    [AUILabel text: @"Catalog smoke test"],
                    [AUIHStack gap: 8 children: @[
                        [AUIBadge text: @"beta" variant: AUIControlVariantPrimary],
                        [AUIBadge text: @"stable" variant: AUIControlVariantSecondary]
                    ]],
                    [AUIProgressBar progress: 0.65f variant: AUIControlVariantPrimary]
                ]],
                [AUIHStack gap: 10 children: @[
                    [AUIButton title: @"Primary"
                              variant: AUIControlVariantPrimary
                                 size: AUIControlSizeMedium
                              enabled: true
                              onPress: nilptr],
                    [AUIIconButton icon: @"+"
                                 variant: AUIControlVariantSecondary
                                    size: AUIControlSizeMedium
                                 enabled: true
                                 onPress: nilptr]
                ]],
                [AUIVStack gap: 8 children: @[
                    [AUIToggle label: @"Toggle" checked: true enabled: true onChange: nilptr],
                    [AUICheckbox label: @"Checkbox" checked: false enabled: true onChange: nilptr],
                    [AUIRadioGroup options: @[ @"One", @"Two" ] selectedIndex: 1 onChange: nilptr],
                    [AUITextField text: @"hello" placeholder: @"Text" enabled: true onChange: nilptr onSubmit: nilptr],
                    [AUISecureField text: @"secret" placeholder: @"Password" enabled: true onChange: nilptr onSubmit: nilptr],
                    [AUISearchField text: @"query" placeholder: @"Search" enabled: true onChange: nilptr onSubmit: nilptr]
                ]]
            ]]
        ]]
    ]];
}

@end

[[subclassing_restricted]]
@interface AUITestFixedSizeRootComponent : AUIComponent @end

@implementation AUITestFixedSizeRootComponent

- (id<AUIRenderable>)body
{
    return [AUIFrame width: [AUI axisFixed: 180]
                     height: [AUI axisFixed: 60]
                      child: [AUILabel text: @"Auto sized"]];
}

@end

[[subclassing_restricted]]
@interface AUITestDarkModeComponent : AUIComponent

@property(readonly, nonatomic) bool observedDarkMode;

@end

@implementation AUITestDarkModeComponent {
    bool _observedDarkMode;
}

@synthesize observedDarkMode = _observedDarkMode;

- (id<AUIRenderable>)body
{
    AUIRenderContext *nillable context = AUIRenderContext.currentContext;

    _observedDarkMode = (context != nilptr and context.window.isDarkMode);
    return [AUILabel text: @"Dark mode"];
}

@end

[[subclassing_restricted]]
@interface AUITestButtonComponent : AUIComponent

@property(readonly, nonatomic) size_t pressCount;

@end

@implementation AUITestButtonComponent {
    size_t _pressCount;
}

@synthesize pressCount = _pressCount;

- (id<AUIRenderable>)body
{
    return [AUIBox layout: (AUILayout){
                        .width = [AUI axisGrow: 0],
                        .height = [AUI axisGrow: 0],
                        .padding = [AUI insetsAll: 20],
                        .childGap = 0,
                        .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                        .direction = AUILayoutDirectionColumn
                    }
               background: [AUI colorWithRed: 255 green: 255 blue: 255 alpha: 255]
                   radius: 0
                   border: AUI.borderNone
                 children: @[
        [AUIButton title: @"Press"
                  variant: AUIControlVariantPrimary
                     size: AUIControlSizeMedium
                  enabled: true
                  onPress: ^{
                      _pressCount++;
                  }]
    ]];
}

@end

[[subclassing_restricted]]
@interface AUITestToggleComponent : AUIComponent

@property(readonly, nonatomic) bool isChecked;

@end

@implementation AUITestToggleComponent {
    bool _checked;
}

@synthesize isChecked = _checked;

- (id<AUIRenderable>)body
{
    return [AUIBox layout: (AUILayout){
                        .width = [AUI axisGrow: 0],
                        .height = [AUI axisGrow: 0],
                        .padding = [AUI insetsAll: 20],
                        .childGap = 0,
                        .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                        .direction = AUILayoutDirectionColumn
                    }
               background: [AUI colorWithRed: 255 green: 255 blue: 255 alpha: 255]
                   radius: 0
                   border: AUI.borderNone
                 children: @[
        [AUIToggle label: @"Airplane mode"
                  checked: _checked
                  enabled: true
                 onChange: ^(bool value) {
                     _checked = value;
                 }]
    ]];
}

@end

[[subclassing_restricted]]
@interface AUITestRadioComponent : AUIComponent

@property(readonly, nonatomic) size_t selectedIndex;

@end

@implementation AUITestRadioComponent {
    size_t _selectedIndex;
}

@synthesize selectedIndex = _selectedIndex;

- (id<AUIRenderable>)body
{
    return [AUIBox layout: (AUILayout){
                        .width = [AUI axisGrow: 0],
                        .height = [AUI axisGrow: 0],
                        .padding = [AUI insetsAll: 20],
                        .childGap = 0,
                        .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                        .direction = AUILayoutDirectionColumn
                    }
               background: [AUI colorWithRed: 255 green: 255 blue: 255 alpha: 255]
                   radius: 0
                   border: AUI.borderNone
                 children: @[
        [AUIRadioGroup options: @[ @"One", @"Two", @"Three" ]
                  selectedIndex: _selectedIndex
                       onChange: ^(size_t index) {
                           _selectedIndex = index;
                       }]
    ]];
}

@end

[[subclassing_restricted]]
@interface AUITestTextFieldComponent : AUIComponent

@property(readonly, copy, nonatomic) OFString *text;
@property(readonly, nonatomic) size_t submitCount;

@end

@implementation AUITestTextFieldComponent {
    OFString *_text;
    size_t _submitCount;
}

@synthesize text = _text;
@synthesize submitCount = _submitCount;

- (instancetype)init
{
    self = [super init];
    _text = @"";
    return self;
}

- (id<AUIRenderable>)body
{
    return [AUIBox layout: (AUILayout){
                        .width = [AUI axisGrow: 0],
                        .height = [AUI axisGrow: 0],
                        .padding = [AUI insetsAll: 20],
                        .childGap = 0,
                        .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                        .direction = AUILayoutDirectionColumn
                    }
               background: [AUI colorWithRed: 255 green: 255 blue: 255 alpha: 255]
                   radius: 0
                   border: AUI.borderNone
                 children: @[
        [AUITextField text: _text
                 placeholder: @"Type"
                     enabled: true
                    onChange: ^(OFString *value) {
                        _text = [value copy];
                    }
                    onSubmit: ^(OFString *value) {
                        (void)value;
                        _submitCount++;
                    }]
    ]];
}

@end

[[subclassing_restricted]]
@interface AUITestTwoFieldComponent : AUIComponent

@property(readonly, copy, nonatomic) OFString *first;
@property(readonly, copy, nonatomic) OFString *second;

@end

@implementation AUITestTwoFieldComponent {
    OFString *_first;
    OFString *_second;
}

@synthesize first = _first;
@synthesize second = _second;

- (instancetype)init
{
    self = [super init];
    _first = @"";
    _second = @"";
    return self;
}

- (id<AUIRenderable>)body
{
    return [AUIBox layout: (AUILayout){
                        .width = [AUI axisGrow: 0],
                        .height = [AUI axisGrow: 0],
                        .padding = [AUI insetsAll: 20],
                        .childGap = 12,
                        .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                        .direction = AUILayoutDirectionColumn
                    }
               background: [AUI colorWithRed: 255 green: 255 blue: 255 alpha: 255]
                   radius: 0
                   border: [AUI borderNone]
                 children: @[
        [AUITextField text: _first
                 placeholder: @"First"
                     enabled: true
                    onChange: ^(OFString *value) {
                        _first = [value copy];
                    }
                    onSubmit: nilptr],
        [AUITextField text: _second
                 placeholder: @"Second"
                     enabled: true
                    onChange: ^(OFString *value) {
                        _second = [value copy];
                    }
                    onSubmit: nilptr]
    ]];
}

@end

[[subclassing_restricted]]
@interface AUITestTextAreaComponent : AUIComponent

@property(readonly, copy, nonatomic) OFString *text;

@end

@implementation AUITestTextAreaComponent {
    OFString *_text;
}

@synthesize text = _text;

- (instancetype)init
{
    self = [super init];
    _text = @"";
    return self;
}

- (id<AUIRenderable>)body
{
    return [AUIBox layout: (AUILayout){
                        .width = [AUI axisGrow: 0],
                        .height = [AUI axisGrow: 0],
                        .padding = [AUI insetsAll: 20],
                        .childGap = 0,
                        .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                        .direction = AUILayoutDirectionColumn
                    }
               background: [AUI colorWithRed: 255 green: 255 blue: 255 alpha: 255]
                   radius: 0
                   border: [AUI borderNone]
                 children: @[
        [AUITextArea text: _text
                 placeholder: @"Notes"
                     enabled: true
                    onChange: ^(OFString *value) {
                        _text = [value copy];
                    }
                    onSubmit: nilptr]
    ]];
}

@end

[[subclassing_restricted]]
@interface AUITestSecureFieldComponent : AUIComponent @end

@implementation AUITestSecureFieldComponent

- (id<AUIRenderable>)body
{
    return [AUISecureField text: @"secret"
                    placeholder: @"Password"
                        enabled: true
                       onChange: nilptr
                       onSubmit: nilptr];
}

@end

[[subclassing_restricted]]
@interface AUITestScrollComponent : AUIComponent @end

@implementation AUITestScrollComponent

- (id<AUIRenderable>)body
{
    OFMutableArray<id<AUIRenderable>> *rows = [OFMutableArray array];

    for (size_t index = 0; index < 8; index++) {
        [rows addObject: [AUIBox layout: (AUILayout){
                                    .width = [AUI axisGrow: 0],
                                    .height = [AUI axisFixed: 24],
                                    .padding = [AUI insetsWithLeft: 8 right: 8 top: 4 bottom: 4],
                                    .childGap = 0,
                                    .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentCenter],
                                    .direction = AUILayoutDirectionColumn
                                }
                         background: [AUI colorWithRed: 240 green: 242 blue: 245 alpha: 255]
                             radius: 6
                             border: [AUI borderNone]
                           children: @[
            [AUIText format: @"Row %zu", index]
        ]]];
    }

    return [AUIBox layout: (AUILayout){
                        .width = [AUI axisGrow: 0],
                        .height = [AUI axisGrow: 0],
                        .padding = [AUI insetsAll: 20],
                        .childGap = 0,
                        .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                        .direction = AUILayoutDirectionColumn
                    }
               background: [AUI colorWithRed: 255 green: 255 blue: 255 alpha: 255]
                   radius: 0
                   border: [AUI borderNone]
                 children: @[
        [AUIFrame width: [AUI axisFixed: 180]
                 height: [AUI axisFixed: 60]
                  child: [AUIScrollView axis: AUIScrollAxisVertical
                                          child: [AUIVStack gap: 6 children: rows]]]
    ]];
}

@end

[[subclassing_restricted]]
@interface AUITestStableFocusComponent : AUIComponent

@property(readonly, copy, nonatomic) OFString *text;
@property(readonly, nonatomic) size_t tick;

- (void)advanceTick;

@end

@implementation AUITestStableFocusComponent {
    OFString *_text;
    size_t _tick;
}

@synthesize text = _text;
@synthesize tick = _tick;

- (instancetype)init
{
    self = [super init];
    _text = @"";
    return self;
}

- (void)advanceTick
{
    _tick++;
}

- (id<AUIRenderable>)body
{
    return [AUIBox layout: (AUILayout){
                        .width = [AUI axisGrow: 0],
                        .height = [AUI axisGrow: 0],
                        .padding = [AUI insetsAll: 20],
                        .childGap = 12,
                        .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                        .direction = AUILayoutDirectionColumn
                    }
               background: [AUI colorWithRed: 255 green: 255 blue: 255 alpha: 255]
                   radius: 0
                   border: [AUI borderNone]
                 children: @[
        [AUILabel text: [OFString stringWithFormat: @"tick %zu", _tick]],
        [AUITextField text: _text
                 placeholder: @"Stable"
                     enabled: true
                    onChange: ^(OFString *value) {
                        _text = [value copy];
                    }
                    onSubmit: nilptr]
    ]];
}

@end

[[subclassing_restricted]]
@interface AUITestClipboardComponent : AUIComponent

@property(readonly, copy, nonatomic) OFString *first;
@property(readonly, copy, nonatomic) OFString *second;

@end

@implementation AUITestClipboardComponent {
    OFString *_first;
    OFString *_second;
}

@synthesize first = _first;
@synthesize second = _second;

- (instancetype)init
{
    self = [super init];
    _first = @"alpha";
    _second = @"";
    return self;
}

- (id<AUIRenderable>)body
{
    return [AUIBox layout: (AUILayout){
                        .width = [AUI axisGrow: 0],
                        .height = [AUI axisGrow: 0],
                        .padding = [AUI insetsAll: 20],
                        .childGap = 12,
                        .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                        .direction = AUILayoutDirectionColumn
                    }
               background: [AUI colorWithRed: 255 green: 255 blue: 255 alpha: 255]
                   radius: 0
                   border: [AUI borderNone]
                 children: @[
        [AUITextField text: _first
                 placeholder: @"First"
                     enabled: true
                    onChange: ^(OFString *value) {
                        _first = [value copy];
                    }
                    onSubmit: nilptr],
        [AUITextField text: _second
                 placeholder: @"Second"
                     enabled: true
                    onChange: ^(OFString *value) {
                        _second = [value copy];
                    }
                    onSubmit: nilptr]
    ]];
}

@end

[[subclassing_restricted]]
@interface AUITestContextMenuComponent : AUIComponent

@property(readonly, nonatomic) size_t selectionCount;

@end

@implementation AUITestContextMenuComponent {
    size_t _selectionCount;
}

@synthesize selectionCount = _selectionCount;

- (id<AUIRenderable>)body
{
    return [AUIBox layout: (AUILayout){
                        .width = [AUI axisGrow: 0],
                        .height = [AUI axisGrow: 0],
                        .padding = [AUI insetsAll: 20],
                        .childGap = 0,
                        .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                        .direction = AUILayoutDirectionColumn
                    }
               background: [AUI colorWithRed: 255 green: 255 blue: 255 alpha: 255]
                   radius: 0
                   border: [AUI borderNone]
                 children: @[
        [AUIContextMenuRegion child: [AUIButton title: @"Open menu"
                                                   variant: AUIControlVariantSecondary
                                                      size: AUIControlSizeMedium
                                                   enabled: true
                                                   onPress: nilptr]
                                   menu: [AUIContextMenu items: @[
            [AUIContextMenuItem title: @"Inspect"
                              enabled: true
                             onSelect: ^{
                                 _selectionCount++;
                             }]
        ]]]
    ]];
}

@end

static char *_Nonnull AUITestSpyWindowFonts[] = {
    (char *)"Sans"
};

[[subclassing_restricted]]
@interface AUITestSpyWindow : AUIWindow

@property(nonatomic) bool failOpen;
@property(nonatomic) bool closeAfterNextRender;
@property(nonatomic) size_t closeAfterRenderCount;
@property(readonly, nonatomic) size_t openCount;
@property(readonly, nonatomic) size_t pollCount;
@property(readonly, nonatomic) size_t closeCount;
@property(readonly, nonatomic) size_t renderCount;
@property(readonly, nonatomic) size_t resizeCount;
@property(readonly, nonatomic) AUICursorStyle cursorStyle;

@end

@implementation AUITestSpyWindow {
    bool _open;
    bool _failOpen;
    bool _closeAfterNextRender;
    size_t _closeAfterRenderCount;
    size_t _openCount;
    size_t _pollCount;
    size_t _closeCount;
    size_t _renderCount;
    size_t _resizeCount;
    AUISize _viewportSize;
    AUICursorStyle _cursorStyle;
    OFString *nillable _clipboardText;
    cairo_surface_t *nillable _surface;
    cairo_t *nillable _cairo;
    unsigned char *nillable _bytes;
}

@synthesize failOpen = _failOpen;
@synthesize closeAfterNextRender = _closeAfterNextRender;
@synthesize closeAfterRenderCount = _closeAfterRenderCount;
@synthesize openCount = _openCount;
@synthesize pollCount = _pollCount;
@synthesize closeCount = _closeCount;
@synthesize renderCount = _renderCount;
@synthesize resizeCount = _resizeCount;
@synthesize cursorStyle = _cursorStyle;

- (instancetype)initWithApplication: (AUIApplication *nillable)application
                            options: (AUIWindowOptions *nillable)options
{
    self = [super initWithApplication: application options: options];
    _open = false;
    _failOpen = false;
    _closeAfterNextRender = false;
    _closeAfterRenderCount = 0;
    _openCount = 0;
    _pollCount = 0;
    _closeCount = 0;
    _renderCount = 0;
    _resizeCount = 0;
    _viewportSize = $assert_nonnil(options).initialSize;
    _cursorStyle = AUICursorStyleDefault;
    _clipboardText = nilptr;
    _surface = nullptr;
    _cairo = nullptr;
    _bytes = nullptr;
    return self;
}

- (void)dealloc
{
    [self closeWindow];
}

- (bool)isOpen
{
    return _open;
}

- (AUISize)viewportSize
{
    return _viewportSize;
}

- (double)scaleFactor
{
    return 1.0;
}

- (void)openWindow
{
    _openCount++;

    if (_failOpen)
        @throw [[AUIInitializationException alloc] initWithReason: @"Spy window failed to open"];

    _open = true;
}

- (void)pollEvents
{
    _pollCount++;
}

- (void)closeWindow
{
    _closeCount++;
    _open = false;

    if (_cairo != nullptr) {
        cairo_destroy(_cairo);
        _cairo = nullptr;
    }

    if (_surface != nullptr) {
        cairo_surface_destroy(_surface);
        _surface = nullptr;
    }

    if (_bytes != nullptr) {
        free(_bytes);
        _bytes = nullptr;
    }
}

- (void)setCursorStyle: (AUICursorStyle)cursorStyle
{
    _cursorStyle = cursorStyle;
}

- (OFString *nillable)clipboardText
{
    return _clipboardText;
}

- (void)setClipboardText: (OFString *nillable)text
{
    _clipboardText = [text copy];
}

- (bool)_ensureSurface
{
    int width = (int)_viewportSize.width;
    int height = (int)_viewportSize.height;
    int stride;

    if (width <= 0 or height <= 0)
        return false;

    if (_surface != nullptr and cairo_image_surface_get_width($assert_nonnil(_surface)) == width and
        cairo_image_surface_get_height($assert_nonnil(_surface)) == height)
        return true;

    if (_cairo != nullptr) {
        cairo_destroy(_cairo);
        _cairo = nullptr;
    }

    if (_surface != nullptr) {
        cairo_surface_destroy(_surface);
        _surface = nullptr;
    }

    if (_bytes != nullptr) {
        free(_bytes);
        _bytes = nullptr;
    }

    stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
    if (stride <= 0)
        return false;

    _bytes = calloc((size_t)height, (size_t)stride);
    if (_bytes == nullptr)
        return false;

    _surface = cairo_image_surface_create_for_data(_bytes,
                                                   CAIRO_FORMAT_ARGB32,
                                                   width,
                                                   height,
                                                   stride);
    if (cairo_surface_status($assert_nonnil(_surface)) != CAIRO_STATUS_SUCCESS)
        return false;

    _cairo = cairo_create($assert_nonnil(_surface));
    if (cairo_status($assert_nonnil(_cairo)) != CAIRO_STATUS_SUCCESS)
        return false;

    return true;
}

- (void)_setViewportSize: (AUISize)viewportSize
{
    _resizeCount++;
    _viewportSize = viewportSize;
}

- (void)renderFrame
{
    AUICairoTextMeasureContext measureContext;
    Clay_RenderCommandArray commands;

    if (not _open or not [self _ensureSurface])
        return;

    _renderCount++;

    cairo_save($assert_nonnil(_cairo));
    @try {
        cairo_set_operator($assert_nonnil(_cairo), CAIRO_OPERATOR_SOURCE);
        cairo_set_source_rgba($assert_nonnil(_cairo), 0.0, 0.0, 0.0, 0.0);
        cairo_paint($assert_nonnil(_cairo));
        measureContext = (AUICairoTextMeasureContext){
            .context = $assert_nonnil(_cairo),
            .fonts = AUITestSpyWindowFonts
        };
        commands = [self _buildRenderCommandsForViewportSize: _viewportSize
                                         textMeasureFunction: AUICairoMeasureText
                                                    userData: &measureContext];
        [AUICairoRenderSupport renderCommands: commands
                                    onContext: $assert_nonnil(_cairo)
                                        fonts: AUITestSpyWindowFonts];
        cairo_surface_flush($assert_nonnil(_surface));
    } @finally {
        cairo_restore($assert_nonnil(_cairo));
    }

    if (_closeAfterNextRender or (_closeAfterRenderCount > 0 and _renderCount >= _closeAfterRenderCount))
        _open = false;
}

@end

[[subclassing_restricted]]
@interface AUITestLifecycleApplication : AUIApplication

@property(retain, nonatomic) AUIComponent *nillable providedRootComponent;
@property(retain, nonatomic) AUIWindow *nillable providedWindow;

@end

@implementation AUITestLifecycleApplication {
    AUIComponent *nillable _providedRootComponent;
    AUIWindow *nillable _providedWindow;
}

@synthesize providedRootComponent = _providedRootComponent;
@synthesize providedWindow = _providedWindow;

- (AUIWindowOptions *)windowOptions
{
    return [AUIWindowOptions title: @"Lifecycle Test"
                              size: (AUISize){ 200, 120 }
                         resizable: true];
}

- (AUIComponent *)makeRootComponent
{
    return _providedRootComponent;
}

- (AUIWindow *)makeWindow
{
    return _providedWindow;
}

@end

[[subclassing_restricted]]
@interface AUITestApplication : AUIApplication @end

@interface AUITestApplication ()

@property(readonly, nonatomic) AUIHeadlessWindow *headlessWindow;

- (AUIWindow *)ensureWindowWithWidth: (float)width height: (float)height;
- (void)disposeWindow;

@end

@implementation AUITestApplication {
    AUIHeadlessWindow *_headlessWindow;
}

@synthesize headlessWindow = _headlessWindow;

- (AUIWindowOptions *)windowOptions
{
    return [AUIWindowOptions title: @"Test UI"
                              size: (AUISize){ 320, 240 }
                         resizable: true];
}

- (AUIComponent *)makeRootComponent
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (AUIWindow *)ensureWindowWithWidth: (float)width height: (float)height
{
    if (_headlessWindow == nilptr) {
        AUIWindowOptions *options = [AUIWindowOptions title: @"Test UI"
                                                       size: (AUISize){ width, height }
                                                  resizable: true];

        _headlessWindow = [[AUIHeadlessWindow alloc] initWithApplication: self options: options];
        [self _setWindowForTesting: _headlessWindow];
        [_headlessWindow openWindow];
    }

    [_headlessWindow setViewportSize: (AUISize){ width, height }];
    return _headlessWindow;
}

- (void)disposeWindow
{
    if (_headlessWindow != nilptr)
        [_headlessWindow closeWindow];

    [self _setWindowForTesting: nilptr];
    _headlessWindow = nilptr;
}

@end

typedef struct AUITestSurface {
    cairo_surface_t *surface;
    cairo_t *cairo;
    unsigned char *bytes;
    int width;
    int height;
    int stride;
} AUITestSurface;

static Clay_Dimensions AUITestMeasureText(Clay_StringSlice text,
                                          Clay_TextElementConfig *config,
                                          void *userData)
{
    (void)config;
    (void)userData;
    return (Clay_Dimensions){
        .width = (float)text.length * 8.0f,
        .height = 16.0f
    };
}

static AUITestSurface AUITestSurfaceMake(int width, int height)
{
    AUITestSurface result = {0};

    result.width = width;
    result.height = height;
    result.stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
    result.bytes = calloc((size_t)height, (size_t)result.stride);
    result.surface = cairo_image_surface_create_for_data(result.bytes,
                                                         CAIRO_FORMAT_ARGB32,
                                                         width,
                                                         height,
                                                         result.stride);
    result.cairo = cairo_create(result.surface);
    return result;
}

static void AUITestSurfaceDestroy(AUITestSurface *surface)
{
    if (surface->cairo != nullptr) {
        cairo_destroy(surface->cairo);
        surface->cairo = nullptr;
    }

    if (surface->surface != nullptr) {
        cairo_surface_destroy(surface->surface);
        surface->surface = nullptr;
    }

    if (surface->bytes != nullptr) {
        free(surface->bytes);
        surface->bytes = nullptr;
    }
}

static void AUITestAttachAndMountRoot(AUITestApplication *app, AUIComponent *root, AsyncScope *rootScope)
{
    [app _setRootComponentForTesting: root];
    [root _attachToApplication: app parent: nilptr];
    [root _mountRecursivelyInScope: rootScope];
}

static void AUITestDetachAndUnmountRoot(AUITestApplication *app, AUIComponent *root)
{
    [root _unmountRecursively];
    [root _detachFromApplication];
    [app _setRootComponentForTesting: nilptr];
    [app disposeWindow];
}

static void AUITestRenderApplication(AUITestApplication *app, float width, float height)
{
    AUIWindow *window = [app ensureWindowWithWidth: width height: height];

    [app setNeedsRender];
    [window renderFrame];
}

static Clay_RenderCommandArray AUITestRenderCommandsForMountedComponent(AUIComponent *root,
                                                                        size_t *memorySizeOut,
                                                                        void **memoryOut)
{
    size_t memorySize = Clay_MinMemorySize();
    void *memory = malloc(memorySize);
    Clay_Arena arena = Clay_CreateArenaWithCapacityAndMemory(memorySize, memory);

    [AUIClay clearError];
    Clay_Initialize(arena, (Clay_Dimensions){ .width = 360.0f, .height = 240.0f }, [AUIClay errorHandler]);
    Clay_SetMeasureTextFunction(AUITestMeasureText, nilptr);
    Clay_BeginLayout();
    [root _renderRecursively];

    if (memorySizeOut != nullptr)
        *memorySizeOut = memorySize;
    if (memoryOut != nullptr)
        *memoryOut = memory;
    return Clay_EndLayout(1.0f / 60.0f);
}

static OFString *AUITestStringFromSlice(Clay_StringSlice slice)
{
    char *buffer = calloc((size_t)slice.length + 1, sizeof(char));
    OFString *string;

    memcpy(buffer, slice.chars, (size_t)slice.length);
    string = [[OFString alloc] initWithUTF8String: buffer];
    free(buffer);
    return string;
}

static OFString *nillable AUITestFirstRenderedTextString(Clay_RenderCommandArray commands)
{
    for (int32_t index = 0; index < commands.length; index++) {
        Clay_RenderCommand *command = Clay_RenderCommandArray_Get(&commands, index);

        if (command->commandType == CLAY_RENDER_COMMAND_TYPE_TEXT)
            return AUITestStringFromSlice(command->renderData.text.stringContents);
    }

    return nilptr;
}

static void AUITestClick(AUITestApplication *app, float x, float y)
{
    [app ensureWindowWithWidth: 320 height: 240];
    [app.headlessWindow sendPointerMoveToX: x y: y];
    AUITestRenderApplication(app, 320, 240);

    [app.headlessWindow sendMouseDown: AUIMouseButtonPrimary];
    AUITestRenderApplication(app, 320, 240);

    [app.headlessWindow sendPointerMoveToX: x y: y];
    [app.headlessWindow sendMouseUp: AUIMouseButtonPrimary];
    AUITestRenderApplication(app, 320, 240);
}

static void AUITestSecondaryClick(AUITestApplication *app, float x, float y)
{
    [app ensureWindowWithWidth: 320 height: 240];
    [app.headlessWindow sendPointerMoveToX: x y: y];
    AUITestRenderApplication(app, 320, 240);

    [app.headlessWindow sendMouseDown: AUIMouseButtonSecondary];
    AUITestRenderApplication(app, 320, 240);

    [app.headlessWindow sendPointerMoveToX: x y: y];
    [app.headlessWindow sendMouseUp: AUIMouseButtonSecondary];
    AUITestRenderApplication(app, 320, 240);
}

static void AUITestTypeASCII(AUITestApplication *app, const char *text)
{
    [app ensureWindowWithWidth: 320 height: 240];
    [app.headlessWindow sendText: [OFString stringWithUTF8String: text]];

    AUITestRenderApplication(app, 320, 240);
}

static void AUITestSendKey(AUITestApplication *app, AUIKey key, AUIModifierFlags modifiers)
{
    [app ensureWindowWithWidth: 320 height: 240];
    [app.headlessWindow sendKey: key modifiers: modifiers repeat: false];
    AUITestRenderApplication(app, 320, 240);
}

static void application_launch_closes_backend_on_open_failure(AsyncScope *rootScope)
{
    AUITestLifecycleApplication *app = [[AUITestLifecycleApplication alloc] init];
    AUITestGroupComponent *root = [[AUITestGroupComponent alloc] init];
    AUITestSpyWindow *window = [[AUITestSpyWindow alloc] initWithApplication: app
                                                                                       options: app.windowOptions];
    OFException *nillable caughtException = nilptr;

    root.bodyChildren = @[];
    window.failOpen = true;
    app.providedRootComponent = root;
    app.providedWindow = window;

    @try {
        (void)[app applicationDidFinishLaunchingAsync: nilptr scope: rootScope];
    } @catch (OFException *exception) {
        caughtException = exception;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtException != nilptr) message: @"application launch should surface the backend open failure"];
    [AsyncRuntimeTestSupport assertCondition: (window.openCount == 1) message: @"application launch should attempt to open the window once"];
    [AsyncRuntimeTestSupport assertCondition: (window.closeCount == 1) message: @"application launch should still close the window in the failure cleanup path"];
    [AsyncRuntimeTestSupport assertCondition: (window.renderCount == 0) message: @"a failed window open should not attempt to render"];
    [AsyncRuntimeTestSupport assertCondition: (root.mountCount == 0) message: @"the root component should not mount if opening the window fails first"];
    [AsyncRuntimeTestSupport assertCondition: (root.unmountCount == 0) message: @"cleanup should not fabricate an unmount for a component that never mounted"];
}

static void application_launch_renders_first_frame_and_cleans_up(AsyncScope *rootScope)
{
    AUITestLifecycleApplication *app = [[AUITestLifecycleApplication alloc] init];
    AUITestGroupComponent *root = [[AUITestGroupComponent alloc] init];
    AUITestSpyWindow *window = [[AUITestSpyWindow alloc] initWithApplication: app
                                                                                        options: app.windowOptions];
    id value;

    root.bodyChildren = @[
        [AUILabel text: @"Hello"]
    ];
    window.closeAfterNextRender = true;
    app.providedRootComponent = root;
    app.providedWindow = window;

    value = [app applicationDidFinishLaunchingAsync: nilptr scope: rootScope];

    [AsyncRuntimeTestSupport assertCondition: ([value respondsToSelector: @selector(intValue)] and ((int)[value intValue]) == 0)
                                     message: @"application launch should resolve to a zero exit status when the window closes cleanly"];
    [AsyncRuntimeTestSupport assertCondition: (window.openCount == 1) message: @"application launch should open the window once"];
    [AsyncRuntimeTestSupport assertCondition: (window.pollCount == 1) message: @"the event loop should poll once before the first frame render"];
    [AsyncRuntimeTestSupport assertCondition: (window.renderCount == 1) message: @"the startup render request should produce a first frame"];
    [AsyncRuntimeTestSupport assertCondition: (window.closeCount == 1) message: @"the window should close during cleanup after the window exits"];
    [AsyncRuntimeTestSupport assertCondition: (root.mountCount == 1) message: @"the root component should mount during application launch"];
    [AsyncRuntimeTestSupport assertCondition: (root.unmountCount == 1) message: @"the root component should unmount during application cleanup"];
}

static void application_launch_processes_multiple_async_render_requests(AsyncScope *rootScope)
{
    AUITestLifecycleApplication *app = [[AUITestLifecycleApplication alloc] init];
    AUITestAsyncRenderLoopComponent *root = [[AUITestAsyncRenderLoopComponent alloc] init];
    AUITestSpyWindow *window = [[AUITestSpyWindow alloc] initWithApplication: app
                                                                                        options: app.windowOptions];
    id value;

    window.closeAfterRenderCount = 3;
    app.providedRootComponent = root;
    app.providedWindow = window;

    value = [app applicationDidFinishLaunchingAsync: nilptr scope: rootScope];

    [AsyncRuntimeTestSupport assertCondition: ([value respondsToSelector: @selector(intValue)] and ((int)[value intValue]) == 0)
                                     message: @"application launch should still resolve cleanly after multiple async-driven rerenders"];
    [AsyncRuntimeTestSupport assertCondition: (window.openCount == 1) message: @"the window should still only open once"];
    [AsyncRuntimeTestSupport assertCondition: (window.pollCount >= 3) message: @"the event loop should continue polling while async updates request more frames"];
    [AsyncRuntimeTestSupport assertCondition: (window.renderCount == 3) message: @"async signal invalidations should drive multiple frame renders before shutdown"];
    [AsyncRuntimeTestSupport assertCondition: (root.lastRenderedPhase == 2) message: @"the root component body should observe the final async-updated signal value before exit"];
}

static void application_launch_auto_resizes_window_to_root_component(AsyncScope *rootScope)
{
    AUITestLifecycleApplication *app = [[AUITestLifecycleApplication alloc] init];
    AUITestFixedSizeRootComponent *root = [[AUITestFixedSizeRootComponent alloc] init];
    AUIWindowOptions *options = [AUIWindowOptions title: @"Auto Resize Test"
                                                   size: (AUISize){ 320, 240 }
                                              resizable: true
                            autoResizeToRootComponent: true];
    AUITestSpyWindow *window = [[AUITestSpyWindow alloc] initWithApplication: app options: options];

    window.closeAfterRenderCount = 2;
    app.providedRootComponent = root;
    app.providedWindow = window;

    (void)[app applicationDidFinishLaunchingAsync: nilptr scope: rootScope];

    [AsyncRuntimeTestSupport assertCondition: (window.resizeCount > 0)
                                     message: @"auto-resize should ask the window to adopt the root component size"];
    [AsyncRuntimeTestSupport assertCondition: (window.renderCount == 2)
                                     message: @"auto-resize should schedule a follow-up frame after the viewport changes"];
    [AsyncRuntimeTestSupport assertCondition: (window.viewportSize.width == 180 and window.viewportSize.height == 60)
                                     message: @"auto-resize should shrink the window viewport to the laid-out root component bounds"];
    [AsyncRuntimeTestSupport assertCondition: AUIWindowOptions.defaultOptions.automaticallyResizesToRootComponent
                                     message: @"default window options should keep root-component auto-resize enabled"];
}

static void render_context_exposes_window_dark_mode_and_window_setter_requests_render(AsyncScope *rootScope)
{
    AUITestApplication *app = [[AUITestApplication alloc] init];
    AUITestDarkModeComponent *root = [[AUITestDarkModeComponent alloc] init];
    AUIWindow *window;

    AUITestAttachAndMountRoot(app, root, rootScope);

    @try {
        window = [app ensureWindowWithWidth: 320 height: 240];
        (void)[app _consumePendingRenderRequest];
        window.isDarkMode = true;

        [AsyncRuntimeTestSupport assertCondition: window.isDarkMode
                                         message: @"window dark mode should be settable through AUIWindow"];
        [AsyncRuntimeTestSupport assertCondition: [app _consumePendingRenderRequest]
                                         message: @"setting window dark mode should request a rerender"];

        [window renderFrame];
        [AsyncRuntimeTestSupport assertCondition: root.observedDarkMode
                                         message: @"render context should expose the window dark-mode state during rendering"];
    } @finally {
        AUITestDetachAndUnmountRoot(app, root);
    }
}

static void objfw_bridge_string_round_trip(AsyncScope *rootScope)
{
    (void)rootScope;

#if AUI_HAS_CORE_GRAPHICS_WINDOW
    AUIWindowOptions *options = AUIWindowOptions.defaultOptions;
    OFString *copiedTitle;

    copiedTitle = [AUICoreGraphicsWindow _roundTripBridgedStringForTesting: options.title];
    [AsyncRuntimeTestSupport assertCondition: (copiedTitle != nilptr)
                                     message: @"ObjFWBridge should convert the default window title through the CoreGraphics window at runtime"];
    [AsyncRuntimeTestSupport assertCondition: [copiedTitle isEqual: options.title]
                                     message: @"OFString to NSString bridging should round-trip through the CoreGraphics window without losing content"];
#endif
}

static void core_graphics_window_prepares_foreground_application(AsyncScope *rootScope)
{
    (void)rootScope;

#if AUI_HAS_CORE_GRAPHICS_WINDOW
    bool prepared = [AUICoreGraphicsWindow _prepareSharedApplicationForTesting];

    [AsyncRuntimeTestSupport assertCondition: prepared
                                     message: @"the CoreGraphics window should be able to create a shared NSApplication instance"];
    [AsyncRuntimeTestSupport assertCondition: [AUICoreGraphicsWindow _sharedApplicationIsForegroundForTesting]
                                     message: @"the CoreGraphics window should promote the process to a foreground app so windows can appear"];
    [AsyncRuntimeTestSupport assertCondition: [AUICoreGraphicsWindow _sharedApplicationHasMainMenuForTesting]
                                     message: @"the CoreGraphics window should install a main menu so the shared NSApplication behaves like a real Cocoa app"];
#endif
}

static void core_graphics_window_open_perform_close_and_cleanup(AsyncScope *rootScope)
{
    (void)rootScope;

#if AUI_HAS_CORE_GRAPHICS_WINDOW
    AUITestLifecycleApplication *application = [[AUITestLifecycleApplication alloc] init];
    AUICoreGraphicsWindow *backend = [[AUICoreGraphicsWindow alloc]
        initWithApplication: application
                    options: [AUIWindowOptions title: @"CoreGraphics Window Smoke"
                                              size: (AUISize){ 160, 96 }
                                         resizable: false]];

    [backend openWindow];
    [backend pollEvents];
    [backend pollEvents];
    [AsyncRuntimeTestSupport assertCondition: backend.isOpen
                                     message: @"opening the CoreGraphics window should create a live window session"];
    [AsyncRuntimeTestSupport assertCondition: [backend _windowIsVisibleForTesting]
                                     message: @"opening the CoreGraphics window should create a visible window"];
    [AsyncRuntimeTestSupport assertCondition: [AUICoreGraphicsWindow _sharedApplicationHasMainMenuForTesting]
                                     message: @"opening the CoreGraphics window should preserve the shared Cocoa main menu"];
    [AsyncRuntimeTestSupport assertCondition: [backend _renderViewIsFirstResponderForTesting]
                                     message: @"opening the CoreGraphics window should make the render view first responder for keyboard input"];
    {
        double scaleFactor = backend.scaleFactor;
        AUIInputState *inputState = [application _inputState];
        OFString *message;

        [backend _sendMouseDownForTestingWithViewX: 24 y: 18];
        message = [OFString stringWithFormat:
            @"CoreGraphics synthetic mouse events should translate view-space coordinates into the render view's backing-space input state (got x=%g y=%g scale=%g)",
            inputState.pointerX,
            inputState.pointerY,
            scaleFactor];
        [AsyncRuntimeTestSupport assertCondition: (fabs(inputState.pointerX - (24.0 * scaleFactor)) < 0.5 and
                                                   fabs(inputState.pointerY - (18.0 * scaleFactor)) < 0.5 and
                                                   inputState.primaryButtonPressedThisFrame)
                                         message: message];
        [inputState resetTransientState];
    }

    [backend openWindow];
    [backend pollEvents];
    [AsyncRuntimeTestSupport assertCondition: backend.isOpen
                                     message: @"opening the CoreGraphics window twice should remain in the open state"];

    [backend _performCloseForTesting];
    [backend pollEvents];
    [backend pollEvents];
    [AsyncRuntimeTestSupport assertCondition: (not backend.isOpen)
                                     message: @"performClose should route through the CoreGraphics window delegate cleanup path without leaving the backend open"];

    [backend openWindow];
    [backend pollEvents];
    [AsyncRuntimeTestSupport assertCondition: backend.isOpen
                                     message: @"opening the CoreGraphics window after a native close should create a fresh live window session"];

    [backend closeWindow];
    [backend pollEvents];
    [backend pollEvents];
    [AsyncRuntimeTestSupport assertCondition: (not backend.isOpen)
                                     message: @"closing the CoreGraphics window directly should leave it out of the open state"];

    [backend closeWindow];
    [AsyncRuntimeTestSupport assertCondition: (not backend.isOpen)
                                     message: @"closing the CoreGraphics window directly twice should remain idempotent"];
#endif
}

static void core_graphics_window_dispatches_pointer_interactions(AsyncScope *rootScope)
{
    (void)rootScope;

#if AUI_HAS_CORE_GRAPHICS_WINDOW
    AUITestApplication *application = [[AUITestApplication alloc] init];
    AUITestButtonComponent *root = [[AUITestButtonComponent alloc] init];
    AUICoreGraphicsWindow *backend = [[AUICoreGraphicsWindow alloc]
        initWithApplication: application
                    options: [AUIWindowOptions title: @"CoreGraphics Interaction Test"
                                              size: (AUISize){ 320, 240 }
                                         resizable: false]];

    [application _setWindowForTesting: backend];
    [application _setRootComponentForTesting: root];
    [root _attachToApplication: application parent: nilptr];
    [root _mountRecursivelyInScope: rootScope];

    @try {
        float viewClickX;
        float viewClickY;

        [backend openWindow];
        [backend pollEvents];
        [backend pollEvents];

        viewClickX = (float)(32.0 / backend.scaleFactor);
        viewClickY = (float)(32.0 / backend.scaleFactor);

        [application setNeedsRender];
        [backend renderFrame];
        [backend _sendPointerMoveForTestingWithViewX: viewClickX y: viewClickY];
        [application setNeedsRender];
        [backend renderFrame];
        [backend _sendMouseDownForTestingWithViewX: viewClickX y: viewClickY];
        [application setNeedsRender];
        [backend renderFrame];
        [backend _sendMouseUpForTestingWithViewX: viewClickX y: viewClickY];
        [application setNeedsRender];
        [backend renderFrame];

        OFString *message = [OFString stringWithFormat:
            @"CoreGraphics window input should dispatch visible button clicks through the shared AUI interaction pipeline (pressCount=%zu)",
            root.pressCount];
        [AsyncRuntimeTestSupport assertCondition: (root.pressCount == 1)
                                         message: message];
    } @finally {
        [root _unmountRecursively];
        [root _detachFromApplication];
        [application _setRootComponentForTesting: nilptr];
        [backend closeWindow];
        [application _setWindowForTesting: nilptr];
    }
#endif
}

static void application_make_window_selects_platform_default_backend(AsyncScope *rootScope)
{
    (void)rootScope;

    AUITestApplication *application = [[AUITestApplication alloc] init];
    AUIWindow *window = [application makeWindow];

#if AUI_HAS_CORE_GRAPHICS_WINDOW
    [AsyncRuntimeTestSupport assertCondition: [window isKindOfClass: AUICoreGraphicsWindow.class]
                                     message: @"AUIApplication should default to AUICoreGraphicsWindow on macOS"];
#elif AUI_HAS_CAIRO_X11_WINDOW
    [AsyncRuntimeTestSupport assertCondition: [window isKindOfClass: AUICairoX11Window.class]
                                     message: @"AUIApplication should default to AUICairoX11Window when X11 is the native backend"];
#else
    [AsyncRuntimeTestSupport assertCondition: [window isKindOfClass: AUIHeadlessWindow.class]
                                     message: @"AUIApplication should default to AUIHeadlessWindow when no interactive backend is enabled"];
#endif
}

static void cairo_x11_window_availability_and_smoke(AsyncScope *rootScope)
{
    (void)rootScope;

#if AUI_HAS_CAIRO_X11_WINDOW
    [AsyncRuntimeTestSupport assertCondition: true
                                     message: @"AUICairoX11Window should be compiled when AUI_HAS_CAIRO_X11_WINDOW is enabled"];

    if (getenv("DISPLAY") != nullptr) {
        AUITestLifecycleApplication *application = [[AUITestLifecycleApplication alloc] init];
        AUICairoX11Window *window = [[AUICairoX11Window alloc]
            initWithApplication: application
                        options: [AUIWindowOptions title: @"Cairo X11 Smoke"
                                                  size: (AUISize){ 96, 64 }
                                             resizable: false]];

        [window openWindow];
        [window pollEvents];
        [AsyncRuntimeTestSupport assertCondition: window.isOpen
                                         message: @"AUICairoX11Window should open successfully when DISPLAY is available"];
        [window closeWindow];
        [AsyncRuntimeTestSupport assertCondition: (not window.isOpen)
                                         message: @"AUICairoX11Window should close cleanly after the smoke check"];
    }
#else
    [AsyncRuntimeTestSupport assertCondition: true
                                     message: @"AUICairoX11Window should be unavailable when AUI_HAS_CAIRO_X11_WINDOW is disabled"];
#endif
}

static void clipboard_shortcuts_round_trip_through_backend(AsyncScope *rootScope)
{
    AUITestApplication *app = [[AUITestApplication alloc] init];
    AUITestClipboardComponent *root = [[AUITestClipboardComponent alloc] init];

    AUITestAttachAndMountRoot(app, root, rootScope);
    AUITestRenderApplication(app, 320, 240);
    AUITestSendKey(app, AUIKeyTab, AUIModifierFlagNone);
    AUITestSendKey(app, AUIKeyA, AUIModifierFlagCommand);
    AUITestSendKey(app, AUIKeyC, AUIModifierFlagCommand);
    AUITestSendKey(app, AUIKeyX, AUIModifierFlagCommand);
    AUITestSendKey(app, AUIKeyTab, AUIModifierFlagNone);
    AUITestSendKey(app, AUIKeyV, AUIModifierFlagCommand);

    [AsyncRuntimeTestSupport assertCondition: ([app.headlessWindow.clipboardText isEqual: @"alpha"])
                                     message: @"copy should write the selected text through the backend clipboard abstraction"];
    [AsyncRuntimeTestSupport assertCondition: ([root.first isEqual: @""])
                                     message: @"cut should remove the selected text from the focused field"];
    [AsyncRuntimeTestSupport assertCondition: ([root.second isEqual: @"alpha"])
                                     message: @"paste should read the clipboard back through the backend into the next field"];

    AUITestDetachAndUnmountRoot(app, root);
}

static void context_menu_opens_activates_and_dismisses(AsyncScope *rootScope)
{
    AUITestApplication *app = [[AUITestApplication alloc] init];
    AUITestContextMenuComponent *root = [[AUITestContextMenuComponent alloc] init];
    Clay_ElementData menuData;

    AUITestAttachAndMountRoot(app, root, rootScope);
    AUITestRenderApplication(app, 320, 240);

    AUITestClick(app, 40, 40);
    [AsyncRuntimeTestSupport assertCondition: ([app _activeContextMenuForTesting] == nilptr)
                                     message: @"primary clicks should not open a context menu region"];

    AUITestSecondaryClick(app, 40, 40);
    AUITestRenderApplication(app, 320, 240);
    menuData = [AUIClay elementDataForID: [AUIClay elementIDFromString: @"__context_menu__"]];
    [AsyncRuntimeTestSupport assertCondition: ([app _activeContextMenuForTesting] != nilptr)
                                     message: @"secondary click should open the context menu state"];
    menuData = [AUIClay elementDataForID: [AUIClay elementIDFromString: @"__context_menu__"]];
    [AsyncRuntimeTestSupport assertCondition: (menuData.found)
                                     message: @"secondary click should open the context menu overlay"];

    AUITestClick(app, 70, 60);
    AUITestRenderApplication(app, 320, 240);
    [AsyncRuntimeTestSupport assertCondition: (root.selectionCount == 1)
                                     message: @"clicking a context menu item should invoke its select handler exactly once"];
    [AsyncRuntimeTestSupport assertCondition: ([app _activeContextMenuForTesting] == nilptr)
                                     message: @"activating a context menu item should dismiss the overlay"];

    AUITestSecondaryClick(app, 40, 40);
    AUITestRenderApplication(app, 320, 240);
    menuData = [AUIClay elementDataForID: [AUIClay elementIDFromString: @"__context_menu__"]];
    [AsyncRuntimeTestSupport assertCondition: ([app _activeContextMenuForTesting] != nilptr)
                                     message: @"the menu state should be reopenable after an action"];
    [AsyncRuntimeTestSupport assertCondition: (menuData.found)
                                     message: @"the menu should be reopenable after an action"];

    AUITestClick(app, 280, 220);
    AUITestRenderApplication(app, 320, 240);
    [AsyncRuntimeTestSupport assertCondition: (root.selectionCount == 1)
                                     message: @"clicking outside the menu should dismiss it without invoking another item action"];
    [AsyncRuntimeTestSupport assertCondition: ([app _activeContextMenuForTesting] == nilptr)
                                     message: @"clicking outside an open context menu should dismiss the overlay"];

    AUITestDetachAndUnmountRoot(app, root);
}

static void component_mount_unmount_recursion_and_child_replacement(AsyncScope *rootScope)
{
    AUITestGroupComponent *root = [[AUITestGroupComponent alloc] init];
    AUITestGroupComponent *childA = [[AUITestGroupComponent alloc] init];
    AUITestGroupComponent *childB = [[AUITestGroupComponent alloc] init];
    AUITestComponent *grandchildA = [[AUITestComponent alloc] init];
    AUITestComponent *grandchildB = [[AUITestComponent alloc] init];

    childA.bodyChildren = @[grandchildA];
    childB.bodyChildren = @[grandchildB];
    root.bodyChildren = @[childA];

    [root _mountRecursivelyInScope: rootScope];
    [root _renderRecursively];

    [AsyncRuntimeTestSupport assertCondition: (root.mountCount == 1) message: @"root component should mount once"];
    [AsyncRuntimeTestSupport assertCondition: (childA.mountCount == 1) message: @"child components should mount when first referenced from -body"];
    [AsyncRuntimeTestSupport assertCondition: (grandchildA.mountCount == 1) message: @"grandchildren should mount recursively through nested bodies"];
    [AsyncRuntimeTestSupport assertCondition: (root.renderedChildren.count == 1) message: @"root should track one mounted child component"];
    [AsyncRuntimeTestSupport assertCondition: (root.renderedChildren.firstObject == childA) message: @"root should track childA as its mounted child"];

    root.bodyChildren = @[childB];
    [root _renderRecursively];

    [AsyncRuntimeTestSupport assertCondition: (childA.unmountCount == 1) message: @"replacing a child should unmount the removed subtree"];
    [AsyncRuntimeTestSupport assertCondition: (grandchildA.unmountCount == 1) message: @"replacing a child should recursively unmount grandchildren"];
    [AsyncRuntimeTestSupport assertCondition: (childB.mountCount == 1) message: @"replacement children should mount when inserted into the render tree"];
    [AsyncRuntimeTestSupport assertCondition: (grandchildB.mountCount == 1) message: @"replacement grandchildren should mount recursively"];

    [root _unmountRecursively];

    [AsyncRuntimeTestSupport assertCondition: (root.unmountCount == 1) message: @"root should unmount once"];
    [AsyncRuntimeTestSupport assertCondition: (childB.unmountCount == 1) message: @"unmounting the root should recursively unmount the remaining child"];
    [AsyncRuntimeTestSupport assertCondition: (grandchildB.unmountCount == 1) message: @"unmounting the root should recursively unmount the remaining grandchild"];
}

static void set_needs_render_bubbles_to_application(AsyncScope *rootScope)
{
    AUITestApplication *app = [[AUITestApplication alloc] init];
    AUITestGroupComponent *root = [[AUITestGroupComponent alloc] init];
    AUITestComponent *child = [[AUITestComponent alloc] init];

    root.bodyChildren = @[child];

    [root _attachToApplication: app parent: nilptr];
    [root _mountRecursivelyInScope: rootScope];
    [root _renderRecursively];

    [AsyncRuntimeTestSupport assertCondition: ([app _consumePendingRenderRequest]) message: @"mounting and rendering should schedule a render"];
    [AsyncRuntimeTestSupport assertCondition: (not [app _consumePendingRenderRequest]) message: @"consuming the pending render flag should clear it"];

    [child setNeedsRender];

    [AsyncRuntimeTestSupport assertCondition: ([app _consumePendingRenderRequest]) message: @"setNeedsRender should bubble to the owning application"];
}

static void render_dependency_tracking_for_signal(AsyncScope *rootScope)
{
    Signal<OFString *> *signal = [Signal withValue: @"alpha"];
    AUITestSignalComponent *component = [[AUITestSignalComponent alloc] initWithSignal: signal];
    block_reference bool invalidated = false;
    AUIRenderObserver *observer = [[AUIRenderObserver alloc] initWithInvalidationHandler: ^{
        invalidated = true;
    }];

    [component _mountRecursivelyInScope: rootScope];
    [observer beginTracking];
    [component _renderRecursively];
    [observer endTracking];

    [AsyncRuntimeTestSupport assertCondition: (not invalidated) message: @"reading a signal during body evaluation should not invalidate immediately"];

    signal.value = [OFString stringWithFormat: @"%@", @"alpha"];
    [AsyncRuntimeTestSupport assertCondition: (not invalidated) message: @"setting a signal to an equal value should not invalidate the render observer"];

    signal.value = @"beta";
    [AsyncRuntimeTestSupport assertCondition: (invalidated) message: @"changing a tracked Signal should invalidate the render observer"];
}

static void render_dependency_tracking_for_async_signal(AsyncScope *rootScope)
{
    AsyncSignal<OFString *> *signal = [AsyncSignal withValue: @"alpha"];
    AUITestAsyncSignalComponent *component = [[AUITestAsyncSignalComponent alloc] initWithSignal: signal];
    block_reference bool invalidated = false;
    AUIRenderObserver *observer = [[AUIRenderObserver alloc] initWithInvalidationHandler: ^{
        invalidated = true;
    }];

    [component _mountRecursivelyInScope: rootScope];
    [observer beginTracking];
    [component _renderRecursively];
    [observer endTracking];

    [AsyncRuntimeTestSupport assertCondition: (not invalidated) message: @"reading an async signal during body evaluation should not invalidate immediately"];

    signal.value = [OFString stringWithFormat: @"%@", @"alpha"];
    [AsyncRuntimeTestSupport assertCondition: (not invalidated) message: @"setting an async signal to an equal value should not invalidate the render observer"];

    signal.value = @"beta";
    [AsyncRuntimeTestSupport assertCondition: (invalidated) message: @"changing a tracked AsyncSignal should invalidate the render observer"];
}

static void duplicate_child_component_references_are_rejected(AsyncScope *rootScope)
{
    AUITestGroupComponent *root = [[AUITestGroupComponent alloc] init];
    AUITestComponent *child = [[AUITestComponent alloc] init];
    AUIRenderException *nillable caughtException = nilptr;

    root.bodyChildren = @[child, child];
    [root _mountRecursivelyInScope: rootScope];

    @try {
        [root _renderRecursively];
    } @catch (AUIRenderException *exception) {
        caughtException = exception;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtException != nilptr) message: @"duplicate child component references should throw AUIRenderException"];
}

static void shared_child_component_under_multiple_parents_is_rejected(AsyncScope *rootScope)
{
    AUITestComponent *sharedChild = [[AUITestComponent alloc] init];
    AUITestGroupComponent *left = [[AUITestGroupComponent alloc] init];
    AUITestGroupComponent *right = [[AUITestGroupComponent alloc] init];
    AUITestGroupComponent *root = [[AUITestGroupComponent alloc] init];
    AUIRenderException *nillable caughtException = nilptr;

    left.bodyChildren = @[sharedChild];
    right.bodyChildren = @[sharedChild];
    root.bodyChildren = @[left, right];
    [root _mountRecursivelyInScope: rootScope];

    @try {
        [root _renderRecursively];
    } @catch (AUIRenderException *exception) {
        caughtException = exception;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtException != nilptr) message: @"the same child component should not be allowed under multiple parents"];
}

static void component_catalog_renders_commands(AsyncScope *rootScope)
{
    AUITestCatalogComponent *root = [[AUITestCatalogComponent alloc] init];
    Clay_RenderCommandArray commands;
    void *memory = nullptr;
    bool sawRectangle = false;
    bool sawText = false;

    [root _mountRecursivelyInScope: rootScope];
    commands = AUITestRenderCommandsForMountedComponent(root, nullptr, &memory);

    for (int32_t index = 0; index < commands.length; index++) {
        Clay_RenderCommand *command = Clay_RenderCommandArray_Get(&commands, index);

        if (command->commandType == CLAY_RENDER_COMMAND_TYPE_RECTANGLE)
            sawRectangle = true;
        else if (command->commandType == CLAY_RENDER_COMMAND_TYPE_TEXT)
            sawText = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (commands.length > 0) message: @"the catalog tree should emit Clay render commands"];
    [AsyncRuntimeTestSupport assertCondition: (sawRectangle) message: @"the catalog tree should emit rectangle commands"];
    [AsyncRuntimeTestSupport assertCondition: (sawText) message: @"the catalog tree should emit text commands"];
    free(memory);
}

static void button_press_invokes_callback(AsyncScope *rootScope)
{
    AUITestApplication *app = [[AUITestApplication alloc] init];
    AUITestButtonComponent *root = [[AUITestButtonComponent alloc] init];

    AUITestAttachAndMountRoot(app, root, rootScope);
    AUITestRenderApplication(app, 320, 240);
    AUITestClick(app, 40, 40);

    [AsyncRuntimeTestSupport assertCondition: (root.pressCount == 1) message: @"button release over the control should invoke onPress exactly once"];

    AUITestDetachAndUnmountRoot(app, root);
}

static void toggle_and_radio_controls_dispatch_controlled_changes(AsyncScope *rootScope)
{
    AUITestApplication *app = [[AUITestApplication alloc] init];
    AUITestToggleComponent *toggleRoot = [[AUITestToggleComponent alloc] init];
    AUITestRadioComponent *radioRoot = [[AUITestRadioComponent alloc] init];

    AUITestAttachAndMountRoot(app, toggleRoot, rootScope);
    AUITestRenderApplication(app, 320, 240);
    AUITestClick(app, 32, 32);
    [AsyncRuntimeTestSupport assertCondition: (toggleRoot.isChecked) message: @"toggle should flip its controlled value on click"];
    AUITestDetachAndUnmountRoot(app, toggleRoot);

    AUITestAttachAndMountRoot(app, radioRoot, rootScope);
    AUITestRenderApplication(app, 320, 240);
    AUITestClick(app, 32, 64);
    [AsyncRuntimeTestSupport assertCondition: (radioRoot.selectedIndex == 1) message: @"radio group should select the clicked option"];
    AUITestDetachAndUnmountRoot(app, radioRoot);
}

static void text_fields_focus_edit_submit_and_tab_navigation(AsyncScope *rootScope)
{
    AUITestApplication *app = [[AUITestApplication alloc] init];
    AUITestTextFieldComponent *fieldRoot = [[AUITestTextFieldComponent alloc] init];
    AUITestTwoFieldComponent *twoFieldRoot = [[AUITestTwoFieldComponent alloc] init];

    AUITestAttachAndMountRoot(app, fieldRoot, rootScope);
    AUITestRenderApplication(app, 320, 240);
    AUITestClick(app, 48, 40);
    AUITestTypeASCII(app, "ab");
    AUITestSendKey(app, AUIKeyBackspace, AUIModifierFlagNone);
    AUITestSendKey(app, AUIKeyEnter, AUIModifierFlagNone);

    [AsyncRuntimeTestSupport assertCondition: ([fieldRoot.text isEqual: @"a"]) message: @"text field typing and backspace should update the controlled value"];
    [AsyncRuntimeTestSupport assertCondition: (fieldRoot.submitCount == 1) message: @"enter on a single-line text field should trigger submit"];
    AUITestDetachAndUnmountRoot(app, fieldRoot);

    AUITestAttachAndMountRoot(app, twoFieldRoot, rootScope);
    AUITestRenderApplication(app, 320, 240);
    AUITestSendKey(app, AUIKeyTab, AUIModifierFlagNone);
    AUITestTypeASCII(app, "x");
    AUITestSendKey(app, AUIKeyTab, AUIModifierFlagNone);
    AUITestTypeASCII(app, "y");

    [AsyncRuntimeTestSupport assertCondition: ([twoFieldRoot.first isEqual: @"x"]) message: @"tab should focus the first focusable field when nothing is focused"];
    [AsyncRuntimeTestSupport assertCondition: ([twoFieldRoot.second isEqual: @"y"]) message: @"tab should advance focus in declaration order"];
    AUITestDetachAndUnmountRoot(app, twoFieldRoot);
}

static void text_area_secure_mask_scroll_and_stable_focus(AsyncScope *rootScope)
{
    AUITestApplication *app = [[AUITestApplication alloc] init];
    AUITestTextAreaComponent *textAreaRoot = [[AUITestTextAreaComponent alloc] init];
    AUITestStableFocusComponent *stableFocusRoot = [[AUITestStableFocusComponent alloc] init];
    AUITestScrollComponent *scrollRoot = [[AUITestScrollComponent alloc] init];
    AUITestSecureFieldComponent *secureRoot = [[AUITestSecureFieldComponent alloc] init];
    Clay_RenderCommandArray commands;
    Clay_ElementData beforeData;
    Clay_ElementData afterData;
    OFString *nillable firstRenderedText = nilptr;
    void *memory = nullptr;

    AUITestAttachAndMountRoot(app, textAreaRoot, rootScope);
    AUITestRenderApplication(app, 320, 240);
    AUITestClick(app, 48, 40);
    AUITestTypeASCII(app, "a");
    AUITestSendKey(app, AUIKeyEnter, AUIModifierFlagNone);
    AUITestTypeASCII(app, "b");
    [AsyncRuntimeTestSupport assertCondition: ([textAreaRoot.text isEqual: @"a\nb"]) message: @"text area should accept multiline editing"];
    AUITestDetachAndUnmountRoot(app, textAreaRoot);

    [secureRoot _mountRecursivelyInScope: rootScope];
    commands = AUITestRenderCommandsForMountedComponent(secureRoot, nullptr, &memory);
    firstRenderedText = AUITestFirstRenderedTextString(commands);
    [AsyncRuntimeTestSupport assertCondition: (firstRenderedText != nilptr) message: @"secure field should render text output"];
    [AsyncRuntimeTestSupport assertCondition: (not [firstRenderedText isEqual: @"secret"]) message: @"secure field should not render the underlying secret value verbatim"];
    free(memory);
    [secureRoot _unmountRecursively];

    AUITestAttachAndMountRoot(app, scrollRoot, rootScope);
    AUITestRenderApplication(app, 320, 240);
    beforeData = [AUIClay elementDataForID: [AUIClay elementIDFromString: @"root/0/0/0"]];
    [app ensureWindowWithWidth: 320 height: 240];
    [app.headlessWindow sendPointerMoveToX: 40 y: 40];
    [app.headlessWindow sendScrollByX: 0 y: -3];
    AUITestRenderApplication(app, 320, 240);
    AUITestRenderApplication(app, 320, 240);
    afterData = [AUIClay elementDataForID: [AUIClay elementIDFromString: @"root/0/0/0"]];
    [AsyncRuntimeTestSupport assertCondition: (beforeData.found and afterData.found) message: @"scroll test should locate the first row element by its stable render-path ID"];
    [AsyncRuntimeTestSupport assertCondition: (afterData.boundingBox.y < beforeData.boundingBox.y) message: @"scroll view wheel input should offset child content on the next frame"];
    AUITestDetachAndUnmountRoot(app, scrollRoot);

    AUITestAttachAndMountRoot(app, stableFocusRoot, rootScope);
    AUITestRenderApplication(app, 320, 240);
    AUITestClick(app, 52, 72);
    AUITestTypeASCII(app, "a");
    [stableFocusRoot advanceTick];
    [stableFocusRoot setNeedsRender];
    AUITestRenderApplication(app, 320, 240);
    AUITestTypeASCII(app, "b");
    [AsyncRuntimeTestSupport assertCondition: ([stableFocusRoot.text isEqual: @"ab"]) message: @"render-path derived IDs should preserve text-input focus across ordinary rerenders"];
    AUITestDetachAndUnmountRoot(app, stableFocusRoot);
}

ASYNC_RUNTIME_ASYNC_TEST(component_mount_unmount_recursion_and_child_replacement)
ASYNC_RUNTIME_ASYNC_TEST(set_needs_render_bubbles_to_application)
ASYNC_RUNTIME_ASYNC_TEST(render_dependency_tracking_for_signal)
ASYNC_RUNTIME_ASYNC_TEST(render_dependency_tracking_for_async_signal)
ASYNC_RUNTIME_ASYNC_TEST(duplicate_child_component_references_are_rejected)
ASYNC_RUNTIME_ASYNC_TEST(shared_child_component_under_multiple_parents_is_rejected)
ASYNC_RUNTIME_ASYNC_TEST(component_catalog_renders_commands)
ASYNC_RUNTIME_ASYNC_TEST(application_launch_closes_backend_on_open_failure)
ASYNC_RUNTIME_ASYNC_TEST(application_launch_renders_first_frame_and_cleans_up)
ASYNC_RUNTIME_ASYNC_TEST(application_launch_processes_multiple_async_render_requests)
ASYNC_RUNTIME_ASYNC_TEST(application_launch_auto_resizes_window_to_root_component)
ASYNC_RUNTIME_ASYNC_TEST(render_context_exposes_window_dark_mode_and_window_setter_requests_render)
ASYNC_RUNTIME_ASYNC_TEST(objfw_bridge_string_round_trip)
ASYNC_RUNTIME_ASYNC_TEST(core_graphics_window_prepares_foreground_application)
ASYNC_RUNTIME_ASYNC_TEST(core_graphics_window_open_perform_close_and_cleanup)
ASYNC_RUNTIME_ASYNC_TEST(core_graphics_window_dispatches_pointer_interactions)
ASYNC_RUNTIME_ASYNC_TEST(application_make_window_selects_platform_default_backend)
ASYNC_RUNTIME_ASYNC_TEST(cairo_x11_window_availability_and_smoke)
ASYNC_RUNTIME_ASYNC_TEST(button_press_invokes_callback)
ASYNC_RUNTIME_ASYNC_TEST(toggle_and_radio_controls_dispatch_controlled_changes)
ASYNC_RUNTIME_ASYNC_TEST(text_fields_focus_edit_submit_and_tab_navigation)
ASYNC_RUNTIME_ASYNC_TEST(text_area_secure_mask_scroll_and_stable_focus)
ASYNC_RUNTIME_ASYNC_TEST(clipboard_shortcuts_round_trip_through_backend)
ASYNC_RUNTIME_ASYNC_TEST(context_menu_opens_activates_and_dismisses)

#pragma clang assume_nonnull end
