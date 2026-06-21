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

+ (OFString *)identifier;
+ (OFString *)layout;
+ (OFString *)styling;
+ (OFArray<OFString *> *)observedProperties;

- (OFDictionary<OFString *, id> *)propertyState;
- (AsyncTask<AsyncUnit *> *)taskToRender;
- (AsyncTask<AsyncUnit *> *)taskToRenderTree;
- (void)onMountToWebView: (AsyncWebUIView *)webView;

@end

#pragma clang assume_nonnull end
