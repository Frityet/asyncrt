#pragma once

#import "AsyncRuntime.h"
#import "AUIContent.h"
#import "AUIState.h"

#pragma clang assume_nonnull begin

@class AUIApplication;

typedef void (^AUIEffectCleanupHandler)(void);
typedef AUIEffectCleanupHandler _Nullable (^AUIEffectHandler)(void);

@interface AUIComponent : OFObject<AUIContent>

@property(readonly, nonatomic) AUIApplication *nillable application;
@property(readonly, nonatomic) AUIComponent *nillable parentComponent;
@property(readonly, nonatomic) AsyncTaskGroup *nillable mountedTaskGroup;
@property(readonly, nonatomic) bool isMounted;

- (id<AUIContent>)renderContent;
- (void)componentDidMount;
- (void)componentWillUnmount;
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

#pragma clang assume_nonnull end
