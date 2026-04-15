#pragma once

#import "AUIRenderable.h"
#import "Backend/AUIInput.h"
#import "Components/AUIValues.h"
#import "Components/Controls/AUIContextMenu.h"

#pragma clang assume_nonnull begin

typedef enum [[clang::enum_extensibility(closed)]] AUIViewNodeFamily {
    AUIViewNodeFamilyFragment,
    AUIViewNodeFamilyBox,
    AUIViewNodeFamilyText,
    AUIViewNodeFamilyEditableText
} AUIViewNodeFamily;

[[subclassing_restricted, direct_members]]
@interface AUIViewInteractionConfiguration : OFObject

@property(readonly, nonatomic) bool isEnabled;
@property(readonly, nonatomic) bool isFocusable;
@property(readonly, nonatomic) AUICursorStyle cursorStyle;
@property(readonly, nonatomic) bool usesInteractiveBackgroundColors;
@property(readonly, nonatomic) AUIControlColors interactiveBackgroundColors;
@property(readonly, retain, nonatomic) AUIContextMenu *nillable contextMenu;
@property(readonly, copy, nonatomic) void (^nillable activationHandler)(void);

+ (instancetype)enabled: (bool)isEnabled
              focusable: (bool)isFocusable
            cursorStyle: (AUICursorStyle)cursorStyle
             background: (AUIControlColors)interactiveBackgroundColors
             onActivate: (void (^nillable)(void))activationHandler
            contextMenu: (AUIContextMenu *nillable)contextMenu;
+ (instancetype)enabled: (bool)isEnabled
              focusable: (bool)isFocusable
            cursorStyle: (AUICursorStyle)cursorStyle
             onActivate: (void (^nillable)(void))activationHandler
            contextMenu: (AUIContextMenu *nillable)contextMenu;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AUIViewNode : OFObject<AUIRenderable>

@property(readonly, nonatomic) AUIViewNodeFamily nodeFamily;
@property(readonly, copy, nonatomic) OFString *nillable stableKey;

- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AUIViewFragmentNode : AUIViewNode

@property(readonly, copy, nonatomic) OFArray<id<AUIRenderable>> *children;

+ (instancetype)fragmentNodeWithChildren: (OFArray<id<AUIRenderable>> *nonnil)children;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AUIViewBoxNode : AUIViewNode

@property(readonly, nonatomic) AUIBoxProps boxProps;
@property(readonly, retain, nonatomic) AUIViewInteractionConfiguration *nillable interactionConfiguration;
@property(readonly, copy, nonatomic) OFArray<id<AUIRenderable>> *children;

+ (instancetype)boxNodeWithKey: (OFString *nillable)stableKey
                      boxProps: (AUIBoxProps)boxProps
        interactionConfiguration: (AUIViewInteractionConfiguration *nillable)interactionConfiguration
                      children: (OFArray<id<AUIRenderable>> *nonnil)children;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AUIViewTextNode : AUIViewNode

@property(readonly, copy, nonatomic) OFString *text;
@property(readonly, nonatomic) AUITextStyle textStyle;

+ (instancetype)textNodeWithText: (OFString *nonnil)text style: (AUITextStyle)textStyle;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AUIViewEditableTextNode : AUIViewNode

@property(readonly, copy, nonatomic) OFString *nillable text;
@property(readonly, copy, nonatomic) OFString *placeholder;
@property(readonly, nonatomic) AUITextStyle textStyle;
@property(readonly, nonatomic) AUITextInputColors colors;
@property(readonly, nonatomic) AUILayout layout;
@property(readonly, nonatomic) float cornerRadius;
@property(readonly, nonatomic) bool isEnabled;
@property(readonly, nonatomic) bool isSecure;
@property(readonly, nonatomic) bool isMultiline;
@property(readonly, retain, nonatomic) AUIContextMenu *nillable contextMenu;
@property(readonly, copy, nonatomic) void (^nillable textChangeHandler)(OFString *text);
@property(readonly, copy, nonatomic) void (^nillable submitHandler)(OFString *text);

+ (instancetype)editableTextNodeWithKey: (OFString *nillable)stableKey
                                   text: (OFString *nillable)text
                            placeholder: (OFString *nonnil)placeholder
                                  style: (AUITextStyle)textStyle
                                 colors: (AUITextInputColors)colors
                                 layout: (AUILayout)layout
                           cornerRadius: (float)cornerRadius
                                enabled: (bool)isEnabled
                                 secure: (bool)isSecure
                              multiline: (bool)isMultiline
                            contextMenu: (AUIContextMenu *nillable)contextMenu
                               onChange: (void (^nillable)(OFString *text))textChangeHandler
                               onSubmit: (void (^nillable)(OFString *text))submitHandler;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
