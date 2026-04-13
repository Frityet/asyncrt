#include <cairo.h>
#include <stdlib.h>
#include <string.h>

#import "TestSupport.h"
#import "UI/UI.h"
#import "UI/AUIClaySupport.h"
#import "UI/AUIBackend.h"
#import "UI/AUIInternal.h"
#import "UI/Backend/Window/AUIHeadlessWindowBackend.h"
#import "UI/Components/AUIComponents.h"
#import "UI/Components/Controls/AUIControls.h"
#import "UI/Components/Display/AUIDisplay.h"
#import "UI/Components/Forms/AUIForms.h"
#import "UI/Components/Layout/AUILayout.h"
#import "UI/Components/Surface/AUISurface.h"
#import "Async/AsyncSignal.h"

#if defined(__APPLE__)
@interface AUICocoaWindowBackend (AUITestingBridge)
+ (bool)_prepareSharedApplicationForTesting;
+ (bool)_sharedApplicationIsForegroundForTesting;
+ (bool)_sharedApplicationIsActiveForTesting;
+ (bool)_sharedApplicationHasMainMenuForTesting;
+ (size_t)_sharedApplicationWindowCountForTesting;
+ (OFString *nillable)_roundTripBridgedStringForTesting: (OFString *nillable)string;
- (void)_performCloseForTesting;
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

[[subclassing_restricted]]
@interface AUITestSpyWindowBackend : AUIWindowBackend

@property(nonatomic) bool failOpen;
@property(nonatomic) bool closeAfterNextRender;
@property(nonatomic) size_t closeAfterRenderCount;
@property(readonly, nonatomic) size_t openCount;
@property(readonly, nonatomic) size_t pollCount;
@property(readonly, nonatomic) size_t closeCount;
@property(readonly, nonatomic) size_t renderCount;
@property(readonly, nonatomic) AUICursorStyle cursorStyle;

@end

@implementation AUITestSpyWindowBackend {
    bool _open;
    bool _failOpen;
    bool _closeAfterNextRender;
    size_t _closeAfterRenderCount;
    size_t _openCount;
    size_t _pollCount;
    size_t _closeCount;
    size_t _renderCount;
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
    return self.options.initialSize;
}

- (double)scaleFactor
{
    return 1.0;
}

