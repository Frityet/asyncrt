#pragma once

#import <AsyncRT/Application/UI/Surface/Web/View.h>

#pragma clang assume_nonnull begin

@class AsyncWebUIDocument;
@class AsyncWebUIElement;

enum [[clang::enum_extensibility(closed)]] AsyncWebUIDOMMutationKind {
    AsyncWebUIDOMMutationKindSetText,
    AsyncWebUIDOMMutationKindSetHTML,
    AsyncWebUIDOMMutationKindSetAttribute,
    AsyncWebUIDOMMutationKindRemoveAttribute,
    AsyncWebUIDOMMutationKindSetStyleProperty,
    AsyncWebUIDOMMutationKindAddClass,
    AsyncWebUIDOMMutationKindRemoveClass,
    AsyncWebUIDOMMutationKindToggleClass
};

[[subclassing_restricted, direct_members]]
@interface AsyncWebUIDOMMutation : OFObject

@property(readonly, nonatomic) enum AsyncWebUIDOMMutationKind kind;
@property(readonly, copy, nonatomic) OFString *selector;
@property(readonly, copy, nonatomic) OFString *nillable name;
@property(readonly, copy, nonatomic) OFString *nillable value;
@property(readonly, nonatomic) bool flag;

+ (instancetype)setText: (OFString *)text selector: (OFString *)selector;
+ (instancetype)setHTML: (OFString *)HTML selector: (OFString *)selector;
+ (instancetype)setAttribute: (OFString *)name value: (OFString *)value selector: (OFString *)selector;
+ (instancetype)removeAttribute: (OFString *)name selector: (OFString *)selector;
+ (instancetype)setStyleProperty: (OFString *)name value: (OFString *)value selector: (OFString *)selector;
+ (instancetype)addClass: (OFString *)className selector: (OFString *)selector;
+ (instancetype)removeClass: (OFString *)className selector: (OFString *)selector;
+ (instancetype)toggleClass: (OFString *)className enabled: (bool)enabled selector: (OFString *)selector;
- (instancetype)initWithKind: (enum AsyncWebUIDOMMutationKind)kind
                    selector: (OFString *)selector
                        name: (OFString *nillable)name
                       value: (OFString *nillable)value
                        flag: (bool)flag [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncWebUIDocument : OFObject

@property(readonly, nonatomic) AsyncWebUIView *webView;

- (instancetype)initWithWebView: (AsyncWebUIView *)webView [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (AsyncWebUIElement *)elementMatchingSelector: (OFString *)selector;
- (AsyncTask<id> *)taskToEvaluateExpression: (OFString *)javaScriptExpression;
- (AsyncTask<OFArray<id> *> *)taskToApplyMutations: (OFArray<AsyncWebUIDOMMutation *> *)mutations;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncWebUIElement : OFObject

@property(readonly, nonatomic) AsyncWebUIDocument *document;
@property(readonly, copy, nonatomic) OFString *selector;

- (instancetype)initWithDocument: (AsyncWebUIDocument *)document
                        selector: (OFString *)selector [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (AsyncTask<OFNumber *> *)taskToExists;
- (AsyncTask<OFString *> *)taskToReadText;
- (AsyncTask<OFDictionary<OFString *, id> *> *)taskToMeasure;
- (AsyncTask<OFArray<id> *> *)taskToApplyMutations: (OFArray<AsyncWebUIDOMMutation *> *)mutations;
- (AsyncTask<OFArray<id> *> *)taskToSetText: (OFString *)text;
- (AsyncTask<OFArray<id> *> *)taskToSetHTML: (OFString *)HTML;
- (AsyncTask<OFArray<id> *> *)taskToSetAttribute: (OFString *)name value: (OFString *)value;
- (AsyncTask<OFArray<id> *> *)taskToRemoveAttribute: (OFString *)name;
- (AsyncTask<OFArray<id> *> *)taskToSetStyleProperty: (OFString *)name value: (OFString *)value;
- (AsyncTask<OFArray<id> *> *)taskToAddClass: (OFString *)className;
- (AsyncTask<OFArray<id> *> *)taskToRemoveClass: (OFString *)className;
- (AsyncTask<OFArray<id> *> *)taskToToggleClass: (OFString *)className enabled: (bool)enabled;

@end

#pragma clang assume_nonnull end
