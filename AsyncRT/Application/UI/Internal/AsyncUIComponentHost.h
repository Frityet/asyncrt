#pragma once

#import <AsyncRT/Application/UI/AsyncUIComponent.h>

#pragma clang assume_nonnull begin

@class AsyncUIRenderer;

[[subclassing_restricted, direct_members]]
@interface AsyncUIComponentHost : OFObject

@property(readonly, nonatomic) AsyncUIComponent *nillable owner;
@property(readonly, nonatomic) AsyncUIApplication *nillable application;
@property(readonly, nonatomic) AsyncUIComponentHost *nillable parentHost;
@property(readonly, nonatomic) AsyncTaskGroup *nillable mountedTaskGroup;
@property(readonly, nonatomic) bool isMounted;

- (instancetype)initWithOwner: (AsyncUIComponent *nillable)owner [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (void)attachToApplication: (AsyncUIApplication *nillable)application
                  parentHost: (AsyncUIComponentHost *nillable)parentHost
                   taskGroup: (AsyncTaskGroup *nillable)taskGroup;
- (void)detachFromApplication;
- (void)ensureMountedInTaskGroup: (AsyncTaskGroup *nonnil)taskGroup;
- (void)unmountRecursively;
- (void)beginContentTraversal;
- (void)endContentTraversalWithRenderer: (AsyncUIRenderer *nonnil)renderer;
- (id<AsyncUIContent>)resolvedRenderedContent;
- (AsyncUIComponentHost *)resolveChildHostForComponent: (AsyncUIComponent *nonnil)component
                                                key: (OFString *nonnil)key;
- (void)setNeedsRender;
- (AsyncUIState *)useState: (id nillable)initialValue;
- (void)useEffect: (AsyncUIEffectHandler nillable)effectHandler
      dependencies: (OFArray<id> *nillable)dependencies;
- (AsyncTask<id> *nillable)useTask: (id (^nillable)(AsyncTaskGroup *taskGroup))launchBlock
                 dependencies: (OFArray<id> *nillable)dependencies
                         name: (OFString *nillable)name;
- (AsyncTask<id> *nillable)launchTask: (id (^nillable)(AsyncTaskGroup *taskGroup))launchBlock
                                  name: (OFString *nillable)name;

@end

@interface AsyncUIComponent ()

- (AsyncUIComponentHost *)_componentHost;

@end

#pragma clang assume_nonnull end