- (void)openWindow
{
    _openCount++;

    if (_failOpen)
        @throw [[AUIInitializationException alloc] initWithReason: @"Spy window backend failed to open"];

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
    int width = (int)self.options.initialSize.width;
    int height = (int)self.options.initialSize.height;
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

- (void)_renderFrameWithBlock: (void (^)(cairo_t *cairo, AUISize viewportSize))renderBlock
{
    if (not _open or renderBlock == nilptr or not [self _ensureSurface])
        return;

    _renderCount++;

    cairo_save($assert_nonnil(_cairo));
    @try {
        cairo_set_operator($assert_nonnil(_cairo), CAIRO_OPERATOR_SOURCE);
        cairo_set_source_rgba($assert_nonnil(_cairo), 0.0, 0.0, 0.0, 0.0);
        cairo_paint($assert_nonnil(_cairo));
        renderBlock($assert_nonnil(_cairo), self.options.initialSize);
        cairo_surface_flush($assert_nonnil(_surface));
    } @finally {
        cairo_restore($assert_nonnil(_cairo));
    }

    if (_closeAfterNextRender or (_closeAfterRenderCount > 0 and _renderCount >= _closeAfterRenderCount))
        _open = false;
}

@end

[[subclassing_restricted]]
@interface AUITestSpyRendererBackend : AUIRendererBackend

@property(readonly, nonatomic) size_t prepareCount;
@property(readonly, nonatomic) size_t renderCount;
@property(readonly, nonatomic) AUISize lastPreparedViewportSize;
@property(readonly, nonatomic) AUISize lastRenderedViewportSize;

@end

@implementation AUITestSpyRendererBackend {
    size_t _prepareCount;
    size_t _renderCount;
    AUISize _lastPreparedViewportSize;
    AUISize _lastRenderedViewportSize;
}

@synthesize prepareCount = _prepareCount;
@synthesize renderCount = _renderCount;
@synthesize lastPreparedViewportSize = _lastPreparedViewportSize;
@synthesize lastRenderedViewportSize = _lastRenderedViewportSize;

- (void)_prepareForViewportSize: (AUISize)viewportSize
{
    _prepareCount++;
    _lastPreparedViewportSize = viewportSize;
}

- (void)_renderApplication: (AUIApplication *)application
                 inputState: (AUIInputState *)inputState
               viewportSize: (AUISize)viewportSize
                      cairo: (cairo_t *)cairo
{
    (void)inputState;
    (void)cairo;

    _renderCount++;
    _lastRenderedViewportSize = viewportSize;
    (void)[application _buildRenderCommandsWithViewportSize: viewportSize deltaTime: 1.0f / 60.0f];
}

@end

[[subclassing_restricted]]
@interface AUITestLifecycleApplication : AUIApplication

@property(retain, nonatomic) AUIComponent *nillable providedRootComponent;
@property(retain, nonatomic) AUIWindowBackend *nillable providedWindowBackend;
@property(retain, nonatomic) AUIRendererBackend *nillable providedRendererBackend;

@end

@implementation AUITestLifecycleApplication {
    AUIComponent *nillable _providedRootComponent;
    AUIWindowBackend *nillable _providedWindowBackend;
    AUIRendererBackend *nillable _providedRendererBackend;
}

@synthesize providedRootComponent = _providedRootComponent;
@synthesize providedWindowBackend = _providedWindowBackend;
@synthesize providedRendererBackend = _providedRendererBackend;

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

- (AUIWindowBackend *)makeWindowBackend
{
    return _providedWindowBackend;
}

- (AUIRendererBackend *)makeRendererBackend
{
    return _providedRendererBackend;
}

@end

[[subclassing_restricted]]
@interface AUITestApplication : AUIApplication @end

@interface AUITestApplication ()

@property(readonly, nonatomic) AUIHeadlessWindowBackend *headlessWindowBackend;
@property(readonly, nonatomic) AUIBackend *backendCoordinator;

- (AUIBackend *)ensureBackendWithWidth: (float)width height: (float)height;
- (void)disposeBackend;

@end

@implementation AUITestApplication {
    AUIHeadlessWindowBackend *_headlessWindowBackend;
    AUIBackend *_backendCoordinator;
}

@synthesize headlessWindowBackend = _headlessWindowBackend;
@synthesize backendCoordinator = _backendCoordinator;

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

- (AUIBackend *)ensureBackendWithWidth: (float)width height: (float)height
{
    if (_headlessWindowBackend == nilptr) {
        AUIWindowOptions *options = [AUIWindowOptions title: @"Test UI"
                                                       size: (AUISize){ width, height }
                                                  resizable: true];

        _headlessWindowBackend = [[AUIHeadlessWindowBackend alloc] initWithApplication: self options: options];
        _backendCoordinator = [[AUIBackend alloc] initWithApplication: self
                                                         windowBackend: _headlessWindowBackend
                                                       rendererBackend: [[AUICairoRendererBackend alloc] initWithApplication: self]];
        [self _setBackendForTesting: _backendCoordinator];
        [_backendCoordinator openWindow];
    }

    [_headlessWindowBackend setViewportSize: (AUISize){ width, height }];
    return _backendCoordinator;
}

- (void)disposeBackend
{
    if (_backendCoordinator != nilptr)
        [_backendCoordinator closeWindow];

    [self _setBackendForTesting: nilptr];
    _backendCoordinator = nilptr;
    _headlessWindowBackend = nilptr;
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
    [app disposeBackend];
}

static void AUITestRenderApplication(AUITestApplication *app, float width, float height)
{
    AUIBackend *backend = [app ensureBackendWithWidth: width height: height];

    [app setNeedsRender];
    [backend renderFrame];
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
    [app ensureBackendWithWidth: 320 height: 240];
    [app.headlessWindowBackend sendPointerMoveToX: x y: y];
    AUITestRenderApplication(app, 320, 240);

    [app.headlessWindowBackend sendMouseDown: AUIMouseButtonPrimary];
    AUITestRenderApplication(app, 320, 240);

    [app.headlessWindowBackend sendPointerMoveToX: x y: y];
    [app.headlessWindowBackend sendMouseUp: AUIMouseButtonPrimary];
    AUITestRenderApplication(app, 320, 240);
}

static void AUITestSecondaryClick(AUITestApplication *app, float x, float y)
{
    [app ensureBackendWithWidth: 320 height: 240];
    [app.headlessWindowBackend sendPointerMoveToX: x y: y];
    AUITestRenderApplication(app, 320, 240);

    [app.headlessWindowBackend sendMouseDown: AUIMouseButtonSecondary];
    AUITestRenderApplication(app, 320, 240);

    [app.headlessWindowBackend sendPointerMoveToX: x y: y];
    [app.headlessWindowBackend sendMouseUp: AUIMouseButtonSecondary];
    AUITestRenderApplication(app, 320, 240);
}

static void AUITestTypeASCII(AUITestApplication *app, const char *text)
{
    [app ensureBackendWithWidth: 320 height: 240];
    [app.headlessWindowBackend sendText: [OFString stringWithUTF8String: text]];

    AUITestRenderApplication(app, 320, 240);
}

static void AUITestSendKey(AUITestApplication *app, AUIKey key, AUIModifierFlags modifiers)
{
    [app ensureBackendWithWidth: 320 height: 240];
    [app.headlessWindowBackend sendKey: key modifiers: modifiers repeat: false];
    AUITestRenderApplication(app, 320, 240);
}

static void application_launch_closes_backend_on_open_failure(AsyncScope *rootScope)
{
    AUITestLifecycleApplication *app = [[AUITestLifecycleApplication alloc] init];
    AUITestGroupComponent *root = [[AUITestGroupComponent alloc] init];
    AUITestSpyWindowBackend *windowBackend = [[AUITestSpyWindowBackend alloc] initWithApplication: app
                                                                                           options: app.windowOptions];
    AUITestSpyRendererBackend *rendererBackend = [[AUITestSpyRendererBackend alloc] initWithApplication: app];
    OFException *nillable caughtException = nilptr;

    root.bodyChildren = @[];
    windowBackend.failOpen = true;
    app.providedRootComponent = root;
    app.providedWindowBackend = windowBackend;
    app.providedRendererBackend = rendererBackend;

    @try {
        (void)[app applicationDidFinishLaunchingAsync: nilptr scope: rootScope];
    } @catch (OFException *exception) {
        caughtException = exception;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtException != nilptr) message: @"application launch should surface the backend open failure"];
    [AsyncRuntimeTestSupport assertCondition: (windowBackend.openCount == 1) message: @"application launch should attempt to open the window once"];
    [AsyncRuntimeTestSupport assertCondition: (windowBackend.closeCount == 1) message: @"application launch should still close the backend in the failure cleanup path"];
    [AsyncRuntimeTestSupport assertCondition: (windowBackend.renderCount == 0) message: @"a failed window open should not attempt to render"];
    [AsyncRuntimeTestSupport assertCondition: (rendererBackend.prepareCount == 0) message: @"renderer preparation should not happen when the window fails to open"];
    [AsyncRuntimeTestSupport assertCondition: (rendererBackend.renderCount == 0) message: @"renderer should not render after an open failure"];
    [AsyncRuntimeTestSupport assertCondition: (root.mountCount == 0) message: @"the root component should not mount if opening the window fails first"];
    [AsyncRuntimeTestSupport assertCondition: (root.unmountCount == 0) message: @"cleanup should not fabricate an unmount for a component that never mounted"];
}

