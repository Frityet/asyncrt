#include <math.h>
#include <stdlib.h>

#import "Backend/AUIWindow.h"
#import "AUIClaySupport.h"
#import "AUIInternal.h"

#pragma clang assume_nonnull begin

@namespace(AUIWindowSupport)

+ (bool)viewportSize: (AUISize)left equals: (AUISize)right;
+ (AUISize)viewportSizeForBoundingBox: (Clay_BoundingBox)boundingBox;
+ (AUISize)viewportSizeForCommands: (Clay_RenderCommandArray)commands
                            fallback: (AUISize)fallback;

@end

@namespace_implementation(AUIWindowSupport)

+ (bool)viewportSize: (AUISize)left equals: (AUISize)right
{
    return (left.width == right.width and left.height == right.height);
}

+ (AUISize)viewportSizeForBoundingBox: (Clay_BoundingBox)boundingBox
{
    float width;
    float height;

    width = ceilf(boundingBox.width);
    height = ceilf(boundingBox.height);
    if (width < 1.0f)
        width = 1.0f;
    if (height < 1.0f)
        height = 1.0f;

    return [AUI sizeWithWidth: width height: height];
}

+ (AUISize)viewportSizeForCommands: (Clay_RenderCommandArray)commands
                            fallback: (AUISize)fallback
{
    float minX = 0;
    float minY = 0;
    float maxX = 0;
    float maxY = 0;
    bool sawBounds = false;

    for (int32_t index = 0; index < commands.length; index++) {
        Clay_RenderCommand *command = Clay_RenderCommandArray_Get(&commands, index);
        Clay_BoundingBox boundingBox;

        if (command == nullptr or command->zIndex >= 32767)
            continue;

        switch (command->commandType) {
            case CLAY_RENDER_COMMAND_TYPE_RECTANGLE:
            case CLAY_RENDER_COMMAND_TYPE_BORDER:
            case CLAY_RENDER_COMMAND_TYPE_TEXT:
            case CLAY_RENDER_COMMAND_TYPE_IMAGE:
            case CLAY_RENDER_COMMAND_TYPE_SCISSOR_START:
            case CLAY_RENDER_COMMAND_TYPE_CUSTOM:
                break;
            case CLAY_RENDER_COMMAND_TYPE_NONE:
            case CLAY_RENDER_COMMAND_TYPE_SCISSOR_END:
            case CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_START:
            case CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_END:
                continue;
        }

        boundingBox = command->boundingBox;
        if (not sawBounds) {
            minX = boundingBox.x;
            minY = boundingBox.y;
            maxX = boundingBox.x + boundingBox.width;
            maxY = boundingBox.y + boundingBox.height;
            sawBounds = true;
            continue;
        }

        if (boundingBox.x < minX)
            minX = boundingBox.x;
        if (boundingBox.y < minY)
            minY = boundingBox.y;
        if (boundingBox.x + boundingBox.width > maxX)
            maxX = boundingBox.x + boundingBox.width;
        if (boundingBox.y + boundingBox.height > maxY)
            maxY = boundingBox.y + boundingBox.height;
    }

    if (not sawBounds)
        return fallback;

    return [self viewportSizeForBoundingBox: (Clay_BoundingBox){
        .x = minX,
        .y = minY,
        .width = maxX - minX,
        .height = maxY - minY
    }];
}

@end

[[direct_members]]
@implementation AUIWindow {
    AUIApplication *_application;
    AUIWindowOptions *_options;
    void *nillable _clayMemory;
    size_t _clayMemorySize;
    Clay_Context *nillable _clayContext;
    bool _darkMode;
    bool _hasExplicitDarkMode;
}


