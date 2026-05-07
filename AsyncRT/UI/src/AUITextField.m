#import "AUITextField.h"
#import "AUIContextMenu.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUITextField

+ (instancetype)withText: (OFString *nillable)text
              placeholder: (OFString *)placeholder
                styledBy: (AUIControlStyle *)style
              contextMenu: (AUIContextMenu *nillable)contextMenu
                onChange: (AUITextChangeHandler nillable)changeHandler
                onSubmit: (AUITextSubmitHandler nillable)submitHandler
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
                        style: (AUIControlStyle *)style
                   contextMenu: (AUIContextMenu *nillable)contextMenu
                     onChange: (AUITextChangeHandler nillable)changeHandler
                     onSubmit: (AUITextSubmitHandler nillable)submitHandler
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

- (AUIContentKind)contentKind
{
    return AUIContentKindTextField;
}

@end

#pragma clang assume_nonnull end
