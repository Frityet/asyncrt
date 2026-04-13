#import "UI/Components/Forms/AUITextArea.h"

#pragma clang assume_nonnull begin

@interface AUITextArea ()

- (instancetype)initWithText: (OFString *nillable)text
                 placeholder: (OFString *nillable)placeholder
                     enabled: (bool)enabled
                    onChange: (void (^nillable)(OFString *text))changeHandler
                    onSubmit: (void (^nillable)(OFString *text))submitHandler designated_initaliser;

@end

@implementation AUITextArea {
    OFString *nillable _text;
    OFString *_placeholder;
    bool _enabled;
    void (^nillable _changeHandler)(OFString *text);
    void (^nillable _submitHandler)(OFString *text);
}

@synthesize text = _text;
@synthesize placeholder = _placeholder;
@synthesize enabled = _enabled;
@synthesize changeHandler = _changeHandler;
@synthesize submitHandler = _submitHandler;

+ (instancetype)text: (OFString *nillable)text
         placeholder: (OFString *nillable)placeholder
             enabled: (bool)enabled
            onChange: (void (^nillable)(OFString *text))changeHandler
            onSubmit: (void (^nillable)(OFString *text))submitHandler
{
    return [[self alloc] initWithText: text
                          placeholder: placeholder
                              enabled: enabled
                             onChange: changeHandler
                             onSubmit: submitHandler];
}

- (instancetype)initWithText: (OFString *nillable)text
                 placeholder: (OFString *nillable)placeholder
                     enabled: (bool)enabled
                    onChange: (void (^nillable)(OFString *text))changeHandler
                    onSubmit: (void (^nillable)(OFString *text))submitHandler
{
    self = [super init];
    _text = [text copy];
    _placeholder = [(placeholder ?: @"") copy];
    _enabled = enabled;
    _changeHandler = [changeHandler copy];
    _submitHandler = [submitHandler copy];
    return self;
}

- (id<AUIRenderable>)renderableBody
{
    AUILayout layout = [AUI layout];

    layout.height = [AUI axisFixed: 120];
    layout.padding = [AUI insetsWithLeft: 14 right: 14 top: 12 bottom: 12];
    layout.width = [AUI axisGrow: 0];

    return [AUITextInput text: _text
                  placeholder: _placeholder
                        style: [AUIComponents inputTextStyleForSize: AUIControlSizeMedium]
                       colors: [AUIComponents inputColors]
                       layout: layout
                       radius: [AUIComponents controlCornerRadiusForSize: AUIControlSizeMedium]
                      enabled: _enabled
                       secure: false
                    multiline: true
                     onChange: _changeHandler
                     onSubmit: _submitHandler];
}

@end

#pragma clang assume_nonnull end