- (instancetype)initWithApplication: (AUIApplication *nillable)application
                            options: (AUIWindowOptions *nillable)options
{
    if (application == nilptr or options == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _application = $assert_nonnil(application);
    _options = $assert_nonnil(options);
    _clayMemory = nullptr;
    _clayMemorySize = 0;
    _clayContext = nullptr;
    _darkMode = false;
    _hasExplicitDarkMode = false;
    return self;
}

- (void)dealloc
{
    if (_clayMemory != nullptr)
        free(_clayMemory);
}

- (bool)isOpen
{
    return false;
}

- (AUISize)viewportSize
{
    return (AUISize){ 0, 0 };
}

- (double)scaleFactor
{
    return 1.0;
}

- (bool)isDarkMode
{
    return _darkMode;
}

- (void)setIsDarkMode: (bool)darkMode
{
    [self _setDarkMode: darkMode explicitly: true];
}

- (void)openWindow
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (void)pollEvents
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (void)renderFrame
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (void)closeWindow
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (void)setCursorStyle: (AUICursorStyle)cursorStyle
{
    (void)cursorStyle;
}

- (OFString *nillable)clipboardText
{
    return nilptr;
}

- (void)setClipboardText: (OFString *nillable)text
{
    (void)text;
}

- (void)_setDarkMode: (bool)darkMode explicitly: (bool)explicitly
{
    bool didChange = (_darkMode != darkMode);
    bool explicitStateChanged = (_hasExplicitDarkMode != explicitly);

    if (not didChange and not explicitStateChanged)
        return;

    _darkMode = darkMode;
    _hasExplicitDarkMode = explicitly;

    if (didChange)
        [self.application setNeedsRender];
}

- (bool)_hasExplicitDarkMode
{
    return _hasExplicitDarkMode;
}

- (void)_setViewportSize: (AUISize)viewportSize
{
    (void)viewportSize;
}

- (void)_prepareClayContextForViewportSize: (AUISize)viewportSize
{
    OFString *nillable clayError = nilptr;

    if (_clayMemory == nullptr) {
        _clayMemorySize = [AUIClay minimumMemorySize];
        _clayMemory = malloc(_clayMemorySize);
        if (_clayMemory == nullptr)
            @throw [[AUIInitializationException alloc] initWithReason: @"Failed to allocate the Clay arena"];

        [AUIClay clearError];
        _clayContext = [AUIClay initializeWithMemory: $assert_nonnil(_clayMemory)
                                                size: _clayMemorySize
                                          dimensions: viewportSize];
        clayError = [AUIClay consumeError];
        if (clayError != nilptr)
            @throw [[AUIInitializationException alloc] initWithReason: $assert_nonnil(clayError)];
    }

    AUIClay.currentContext = _clayContext;
    AUIClay.layoutDimensions = viewportSize;
}

- (Clay_RenderCommandArray)_buildRenderCommandsOnceForViewportSize: (AUISize)viewportSize
                                                textMeasureFunction: (AUITextMeasureFunction)textMeasureFunction
                                                           userData: (void *nillable)userData
{
    AUIInputState *inputState;
    Clay_RenderCommandArray commands;
    OFString *nillable clayError = nilptr;

    if (textMeasureFunction == (AUITextMeasureFunction)nullptr)
        @throw [OFInvalidArgumentException exception];

    [AUIClay clearError];
    [self _prepareClayContextForViewportSize: viewportSize];
    Clay_SetMeasureTextFunction(textMeasureFunction, userData);
    inputState = self.application._inputState;
    [AUIClay setPointerPositionX: inputState.pointerX
                                y: inputState.pointerY
                             down: inputState.isPrimaryButtonDown];
    commands = [self.application _buildRenderCommandsWithViewportSize: viewportSize
                                                            deltaTime: (1.0f / 60.0f)];

    clayError = [AUIClay consumeError];
    if (clayError != nilptr)
        @throw [[AUIRenderException alloc] initWithReason: $assert_nonnil(clayError)];

    return commands;
}

- (Clay_RenderCommandArray)_buildRenderCommandsForViewportSize: (AUISize)viewportSize
                                           textMeasureFunction: (AUITextMeasureFunction)textMeasureFunction
                                                      userData: (void *nillable)userData
{
    AUISize currentViewportSize = viewportSize;
    Clay_RenderCommandArray commands = [self _buildRenderCommandsOnceForViewportSize: currentViewportSize
                                                                  textMeasureFunction: textMeasureFunction
                                                                             userData: userData];

    if (not self.options.automaticallyResizesToRootComponent)
        return commands;

    for (size_t iteration = 0; iteration < 3; iteration++) {
        Clay_ElementData rootElementData = [AUIClay elementDataForID: [AUIClay elementIDFromString: @"root"]];
        AUISize resizedViewportSize = (rootElementData.found
            ? [AUIWindowSupport viewportSizeForBoundingBox: rootElementData.boundingBox]
            : [AUIWindowSupport viewportSizeForCommands: commands fallback: currentViewportSize]);

        if ([AUIWindowSupport viewportSize: resizedViewportSize equals: currentViewportSize])
            break;

        [self _setViewportSize: resizedViewportSize];
        [self.application setNeedsRender];
        currentViewportSize = self.viewportSize;
        if ([AUIWindowSupport viewportSize: currentViewportSize equals: resizedViewportSize])
            commands = [self _buildRenderCommandsOnceForViewportSize: currentViewportSize
                                                 textMeasureFunction: textMeasureFunction
                                                            userData: userData];
    }

    return commands;
}

@end

#pragma clang assume_nonnull end
