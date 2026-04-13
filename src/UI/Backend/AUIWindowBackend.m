#import "UI/Backend/AUIWindowBackend.h"
#import "UI/AUIApplication.h"

#pragma clang assume_nonnull begin

@implementation AUIWindowBackend {
    AUIApplication *_application;
    AUIWindowOptions *_options;
}

@synthesize application = _application;
@synthesize options = _options;

- (instancetype)initWithApplication: (AUIApplication *nillable)application
                            options: (AUIWindowOptions *nillable)options
{
    if (application == nilptr or options == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _application = $assert_nonnil(application);
    _options = $assert_nonnil(options);
    return self;
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

- (void)openWindow
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (void)pollEvents
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

@end

#pragma clang assume_nonnull end
