#pragma once

#include "Utilities/common.h"

#pragma clang assume_nonnull begin

typedef void (^DependencyTrackingCleanupBlock)(void);
typedef DependencyTrackingCleanupBlock nillable (^DependencyTrackingRegistrationBlock)(void (^notify)(void));

@protocol DependencyTrackingObserver

- (void)trackDependency: (id)dependency registration: (DependencyTrackingRegistrationBlock)registration;

@end

@interface DependencyTracking : OFObject

+ (void)pushObserver: (id<DependencyTrackingObserver>)observer;
+ (void)popObserver;
+ (id<DependencyTrackingObserver> nillable)currentObserver;
+ (void)registerDependency: (id)dependency registration: (DependencyTrackingRegistrationBlock)registration;

@end

#pragma clang assume_nonnull end