static void application_launch_renders_first_frame_and_cleans_up(AsyncScope *rootScope)
{
    AUITestLifecycleApplication *app = [[AUITestLifecycleApplication alloc] init];
    AUITestGroupComponent *root = [[AUITestGroupComponent alloc] init];
    AUITestSpyWindowBackend *windowBackend = [[AUITestSpyWindowBackend alloc] initWithApplication: app
                                                                                           options: app.windowOptions];
    AUICairoRendererBackend *rendererBackend = [[AUICairoRendererBackend alloc] initWithApplication: app];
    id value;

    root.bodyChildren = @[
        [AUILabel text: @"Hello"]
    ];
    windowBackend.closeAfterNextRender = true;
    app.providedRootComponent = root;
    app.providedWindowBackend = windowBackend;
    app.providedRendererBackend = rendererBackend;

    value = [app applicationDidFinishLaunchingAsync: nilptr scope: rootScope];

    [AsyncRuntimeTestSupport assertCondition: ([value respondsToSelector: @selector(intValue)] and ((int)[value intValue]) == 0)
                                     message: @"application launch should resolve to a zero exit status when the window closes cleanly"];
    [AsyncRuntimeTestSupport assertCondition: (windowBackend.openCount == 1) message: @"application launch should open the window once"];
    [AsyncRuntimeTestSupport assertCondition: (windowBackend.pollCount == 1) message: @"the event loop should poll once before the first frame render"];
    [AsyncRuntimeTestSupport assertCondition: (windowBackend.renderCount == 1) message: @"the startup render request should produce a first frame"];
    [AsyncRuntimeTestSupport assertCondition: (windowBackend.closeCount == 1) message: @"the backend should close during cleanup after the window exits"];
    [AsyncRuntimeTestSupport assertCondition: (root.mountCount == 1) message: @"the root component should mount during application launch"];
    [AsyncRuntimeTestSupport assertCondition: (root.unmountCount == 1) message: @"the root component should unmount during application cleanup"];
}

