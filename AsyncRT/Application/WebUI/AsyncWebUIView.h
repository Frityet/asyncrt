#import <AsyncRT/Core.h>

#import "AsyncWebUIRequest.h"

@interface AsyncWebUIWindowConfiguration : OFObject

@end

@interface AsyncWebUIView : OFObject

@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) AsyncWebUIWindowConfiguration *configuration;
@property(readonly, nonatomic) OFString *html;

- (instancetype)initWithConfiguration: (AsyncWebUIWindowConfiguration *)configuration
                            scheduler: (AsyncScheduler *)scheduler
    [[designated_initailiser]];

// - (void)navigateToIRI: (OFIRI *)IRI;

- (void)bindAction: (OFString *)name toHandler: (AsyncWebUIActionHandler)handler;

- (AsyncTask<AsyncUnit *> *)taskToEvaluateJavaScript: (OFString *)javaScript;
- (void)emitEvent: (OFString *)name withJSONPayload: (OFString *)payloadJSON;
- (void)close;

@end
