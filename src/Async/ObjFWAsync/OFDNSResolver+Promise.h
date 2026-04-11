#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"

#pragma clang assume_nonnull begin

@interface OFDNSResolver (PromiseAdditions)

- (Promise<OFDNSResponse *> *)promiseToPerformQuery: (OFDNSQuery *)query onScheduler: (AsyncScheduler *)scheduler;
- (Promise<OFDNSResponse *> *)promiseToPerformQuery: (OFDNSQuery *)query onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Promise<OFData *> *)promiseToResolveAddressesForHost: (OFString *)host onScheduler: (AsyncScheduler *)scheduler;
- (Promise<OFData *> *)promiseToResolveAddressesForHost: (OFString *)host onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;
- (Promise<OFData *> *)promiseToResolveAddressesForHost: (OFString *)host addressFamily: (OFSocketAddressFamily)addressFamily onScheduler: (AsyncScheduler *)scheduler;
- (Promise<OFData *> *)promiseToResolveAddressesForHost: (OFString *)host addressFamily: (OFSocketAddressFamily)addressFamily onScheduler: (AsyncScheduler *)scheduler cancelOnTaskCancellation: (bool)cancelOnTaskCancellation;

@end

#pragma clang assume_nonnull end
