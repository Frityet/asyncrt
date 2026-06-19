#pragma once

#import <AsyncRT/Application/UI/Surface/Web/Request.h>
#import <AsyncRT/Application/UI/Window/Configuration.h>

#pragma clang assume_nonnull begin

@interface AsyncWebUIView : OFObject

@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) AsyncUIWindowConfiguration *configuration;
@property(readonly, nonatomic) OFString *nillable loadedHTML;
@property(readonly, nonatomic) OFIRI *nillable loadedIRI;
@property(readonly, nonatomic) bool isClosed;

+ (OFString *)javaScriptToDispatchEventNamed: (OFString *)name
                                  payloadJSON: (OFString *nillable)payloadJSON;
+ (OFString *)javaScriptToResolveRequestID: (OFString *)requestID
                               responseJSON: (OFString *nillable)responseJSON;

- (instancetype)initWithConfiguration: (AsyncUIWindowConfiguration *)configuration
                            scheduler: (AsyncScheduler *)scheduler [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

- (void)loadHTML: (OFString *)html;
- (void)loadIRI: (OFIRI *)IRI;
- (void)bindAction: (OFString *)name toHandler: (AsyncWebUIActionHandler)handler;
- (void)bindAction: (OFString *)name toJSONHandler: (AsyncWebUIJSONActionHandler)handler;
- (void)unbindActionNamed: (OFString *)name;
- (AsyncTask<OFString *> *)taskToHandleRequest: (AsyncWebUIRequest)request;
- (AsyncTask<AsyncUnit *> *)taskToEvaluateJavaScript: (OFString *)javaScript;
- (void)emitEvent: (OFString *)name withJSONPayload: (OFString *nillable)payloadJSON;
- (void)pollEvents;
- (void)close;

@end

#pragma clang assume_nonnull end
