#import "Common.h"

#pragma clang assume_nonnull begin

@interface CodeGen : OFObject<OFApplicationDelegate> @end

@implementation CodeGen

- (void)applicationDidFinishLaunching: _
{
    OFLog(@"OK");
    [OFApplication terminateWithStatus: 0];
}

@end

#pragma clang assume_nonnull end

OF_APPLICATION_DELEGATE(CodeGen);
