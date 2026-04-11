#import "Async/ObjFWAsync/OFDNSResolver+Future.h"

#pragma clang assume_nonnull begin

@interface AsyncDNSResolverQueryFutureDelegate : OFObject<OFDNSResolverQueryDelegate>

- (instancetype)initWithBridge: (AsyncObjFWFutureBridge *)bridge resolver: (OFDNSResolver *)resolver query: (OFDNSQuery *)query OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncDNSResolverHostFutureDelegate : OFObject<OFDNSResolverHostDelegate>

- (instancetype)initWithBridge: (AsyncObjFWFutureBridge *)bridge resolver: (OFDNSResolver *)resolver host: (OFString *)host OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@implementation AsyncDNSResolverQueryFutureDelegate {
    AsyncObjFWFutureBridge *_bridge;
    OFDNSResolver *_resolver;
    OFDNSQuery *_query;
}

- (instancetype)initWithBridge: (AsyncObjFWFutureBridge *)bridge resolver: (OFDNSResolver *)resolver query: (OFDNSQuery *)query
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

@implementation AsyncDNSResolverHostFutureDelegate {
    AsyncObjFWFutureBridge *_bridge;
    OFDNSResolver *_resolver;
    OFString *_host;
}

- (instancetype)initWithBridge: (AsyncObjFWFutureBridge *)bridge resolver: (OFDNSResolver *)resolver host: (OFString *)host
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

@implementation OFDNSResolver (FutureAdditions)

- (Future<OFDNSResponse *> *)futurePerformQuery: (OFDNSQuery *)query onScheduler: (AsyncScheduler *)scheduler
{
    return [self futurePerformQuery: query onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<OFDNSResponse *> *)futurePerformQuery: (OFDNSQuery *)query onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    if ((OFDNSResolver *nillable)self == nilptr or (OFDNSQuery *nillable)query == nilptr or (AsyncScheduler *nillable)scheduler == nilptr)
        @throw [OFInvalidArgumentException exception];

    FutureResolver<OFDNSResponse *> *resolver = [[FutureResolver alloc] init];
    block_reference AsyncDNSResolverQueryFutureDelegate *delegate = nilptr;
    AsyncObjFWFutureBridge *bridge = [[AsyncObjFWFutureBridge alloc] initWithObject: self operation: @"asyncPerformQuery:" scheduler: scheduler resolver: (FutureResolver<id> *)resolver startBlock: ^(AsyncObjFWFutureBridge *bridge) {
        delegate = [[AsyncDNSResolverQueryFutureDelegate alloc] initWithBridge: bridge resolver: self query: query];
        [self asyncPerformQuery: query runLoopMode: scheduler.mode delegate: delegate];
    } cancelBlock: ^(AsyncObjFWFutureBridge *unusedBridge) {
        (void)unusedBridge;
        [self close];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToFuture: resolver.future cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.future;
}

- (Future<OFData *> *)futureResolveAddressesForHost: (OFString *)host onScheduler: (AsyncScheduler *)scheduler
{
    return [self futureResolveAddressesForHost: host addressFamily: OFSocketAddressFamilyAny onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<OFData *> *)futureResolveAddressesForHost: (OFString *)host onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    return [self futureResolveAddressesForHost: host addressFamily: OFSocketAddressFamilyAny onScheduler: scheduler cancelOnTaskCancellation: cancelOnTaskCancellation];
}

- (Future<OFData *> *)futureResolveAddressesForHost: (OFString *)host addressFamily: (OFSocketAddressFamily)addressFamily onScheduler: (AsyncScheduler *)scheduler
{
    return [self futureResolveAddressesForHost: host addressFamily: addressFamily onScheduler: scheduler cancelOnTaskCancellation: false];
}

- (Future<OFData *> *)futureResolveAddressesForHost: (OFString *)host addressFamily: (OFSocketAddressFamily)addressFamily onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation
{
    if ((OFDNSResolver *nillable)self == nilptr or (OFString *nillable)host == nilptr or (AsyncScheduler *nillable)scheduler == nilptr)
        @throw [OFInvalidArgumentException exception];

    OFString *expectedHost = [host copy];
    FutureResolver<OFData *> *resolver = [[FutureResolver alloc] init];
    block_reference AsyncDNSResolverHostFutureDelegate *delegate = nilptr;
    AsyncObjFWFutureBridge *bridge = [[AsyncObjFWFutureBridge alloc] initWithObject: self operation: @"asyncResolveAddressesForHost:addressFamily:" scheduler: scheduler resolver: (FutureResolver<id> *)resolver startBlock: ^(AsyncObjFWFutureBridge *bridge) {
        delegate = [[AsyncDNSResolverHostFutureDelegate alloc] initWithBridge: bridge resolver: self host: expectedHost];
        [self asyncResolveAddressesForHost: expectedHost addressFamily: addressFamily runLoopMode: scheduler.mode delegate: delegate];
    } cancelBlock: ^(AsyncObjFWFutureBridge *unusedBridge) {
        (void)unusedBridge;
        [self close];
    }];

    [AsyncObjFWSupport attachCancellationBridgeToFuture: resolver.future cancelOnTaskCancellation: cancelOnTaskCancellation bridge: bridge];
    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.future;
}

@end

void async_link_objfw_ofdnsresolver_future_category(void) {}

#pragma clang assume_nonnull end
