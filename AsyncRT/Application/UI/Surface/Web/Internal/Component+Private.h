#pragma once

#import <AsyncRT/Application/UI/Surface/Web/Component.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncWebUIComponentChildEntry : OFObject

@property(readonly, nonatomic) AsyncWebUIComponent *component;
@property(readonly, copy, nonatomic) OFString *slotName;

- (instancetype)initWithComponent: (AsyncWebUIComponent *)component
                         slotName: (OFString *)slotName [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncWebUIComponent ()

+ (OFString *)_asyncWebUIInvokeActionName;
+ (OFString *)_asyncWebUIUpdateEventName;
+ (OFString *)_asyncWebUIDefinitionJavaScript;

- (OFArray<AsyncWebUIComponentChildEntry *> *)_asyncWebUIChildComponentEntries;
- (void)_asyncWebUIMountToWebView: (AsyncWebUIView *)webView componentID: (OFString *)componentID;
- (OFString *)_asyncWebUIElementHTMLWithSlotName: (OFString *nillable)slotName;
- (AsyncTask<OFString *> *)_asyncWebUIHandleActionPayload: (OFDictionary<OFString *, id> *)payload;

@end

#pragma clang assume_nonnull end
