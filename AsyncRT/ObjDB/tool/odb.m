#import "AsyncApplication.h"
#import "ObjDBModule.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface ODBApplication : AsyncApplication
@end

@implementation ODBApplication

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification
                               taskGroup: (AsyncTaskGroup *)taskGroup
{
    (void)notification;
    (void)taskGroup;

    [OFStdOut writeLine: ObjDBModule.toolName];
    return @0;
}

@end

#pragma clang assume_nonnull end

OF_APPLICATION_DELEGATE(ODBApplication)