static void application_launch_processes_multiple_async_render_requests(AsyncScope *rootScope)
{
    AUITestLifecycleApplication *app = [[AUITestLifecycleApplication alloc] init];
    AUITestAsyncRenderLoopComponent *root = [[AUITestAsyncRenderLoopComponent alloc] init];
    AUITestSpyWindowBackend *windowBackend = [[AUITestSpyWindowBackend alloc] initWithApplication: app
                                                                                           options: app.windowOptions];
    AUICairoRendererBackend *rendererBackend = [[AUICairoRendererBackend alloc] initWithApplication: app];
    id value;

    windowBackend.closeAfterRenderCount = 3;
    app.providedRootComponent = root;
    app.providedWindowBackend = windowBackend;
    app.providedRendererBackend = rendererBackend;

    value = [app applicationDidFinishLaunchingAsync: nilptr scope: rootScope];

    [AsyncRuntimeTestSupport assertCondition: ([value respondsToSelector: @selector(intValue)] and ((int)[value intValue]) == 0)
                                     message: @"application launch should still resolve cleanly after multiple async-driven rerenders"];
    [AsyncRuntimeTestSupport assertCondition: (windowBackend.openCount == 1) message: @"the window backend should still only open once"];
    [AsyncRuntimeTestSupport assertCondition: (windowBackend.pollCount >= 3) message: @"the event loop should continue polling while async updates request more frames"];
    [AsyncRuntimeTestSupport assertCondition: (windowBackend.renderCount == 3) message: @"async signal invalidations should drive multiple frame renders before shutdown"];
    [AsyncRuntimeTestSupport assertCondition: (root.lastRenderedPhase == 2) message: @"the root component body should observe the final async-updated signal value before exit"];
}

static void objfw_bridge_string_round_trip(AsyncScope *rootScope)
{
    (void)rootScope;

#if defined(__APPLE__)
    AUIWindowOptions *options = AUIWindowOptions.defaultOptions;
    OFString *copiedTitle;

    copiedTitle = [AUICocoaWindowBackend _roundTripBridgedStringForTesting: options.title];
    [AsyncRuntimeTestSupport assertCondition: (copiedTitle != nilptr)
                                     message: @"ObjFWBridge should convert the default window title through the Cocoa backend at runtime"];
    [AsyncRuntimeTestSupport assertCondition: [copiedTitle isEqual: options.title]
                                     message: @"OFString to NSString bridging should round-trip through the Cocoa backend without losing content"];
#endif
}

static void cocoa_backend_prepares_foreground_application(AsyncScope *rootScope)
{
    (void)rootScope;

#if defined(__APPLE__)
    bool prepared = [AUICocoaWindowBackend _prepareSharedApplicationForTesting];

    [AsyncRuntimeTestSupport assertCondition: prepared
                                     message: @"the Cocoa backend should be able to create a shared NSApplication instance"];
    [AsyncRuntimeTestSupport assertCondition: [AUICocoaWindowBackend _sharedApplicationIsForegroundForTesting]
                                     message: @"the Cocoa backend should promote the process to a foreground app so windows can appear"];
    [AsyncRuntimeTestSupport assertCondition: [AUICocoaWindowBackend _sharedApplicationHasMainMenuForTesting]
                                     message: @"the Cocoa backend should install a main menu so the shared NSApplication behaves like a real Cocoa app"];
#endif
}

