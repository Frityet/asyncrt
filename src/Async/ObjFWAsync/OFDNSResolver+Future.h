#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFDNSResolver (FutureAdditions)

- (Future<OFDNSResponse *> *)futurePerformQuery: (OFDNSQuery *)query onScheduler: (AsyncScheduler *)scheduler;
- (Future<OFDNSResponse *> *)futurePerformQuery: (OFDNSQuery *)query onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Future<OFData *> *)futureResolveAddressesForHost: (OFString *)host onScheduler: (AsyncScheduler *)scheduler;
- (Future<OFData *> *)futureResolveAddressesForHost: (OFString *)host onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Future<OFData *> *)futureResolveAddressesForHost: (OFString *)host addressFamily: (OFSocketAddressFamily)addressFamily onScheduler: (AsyncScheduler *)scheduler;
- (Future<OFData *> *)futureResolveAddressesForHost: (OFString *)host addressFamily: (OFSocketAddressFamily)addressFamily onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end
