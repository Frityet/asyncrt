#import "UI/Components/Forms/AUITextInput.h"

#pragma clang assume_nonnull begin

@interface AUITextInput ()

- (instancetype)initWithText: (OFString *nillable)text
                 placeholder: (OFString *nillable)placeholder
                       style: (AUITextStyle)style
                      colors: (AUITextInputColors)colors
                      layout: (AUILayout)layout
                      radius: (float)cornerRadius
                     enabled: (bool)enabled
                      secure: (bool)secure
                   multiline: (bool)multiline
                    onChange: (void (^nillable)(OFString *text))changeHandler
                    onSubmit: (void (^nillable)(OFString *text))submitHandler [[designated_initailiser]];

@end

@implementation AUITextInput {
    OFString *nillable _text;
    OFString *_placeholder;
    AUITextStyle _style;
    AUITextInputColors _colors;
    AUILayout _layout;
    float _cornerRadius;
    bool _enabled;
    bool _secure;
    bool _multiline;
    void (^nillable _changeHandler)(OFString *text);
    void (^nillable _submitHandler)(OFString *text);
}

@synthesize isEnabled = _enabled;
@synthesize isSecure = _secure;
@synthesize isMultiline = _multiline;

+ (instancetype)text: (OFString *nillable)text
         placeholder: (OFString *nillable)placeholder
               style: (AUITextStyle)style
              colors: (AUITextInputColors)colors
              layout: (AUILayout)layout
              radius: (float)cornerRadius
             enabled: (bool)enabled
              secure: (bool)secure
           multiline: (bool)multiline
            onChange: (void (^nillable)(OFString *text))changeHandler
            onSubmit: (void (^nillable)(OFString *text))submitHandler
{
    return [[self alloc] initWithText: text
                          placeholder: placeholder
                                style: style
                               colors: colors
                               layout: layout
                               radius: cornerRadius
                              enabled: enabled
                               secure: secure
                            multiline: multiline
                             onChange: changeHandler
                             onSubmit: submitHandler];
}

- (instancetype)initWithText: (OFString *nillable)text
                 placeholder: (OFString *nillable)placeholder
                       style: (AUITextStyle)style
                      colors: (AUITextInputColors)colors
                      layout: (AUILayout)layout
                      radius: (float)cornerRadius
                     enabled: (bool)enabled
                      secure: (bool)secure
                   multiline: (bool)multiline
                    onChange: (void (^nillable)(OFString *text))changeHandler
                    onSubmit: (void (^nillable)(OFString *text))submitHandler
{
    self = [super init];
    _text = [text copy];
    _placeholder = [(placeholder ?: @"") copy];
    _style = style;
    _colors = colors;
    _layout = layout;
    _cornerRadius = cornerRadius;
    _enabled = enabled;
    _secure = secure;
    _multiline = multiline;
    _changeHandler = [changeHandler copy];
    _submitHandler = [submitHandler copy];
    return self;
}

@end

#pragma clang assume_nonnull end
