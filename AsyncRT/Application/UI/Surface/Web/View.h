#pragma once

#import <AsyncRT/Application/UI/Surface/Web/Request.h>
#import <AsyncRT/Application/UI/Window/Configuration.h>

#pragma clang assume_nonnull begin

@class AsyncWebUIDocument;

@interface AsyncWebUIView : OFObject

@property(readonly, nonatomic) AsyncUIWindowConfiguration *configuration;
@property(readonly, nonatomic) AsyncWebUIDocument *document;
@property(readonly, nonatomic) OFString *nillable loadedHTML;
@property(readonly, nonatomic) OFIRI *nillable loadedIRI;
@property(readonly, nonatomic) OFIRI *nillable serverIRI;
@property(readonly, nonatomic) bool isClosed;

+ (OFString *)javaScriptToDispatchEventNamed: (OFString *)name payload: (id nillable)payload;
+ (OFString *)javaScriptToResolveRequestID: (OFString *)requestID responseJSON: (OFString *nillable)responseJSON;
+ (OFString *)javaScriptToUpdateComponentID: (OFString *)componentID stateJSON: (OFString *)stateJSON;

- (instancetype)initWithConfiguration: (AsyncUIWindowConfiguration *)configuration [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

- (void)loadHTML: (OFString *)html;
- (void)loadIRI: (OFIRI *)IRI;
- (void)bindAction: (OFString *)name toHandler: (AsyncWebUIActionHandler)handler;
- (void)unbindActionNamed: (OFString *)name;
- (AsyncTask<OFString *> *)taskToHandleRequest: (AsyncWebUIRequest)request;
- (AsyncTask<id> *)taskToEvaluateJavaScriptReturningValue: (OFString *)javaScript;
- (AsyncTask<AsyncUnit *> *)taskToEvaluateJavaScript: (OFString *)javaScript;
- (void)emitEvent: (OFString *)name withPayload: (id nillable)payload;
- (void)pollEvents;
- (void)close;

@end

#pragma clang assume_nonnull end
