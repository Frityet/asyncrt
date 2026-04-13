#import "Utilities/DependencyTracking.h"

#pragma clang assume_nonnull begin

@namespace(DependencyTrackingSupport)

+ (OFString *)observerStackKey;
+ (OFMutableArray<id<DependencyTrackingObserver>> *)observerStack;

@end

@namespace_implementation(DependencyTrackingSupport)

+ (OFString *)observerStackKey
{
    return @"DependencyTracking.observerStack";
}

+ (OFMutableArray<id<DependencyTrackingObserver>> *)observerStack
{
    OFMutableDictionary<OFString *, OFMutableArray<id<DependencyTrackingObserver>> *> *threadDictionary = OFThread.threadDictionary;
    OFMutableArray<id<DependencyTrackingObserver>> *stack;

    if (threadDictionary == nilptr)
        @throw [OFInvalidArgumentException exception];

    stack = threadDictionary[self.observerStackKey];
    if (stack == nilptr) {
        stack = [OFMutableArray array];
        threadDictionary[self.observerStackKey] = stack;
    }

    return stack;
}

@end

@implementation DependencyTracking

+ (void)pushObserver: (id<DependencyTrackingObserver>)observer
{
    if (((id nillable)observer) == nilptr)
        @throw [OFInvalidArgumentException exception];

    [[DependencyTrackingSupport observerStack] addObject: observer];
}

+ (void)popObserver
{
    auto stack = [DependencyTrackingSupport observerStack];

    if (stack.count == 0)
        @throw [OFOutOfRangeException exception];

    [stack removeObjectAtIndex: stack.count - 1];
}

+ (id<DependencyTrackingObserver> nillable)currentObserver
{
    OFMutableDictionary<OFString *, OFMutableArray<id<DependencyTrackingObserver>> *> *threadDictionary = OFThread.threadDictionary;
    OFMutableArray<id<DependencyTrackingObserver>> *nillable stack = nilptr;

    if (threadDictionary == nilptr)
        return nilptr;

    stack = threadDictionary[[DependencyTrackingSupport observerStackKey]];
    if (stack == nilptr or stack.count == 0)
        return nilptr;

    return [stack objectAtIndex: stack.count - 1];
}

+ (void)registerDependency: (id)dependency registration: (DependencyTrackingRegistrationBlock)registration
{
    id<DependencyTrackingObserver> currentObserver = self.currentObserver;

    if (currentObserver == nilptr)
        return;
    if (((id nillable)dependency) == nilptr or registration == nilptr)
        @throw [OFInvalidArgumentException exception];

    [currentObserver trackDependency: dependency registration: registration];
}

@end

#pragma clang assume_nonnull end
