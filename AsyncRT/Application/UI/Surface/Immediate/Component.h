#pragma once

#import <AsyncRT/Core/AsyncRuntime.h>
#import <AsyncRT/Application/UI/Surface/Immediate/Content.h>
#import <AsyncRT/Application/UI/Surface/Immediate/State.h>

#pragma clang assume_nonnull begin

@class AsyncUIApplication;

typedef void (^AsyncUIEffectCleanupHandler)(void);
typedef AsyncUIEffectCleanupHandler _Nullable (^AsyncUIEffectHandler)(void);

@interface AsyncUIComponent : OFObject<AsyncUIContent>

@property(readonly, nonatomic) AsyncUIApplication *nillable application;
@property(readonly, nonatomic) AsyncUIComponent *nillable parentComponent;
@property(readonly, nonatomic) AsyncTaskGroup *nillable mountedTaskGroup;
@property(readonly, nonatomic) bool isMounted;

- (id<AsyncUIContent>)renderContent;
- (void)componentDidMount;
- (void)componentWillUnmount;
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

#pragma clang assume_nonnull end
