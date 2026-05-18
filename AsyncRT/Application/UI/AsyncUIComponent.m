#import <AsyncRT/Application/UI/AsyncUIComponent.h>

#import <AsyncRT/Application/UI/AsyncUIGroup.h>
#import <AsyncRT/Application/UI/Internal/AsyncUIComponentHost.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIComponent {
    AsyncUIComponentHost *_componentHost;
}

- (instancetype)init
{
    self = [super init];
    _componentHost = [[AsyncUIComponentHost alloc] initWithOwner: self];
    return self;
}

- (AsyncUIContentKind)contentKind
{
    return AsyncUIContentKindComponent;
}

- (AsyncUIApplication *nillable)application
{
    return _componentHost.application;
}

- (AsyncUIComponent *nillable)parentComponent
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

- (id<AsyncUIContent>)renderContent
{
    return [AsyncUIGroup withChildren: [OFArray array]];
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

- (AsyncUIState *)useState: (id nillable)initialValue
{
    return [_componentHost useState: initialValue];
}

- (void)useEffect: (AsyncUIEffectHandler nillable)effectHandler
      dependencies: (OFArray<id> *nillable)dependencies
{
    [_componentHost useEffect: effectHandler dependencies: dependencies];
}

- (AsyncTask<id> *nillable)useTask: (id (^nillable)(AsyncTaskGroup *taskGroup))launchBlock
                 dependencies: (OFArray<id> *nillable)dependencies
                         name: (OFString *nillable)name
{
    return [_componentHost useTask: launchBlock dependencies: dependencies name: name];
}

- (AsyncTask<id> *nillable)launchTask: (id (^nillable)(AsyncTaskGroup *taskGroup))launchBlock
                                  name: (OFString *nillable)name
{
    return [_componentHost launchTask: launchBlock name: name];
}

- (AsyncUIComponentHost *)_componentHost
{
    return _componentHost;
}

@end

#pragma clang assume_nonnull end
