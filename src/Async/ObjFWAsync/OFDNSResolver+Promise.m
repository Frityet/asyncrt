#import "Async/ObjFWAsync/OFDNSResolver+Promise.h"

#pragma clang assume_nonnull begin

@interface AsyncDNSResolverQueryPromiseDelegate : OFObject<OFDNSResolverQueryDelegate>

- (instancetype)initWithBridge: (AsyncObjFWPromiseBridge *)bridge resolver: (OFDNSResolver *)resolver query: (OFDNSQuery *)query OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncDNSResolverHostPromiseDelegate : OFObject<OFDNSResolverHostDelegate>

- (instancetype)initWithBridge: (AsyncObjFWPromiseBridge *)bridge resolver: (OFDNSResolver *)resolver host: (OFString *)host OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@implementation AsyncDNSResolverQueryPromiseDelegate {
    AsyncObjFWPromiseBridge *_bridge;
    OFDNSResolver *_resolver;
    OFDNSQuery *_query;
}

- (instancetype)initWithBridge: (AsyncObjFWPromiseBridge *)bridge resolver: (OFDNSResolver *)resolver query: (OFDNSQuery *)query
{
    self = [super init];
    _bridge = bridge;
    _resolver = resolver;
    _query = [query copy];
    return self;
}

- (void)resolver: (OFDNSResolver *)resolver didPerformQuery: (OFDNSQuery *)query response: (OFDNSResponse *nillable)response exception: (id nillable)exception
{
    if (resolver != _resolver or not [query isEqual: _query]) {
        [_bridge rejectInvalidCompletionWithReason: @"ObjFW resolved a DNS query with mismatched metadata"];
        return;
    }

    if (exception != nilptr) {
        [_bridge reject: (OFException *)exception];
    } else if ((OFDNSResponse *nillable)response == nilptr) {
        [_bridge rejectInvalidCompletionWithReason: @"ObjFW completed a DNS query without a response or exception"];
    } else {
        [_bridge resolve: $assert_nonnil(response)];
    }
}

@end

@implementation AsyncDNSResolverHostPromiseDelegate {
    AsyncObjFWPromiseBridge *_bridge;
    OFDNSResolver *_resolver;
    OFString *_host;
}

- (instancetype)initWithBridge: (AsyncObjFWPromiseBridge *)bridge resolver: (OFDNSResolver *)resolver host: (OFString *)host
{
    self = [super init];
    _bridge = bridge;
    _resolver = resolver;
    _host = [host copy];
    return self;
}

- (void)resolver: (OFDNSResolver *)resolver didResolveHost: (OFString *)host addresses: (OFData *nillable)addresses exception: (id nillable)exception
{
    if (resolver != _resolver or not [host isEqual: _host]) {
        [_bridge rejectInvalidCompletionWithReason: @"ObjFW resolved host addresses with mismatched metadata"];
        return;
    }

    if (exception != nilptr) {
        [_bridge reject: (OFException *)exception];
    } else if ((OFData *nillable)addresses == nilptr) {
        [_bridge rejectInvalidCompletionWithReason: @"ObjFW completed a host resolution without addresses or exception"];
    } else {
        [_bridge resolve: $assert_nonnil(addresses)];
    }
}

@end

@implementation OFDNSResolver (PromiseAdditions)

- (Promise<OFDNSResponse *> *)promiseToPerformQuery: (OFDNSQuery *)query onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToPerformQuery: query onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<OFDNSResponse *> *)promiseToPerformQuery: (OFDNSQuery *)query onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    auto resolver = [[PromiseResolver<OFDNSResponse *> alloc] init];
    block_reference AsyncDNSResolverQueryPromiseDelegate *delegate = nilptr;
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: self operation: @"asyncPerformQuery:" scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        delegate = [[AsyncDNSResolverQueryPromiseDelegate alloc] initWithBridge: bridge resolver: self query: query];
        [self asyncPerformQuery: query runLoopMode: scheduler.mode delegate: delegate];
    } cancelBlock: ^(AsyncObjFWPromiseBridge *) {
        [self close];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToPromise: resolver.future cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.future;
}

- (Promise<OFData *> *)promiseToResolveAddressesForHost: (OFString *)host onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToResolveAddressesForHost: host addressFamily: OFSocketAddressFamilyAny onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<OFData *> *)promiseToResolveAddressesForHost: (OFString *)host onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return [self promiseToResolveAddressesForHost: host addressFamily: OFSocketAddressFamilyAny onScheduler: scheduler cancelOnTaskCancellation: cancelOnTaskCancellation];
}

- (Promise<OFData *> *)promiseToResolveAddressesForHost: (OFString *)host addressFamily: (OFSocketAddressFamily)addressFamily onScheduler: (AsyncScheduler *)scheduler
{
    return [self promiseToResolveAddressesForHost: host addressFamily: addressFamily onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Promise<OFData *> *)promiseToResolveAddressesForHost: (OFString *)host addressFamily: (OFSocketAddressFamily)addressFamily onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    OFString *expectedHost = [host copy];
    auto resolver = [[PromiseResolver<OFData *> alloc] init];
    block_reference AsyncDNSResolverHostPromiseDelegate *delegate = nilptr;
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: self operation: @"asyncResolveAddressesForHost:addressFamily:" scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        delegate = [[AsyncDNSResolverHostPromiseDelegate alloc] initWithBridge: bridge resolver: self host: expectedHost];
        [self asyncResolveAddressesForHost: expectedHost addressFamily: addressFamily runLoopMode: scheduler.mode delegate: delegate];
    } cancelBlock: ^(AsyncObjFWPromiseBridge *) {
        [self close];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToPromise: resolver.future cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.future;
}

@end

void async_link_objfw_ofdnsresolver_promise_category(void) {}

#pragma clang assume_nonnull end