static void cocoa_backend_open_perform_close_and_cleanup(AsyncScope *rootScope)
{
    (void)rootScope;

#if defined(__APPLE__)
    AUITestLifecycleApplication *application = [[AUITestLifecycleApplication alloc] init];
    AUICocoaWindowBackend *backend = [[AUICocoaWindowBackend alloc]
        initWithApplication: application
                    options: [AUIWindowOptions title: @"Cocoa Backend Smoke"
                                              size: (AUISize){ 160, 96 }
                                         resizable: false]];
    size_t windowCountBefore = [AUICocoaWindowBackend _sharedApplicationWindowCountForTesting];

    [backend openWindow];
    [backend pollEvents];
    [backend pollEvents];
    [AsyncRuntimeTestSupport assertCondition: backend.isOpen
                                     message: @"opening the Cocoa backend should create a live window backend session"];
    [AsyncRuntimeTestSupport assertCondition: ([AUICocoaWindowBackend _sharedApplicationWindowCountForTesting] == windowCountBefore + 1)
                                     message: @"opening the Cocoa backend should add exactly one Cocoa window"];
    [AsyncRuntimeTestSupport assertCondition: [backend _windowIsVisibleForTesting]
                                     message: @"opening the Cocoa backend should create a visible window"];
    [AsyncRuntimeTestSupport assertCondition: [AUICocoaWindowBackend _sharedApplicationHasMainMenuForTesting]
                                     message: @"opening the Cocoa backend should preserve the shared Cocoa main menu"];
    [AsyncRuntimeTestSupport assertCondition: [backend _renderViewIsFirstResponderForTesting]
                                     message: @"opening the Cocoa backend should make the render view first responder for keyboard input"];

    [backend openWindow];
    [backend pollEvents];
    [AsyncRuntimeTestSupport assertCondition: ([AUICocoaWindowBackend _sharedApplicationWindowCountForTesting] == windowCountBefore + 1)
                                     message: @"opening the Cocoa backend twice should not create a second window"];

    [backend closeWindow];
    [backend pollEvents];
    [backend pollEvents];
    [AsyncRuntimeTestSupport assertCondition: (not backend.isOpen)
                                     message: @"closing the Cocoa backend directly should leave it out of the open state"];
    [AsyncRuntimeTestSupport assertCondition: ([AUICocoaWindowBackend _sharedApplicationWindowCountForTesting] == windowCountBefore)
                                     message: @"closing the Cocoa backend directly should release the Cocoa window reference from the shared application"];

    [backend closeWindow];
    [AsyncRuntimeTestSupport assertCondition: (not backend.isOpen)
                                     message: @"closing the Cocoa backend directly twice should remain idempotent"];
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

    [AsyncRuntimeTestSupport assertCondition: ([app.headlessWindowBackend.clipboardText isEqual: @"alpha"])
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
    [app ensureBackendWithWidth: 320 height: 240];
    [app.headlessWindowBackend sendPointerMoveToX: 40 y: 40];
    [app.headlessWindowBackend sendScrollByX: 0 y: -3];
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
ASYNC_RUNTIME_ASYNC_TEST(objfw_bridge_string_round_trip)
ASYNC_RUNTIME_ASYNC_TEST(cocoa_backend_prepares_foreground_application)
ASYNC_RUNTIME_ASYNC_TEST(cocoa_backend_open_perform_close_and_cleanup)
ASYNC_RUNTIME_ASYNC_TEST(button_press_invokes_callback)
ASYNC_RUNTIME_ASYNC_TEST(toggle_and_radio_controls_dispatch_controlled_changes)
ASYNC_RUNTIME_ASYNC_TEST(text_fields_focus_edit_submit_and_tab_navigation)
ASYNC_RUNTIME_ASYNC_TEST(text_area_secure_mask_scroll_and_stable_focus)
ASYNC_RUNTIME_ASYNC_TEST(clipboard_shortcuts_round_trip_through_backend)
ASYNC_RUNTIME_ASYNC_TEST(context_menu_opens_activates_and_dismisses)

#pragma clang assume_nonnull end
