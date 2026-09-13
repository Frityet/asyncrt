#import <AppKit/AppKit.h>
#import <Web.h>

#pragma clang assume_nonnull begin

@interface WebViewApplication : OFObject<OFApplicationDelegate, NSWindowDelegate>

@property(nonatomic) OFString *title;

@property(readonly, nonatomic) OWebComponent *rootComponent;

@end

#pragma clang assume_nonnull end
