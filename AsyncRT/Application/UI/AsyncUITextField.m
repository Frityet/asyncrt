#import <AsyncRT/Application/UI/AsyncUITextField.h>
#import <AsyncRT/Application/UI/AsyncUIContextMenu.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUITextField

+ (instancetype)withText: (OFString *nillable)text
              placeholder: (OFString *)placeholder
                styledBy: (AsyncUIControlStyle *)style
              contextMenu: (AsyncUIContextMenu *nillable)contextMenu
                onChange: (AsyncUITextChangeHandler nillable)changeHandler
                onSubmit: (AsyncUITextSubmitHandler nillable)submitHandler
                 enabled: (bool)isEnabled
                  secure: (bool)isSecure
{
    return [[self alloc] initWithText: text
                           placeholder: placeholder
                                 style: style
                            contextMenu: contextMenu
                              onChange: changeHandler
                              onSubmit: submitHandler
                               enabled: isEnabled
                                secure: isSecure];
}

- (instancetype)initWithText: (OFString *nillable)text
                  placeholder: (OFString *)placeholder
                        style: (AsyncUIControlStyle *)style
                   contextMenu: (AsyncUIContextMenu *nillable)contextMenu
                     onChange: (AsyncUITextChangeHandler nillable)changeHandler
                     onSubmit: (AsyncUITextSubmitHandler nillable)submitHandler
                      enabled: (bool)isEnabled
                       secure: (bool)isSecure
{
    self = [super init];
    _text = [text copy];
    _placeholder = [placeholder copy];
    _style = style;
    _contextMenu = contextMenu;
    _changeHandler = [changeHandler copy];
    _submitHandler = [submitHandler copy];
    _isEnabled = isEnabled;
    _isSecure = isSecure;
    return self;
}

- (AsyncUIContentKind)contentKind
{
    return AsyncUIContentKindTextField;
}

@end

#pragma clang assume_nonnull end
