#import "AUIComponent.h"

#import "AUIGroup.h"
#import "Internal/AUIComponentHost.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIComponent {
    AUIComponentHost *_componentHost;
}

- (instancetype)init
{
    self = [super init];
    _componentHost = [[AUIComponentHost alloc] initWithOwner: self];
    return self;
}

- (AUIContentKind)contentKind
{
    return AUIContentKindComponent;
}

- (AUIApplication *nillable)application
{
    return _componentHost.application;
}

- (AUIComponent *nillable)parentComponent
{
    return _componentHost.parentHost.owner;
}

- (AsyncTaskGroup *nillable)mountedTaskGroup
{
    return _componentHost.mountedTaskGroup;
}

- (bool)isMounted
{
    return _componentHost.isMounted;
}

- (id<AUIContent>)renderContent
{
    return [AUIGroup withChildren: @[]];
}

- (void)componentDidMount
{
}

- (void)componentWillUnmount
{
}

- (void)setNeedsRender
{
    [_componentHost setNeedsRender];
}

- (AUIState *)useState: (id nillable)initialValue
{
    return [_componentHost useState: initialValue];
}

- (void)useEffect: (AUIEffectHandler nillable)effectHandler
      dependencies: (OFArray<id> *nillable)dependencies
{
    [_componentHost useEffect: effectHandler dependencies: dependencies];
}

- (Task<id> *nillable)useTask: (id (^nillable)(AsyncTaskGroup *taskGroup))launchBlock
                 dependencies: (OFArray<id> *nillable)dependencies
                         name: (OFString *nillable)name
{
    return [_componentHost useTask: launchBlock dependencies: dependencies name: name];
}

- (Task<id> *nillable)launchTask: (id (^nillable)(AsyncTaskGroup *taskGroup))launchBlock
                                  name: (OFString *nillable)name
{
    return [_componentHost launchTask: launchBlock name: name];
}

- (AUIComponentHost *)_componentHost
{
    return _componentHost;
}

@end

#pragma clang assume_nonnull end
