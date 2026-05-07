#pragma once

#import "AUIComponent.h"

#pragma clang assume_nonnull begin

@class AUIRenderer;

[[subclassing_restricted, direct_members]]
@interface AUIComponentHost : OFObject

@property(readonly, nonatomic) AUIComponent *nillable owner;
@property(readonly, nonatomic) AUIApplication *nillable application;
@property(readonly, nonatomic) AUIComponentHost *nillable parentHost;
@property(readonly, nonatomic) AsyncTaskGroup *nillable mountedTaskGroup;
@property(readonly, nonatomic) bool isMounted;

- (instancetype)initWithOwner: (AUIComponent *nillable)owner [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (void)attachToApplication: (AUIApplication *nillable)application
                  parentHost: (AUIComponentHost *nillable)parentHost
                   taskGroup: (AsyncTaskGroup *nillable)taskGroup;
- (void)detachFromApplication;
- (void)ensureMountedInTaskGroup: (AsyncTaskGroup *nonnil)taskGroup;
- (void)unmountRecursively;
- (void)beginContentTraversal;
- (void)endContentTraversalWithRenderer: (AUIRenderer *nonnil)renderer;
- (id<AUIContent>)resolvedRenderedContent;
- (AUIComponentHost *)resolveChildHostForComponent: (AUIComponent *nonnil)component
                                                key: (OFString *nonnil)key;
- (void)setNeedsRender;
- (AUIState *)useState: (id nillable)initialValue;
- (void)useEffect: (AUIEffectHandler nillable)effectHandler
      dependencies: (OFArray<id> *nillable)dependencies;
- (Task<id> *nillable)useTask: (id (^nillable)(AsyncTaskGroup *taskGroup))launchBlock
                 dependencies: (OFArray<id> *nillable)dependencies
                         name: (OFString *nillable)name;
- (Task<id> *nillable)launchTask: (id (^nillable)(AsyncTaskGroup *taskGroup))launchBlock
                                  name: (OFString *nillable)name;

@end

@interface AUIComponent ()

- (AUIComponentHost *)_componentHost;

@end

#pragma clang assume_nonnull end
