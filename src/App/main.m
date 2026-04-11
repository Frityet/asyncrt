#import "Async/AsyncRuntime.h"

#pragma clang assume_nonnull begin

@interface App : AsyncApplication @end

@implementation App

- (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification scope: (AsyncScope *)rootScope
{
    auto client = [OFHTTPClient client];
    auto req = [OFHTTPRequest requestWithIRI: [OFIRI IRIWithString: @"https://httpbin.org/get"]];
    req.method = OFHTTPRequestMethodGet;
    [rootScope withChildScope:^(AsyncScope *scope){
        OFArray<Promise<OFHTTPResponse *> *> *tasks = @[
            [client promiseToPerformRequest: req onScheduler: scope.scheduler],
            [client promiseToPerformRequest: req onScheduler: scope.scheduler],
            [client promiseToPerformRequest: req onScheduler: scope.scheduler],
            [client promiseToPerformRequest: req onScheduler: scope.scheduler],
            [client promiseToPerformRequest: req onScheduler: scope.scheduler],
        ];
        
        return AsyncUnit.unit;
    }];

    return AsyncUnit.unit;
}

@end

#pragma clang assume_nonnull end

ASYNC_APPLICATION_DELEGATE(App);
