#include <math.h>
#include <stdlib.h>

#import <AsyncRT/Application/UI/Surface/Immediate/Exceptions.h>
#import <AsyncRT/Application/UI/Surface/Immediate/ClaySupport.h>
#import <AsyncRT/Application/UI/Window/Window+Private.h>
#import <AsyncRT/Application/UI/Window/Window.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/Application+Private.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Internal/InputState.h>

#pragma clang assume_nonnull begin

@namespace(AsyncUIWindowSupport)

+ (bool)viewportSize: (AsyncUISize)left equals: (AsyncUISize)right;
+ (float)scaledDimensionForNativeDimension: (float)nativeDimension contentScale: (double)contentScale;
+ (AsyncUISize)viewportSizeForNativeSize: (AsyncUISize)nativeSize contentScale: (double)contentScale;
+ (AsyncUISize)viewportSizeForBoundingBox: (Clay_BoundingBox)boundingBox;
+ (AsyncUISize)viewportSizeForCommands: (Clay_RenderCommandArray)commands
                            fallback: (AsyncUISize)fallback;

@end

@namespace_implementation(AsyncUIWindowSupport)

+ (bool)viewportSize: (AsyncUISize)left equals: (AsyncUISize)right
{
    return (left.width == right.width and left.height == right.height);
}

+ (float)scaledDimensionForNativeDimension: (float)nativeDimension contentScale: (double)contentScale
{
    if (nativeDimension <= 0.0f)
        return 0.0f;

    const float scaledDimension = nativeDimension / (float)contentScale;
    if (scaledDimension < 1.0f)
        return 1.0f;

    return scaledDimension;
}

+ (AsyncUISize)viewportSizeForNativeSize: (AsyncUISize)nativeSize contentScale: (double)contentScale
{
    return [AsyncUI sizeWithWidth: [self scaledDimensionForNativeDimension: nativeSize.width contentScale: contentScale]
                       height: [self scaledDimensionForNativeDimension: nativeSize.height contentScale: contentScale]];
}

+ (AsyncUISize)viewportSizeForBoundingBox: (Clay_BoundingBox)boundingBox
{
    float width = ceilf(boundingBox.width);
    float height = ceilf(boundingBox.height);
    if (width < 1.0f)
        width = 1.0f;
    if (height < 1.0f)
        height = 1.0f;

    return [AsyncUI sizeWithWidth: width height: height];
}

