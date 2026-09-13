#include "WebView.h"

#pragma clang assume_nonnull begin

@implementation WebViewApplication 

- (void)applicationDidFinishLaunching: (OFNotification *)_
{
    OFLog(@"Started webview renderer with arguments: %@", OFApplication.arguments);
    
}

@end


#pragma clang assume_nonnull end
