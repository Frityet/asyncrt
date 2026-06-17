#import <AsyncRT/Core.h>

#import "AsyncWebUIRequest.h"

@interface AsyncWebUIWindowConfiguration : OFObject <OFCopying>

@property(readwrite, copy, nonatomic) OFString *title;
@property(readwrite, nonatomic) unsigned int width;
@property(readwrite, nonatomic) unsigned int height;
@property(readwrite, nonatomic) bool resizable;

+ (instancetype)configuration;

@end

@interface AsyncWebUIView : OFObject

@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) AsyncWebUIWindowConfiguration *configuration;
@property(readonly, nonatomic) OFString *html;

- (instancetype)initWithConfiguration: (AsyncWebUIWindowConfiguration *)configuration
                            scheduler: (AsyncScheduler *)scheduler
    [[designated_initailiser]];

- (void)loadHTML: (OFString *)html;
- (void)loadIRI: (OFIRI *)IRI;

- (void)bindAction: (OFString *)name toHandler: (AsyncWebUIActionHandler)handler;

- (AsyncTask<AsyncUnit *> *)taskToEvaluateJavaScript: (OFString *)javaScript;
- (void)emitEvent: (OFString *)name withJSONPayload: (OFString *)payloadJSON;
- (void)close;

@end
