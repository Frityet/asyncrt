#import "Async/AsyncRuntime.h"

#pragma clang assume_nonnull begin

@interface App : AsyncApplication @end

@implementation App

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification scope: (AsyncScope *)rootScope
{
    (void)notification;
    auto client = [OFHTTPClient client];
    auto req = [OFHTTPRequest requestWithIRI: [OFIRI IRIWithString: @"https://httpbin.org/get"]];
    req.method = OFHTTPRequestMethodGet;

    id result = [rootScope withChildScope:^(AsyncScope *scope) {
        return [Promise all: @[
            [client promiseToPerformRequest: req onScheduler: scope.scheduler],
            [client promiseToPerformRequest: req onScheduler: scope.scheduler],
            [client promiseToPerformRequest: req onScheduler: scope.scheduler],
            [client promiseToPerformRequest: req onScheduler: scope.scheduler],
            [client promiseToPerformRequest: req onScheduler: scope.scheduler],
        ]].await;
    }];
    OFLog(@"%@", result);

    return @(0);
}

@end

#pragma clang assume_nonnull end

OF_APPLICATION_DELEGATE(App);
