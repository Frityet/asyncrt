#import <AsyncRT/Application/UI/Surface/Web/View.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncWebUIComponentException : OFException

@property(readonly, copy, nonatomic) OFString *reason;

- (instancetype)initWithReason: (OFString *)reason [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncWebUIComponent : OFObject

@property(readonly, copy, nonatomic) OFString *nillable componentID;
@property(readonly, nonatomic) AsyncWebUIView *nillable webView;

+ (OFString *)invokeActionName;
+ (OFString *)updateEventName;
+ (OFString *)identifier;
+ (OFString *)layout;
+ (OFString *)styling;
+ (OFArray<OFString *> *)observedProperties;
+ (OFString *)definitionJavaScript;
+ (AsyncTask *)taskToRegisterOnWebView: (AsyncWebUIView *)webView;

- (void)mountToWebView: (AsyncWebUIView *)webView componentID: (OFString *)componentID;
- (OFDictionary<OFString *, id> *)propertyState;
- (OFString *)propertyStateJSON;
- (OFString *)elementHTML;
- (AsyncTask<AsyncUnit *> *)taskToRender;
- (AsyncTask<OFString *> *)taskToHandleActionRequest: (AsyncWebUIRequest)request;
- (void)onMountToWebView: (AsyncWebUIView *)webView;

@end

#pragma clang assume_nonnull end