+ (AsyncUISize)viewportSizeForCommands: (Clay_RenderCommandArray)commands
                            fallback: (AsyncUISize)fallback
{
    float minX = 0;
    float minY = 0;
    float maxX = 0;
    float maxY = 0;
    bool sawBounds = false;

    for (int32_t index = 0; index < commands.length; index++) {
        Clay_RenderCommand *command = Clay_RenderCommandArray_Get(&commands, index);

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

        const Clay_BoundingBox boundingBox = command->boundingBox;
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
@implementation AsyncUIWindow {
    AsyncImmediateUIApplication *_application;
    AsyncUIWindowConfiguration *_configuration;
    void *nillable _clayMemory;
    size_t _clayMemorySize;
    Clay_Context *nillable _clayContext;
    bool _darkMode;
    bool _hasExplicitDarkMode;
    AsyncUISize _referenceViewportSize;
}


- (instancetype)initWithApplication: (AsyncImmediateUIApplication *nonnil)application
                      configuration: (AsyncUIWindowConfiguration *nonnil)configuration
{
    self = [super init];
    _application = application;
    _configuration = configuration;
    _clayMemory = nullptr;
    _clayMemorySize = 0;
    _clayContext = nullptr;
    _darkMode = false;
    _hasExplicitDarkMode = false;
    _referenceViewportSize = [AsyncUIWindowSupport viewportSizeForNativeSize: configuration.initialSize
                                                            contentScale: configuration.contentScale];
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

- (AsyncUISize)viewportSize
{
    return (AsyncUISize){ 0, 0 };
}

- (double)scaleFactor
{
    return 1.0;
}

- (double)_contentScale
{
    return self.configuration.contentScale;
}

- (bool)_scalesWithWindowSize
{
    return self.configuration.scalesWithWindowSize;
}

- (AsyncUISize)_viewportSizeForNativeSize: (AsyncUISize)nativeSize
{
    if ([self _scalesWithWindowSize])
        return _referenceViewportSize;

    return [AsyncUIWindowSupport viewportSizeForNativeSize: nativeSize contentScale: [self _contentScale]];
}

- (AsyncUISize)_nativeSizeForViewportSize: (AsyncUISize)viewportSize
{
    return [AsyncUI sizeWithWidth: viewportSize.width * (float)[self _contentScale]
                       height: viewportSize.height * (float)[self _contentScale]];
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

- (void)setCursorStyle: (AsyncUICursorStyle)cursorStyle
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

- (void)_setViewportSize: (AsyncUISize)viewportSize
{
    if ([self _scalesWithWindowSize])
        _referenceViewportSize = viewportSize;
}

- (void)_prepareClayContextForViewportSize: (AsyncUISize)viewportSize
{
    OFString *nillable clayError = nilptr;

    if (_clayMemory == nullptr) {
        _clayMemorySize = [AsyncUIClay minimumMemorySize];
        _clayMemory = malloc(_clayMemorySize);
        if (_clayMemory == nullptr)
            @throw [[AsyncUIInitializationException alloc] initWithReason: @"Failed to allocate the Clay arena"];

        [AsyncUIClay clearError];
        _clayContext = [AsyncUIClay initializeWithMemory: $assert_nonnil(_clayMemory)
                                                size: _clayMemorySize
                                          dimensions: viewportSize];
        clayError = [AsyncUIClay consumeError];
        if (clayError != nilptr)
            @throw [[AsyncUIInitializationException alloc] initWithReason: $assert_nonnil(clayError)];
    }

    AsyncUIClay.currentContext = _clayContext;
    AsyncUIClay.layoutDimensions = viewportSize;
}

- (Clay_RenderCommandArray)_buildRenderCommandsOnceForViewportSize: (AsyncUISize)viewportSize
                                                textMeasureFunction: (AsyncUITextMeasureFunction)textMeasureFunction
                                                           userData: (void *nillable)userData
{
    OFString *nillable clayError = nilptr;

    if (textMeasureFunction == (AsyncUITextMeasureFunction)nullptr)
        @throw [OFInvalidArgumentException exception];

    [AsyncUIClay clearError];
    [self _prepareClayContextForViewportSize: viewportSize];
    Clay_SetMeasureTextFunction(textMeasureFunction, userData);
    AsyncUIInputState *inputState = self.application._inputState;
    [AsyncUIClay updatePointerPositionX: inputState.pointerX
                                y: inputState.pointerY
                             down: inputState.isPrimaryButtonDown];
    Clay_RenderCommandArray commands = [self.application _buildRenderCommandsWithViewportSize: viewportSize
                                                                                     deltaTime: (1.0f / 60.0f)];

    clayError = [AsyncUIClay consumeError];
    if (clayError != nilptr)
        @throw [[AsyncUIRenderException alloc] initWithReason: $assert_nonnil(clayError)];

    return commands;
}

- (Clay_RenderCommandArray)_buildRenderCommandsForViewportSize: (AsyncUISize)viewportSize
                                           textMeasureFunction: (AsyncUITextMeasureFunction)textMeasureFunction
                                                      userData: (void *nillable)userData
{
    AsyncUISize currentViewportSize = viewportSize;
    Clay_RenderCommandArray commands = [self _buildRenderCommandsOnceForViewportSize: currentViewportSize
                                                                  textMeasureFunction: textMeasureFunction
                                                                             userData: userData];

    if (not self.configuration.automaticallyResizesToContent)
        return commands;

    for (size_t iteration = 0; iteration < 3; iteration++) {
        Clay_ElementData rootElementData = [AsyncUIClay elementDataForID: [AsyncUIClay elementIDFromString: @"root"]];
        AsyncUISize resizedViewportSize = (rootElementData.found
            ? [AsyncUIWindowSupport viewportSizeForBoundingBox: rootElementData.boundingBox]
            : [AsyncUIWindowSupport viewportSizeForCommands: commands fallback: currentViewportSize]);

        if ([AsyncUIWindowSupport viewportSize: resizedViewportSize equals: currentViewportSize])
            break;

        [self _setViewportSize: resizedViewportSize];
        [self.application setNeedsRender];
        currentViewportSize = self.viewportSize;
        if ([AsyncUIWindowSupport viewportSize: currentViewportSize equals: resizedViewportSize])
            commands = [self _buildRenderCommandsOnceForViewportSize: currentViewportSize
                                                 textMeasureFunction: textMeasureFunction
                                                            userData: userData];
    }

    return commands;
}

@end

#pragma clang assume_nonnull end
