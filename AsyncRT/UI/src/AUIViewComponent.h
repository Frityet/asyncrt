#pragma once

#import "AsyncRuntime.h"
#import "AUIViewNode.h"
#import "AUIRenderContext.h"

#pragma clang assume_nonnull begin

@class AUIApplication;

typedef void (^AUIViewEffectCleanupHandler)(void);
typedef AUIViewEffectCleanupHandler _Nullable (^AUIViewEffectHandler)(void);

[[subclassing_restricted, direct_members]]
@interface AUIStateBinding<__covariant T> : OFObject

@property(readonly, nonatomic) T nillable value;

- (void)setValue: (T nillable)value;
- (void)updateValueUsingBlock: (T _Nullable (^nonnil)(T nillable currentValue))updateBlock;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AUIViewComponent : OFObject

@property(readonly, nonatomic) AUIApplication *nillable application;
@property(readonly, nonatomic) AUIViewComponent *nillable parentViewComponent;
@property(readonly, nonatomic) AsyncTaskGroup *nillable mountedTaskGroup;
@property(readonly, nonatomic) bool isMounted;

- (AUIViewNode *)renderViewNode;
- (void)viewComponentDidMount;
- (void)viewComponentWillUnmount;
- (void)setNeedsViewUpdate;
- (void)setNeedsRender;
- (AUIStateBinding *)useStateWithInitialValue: (id nillable)initialValue;
- (void)useEffectWithDependencies: (OFArray<id> *nillable)dependencies
                           effect: (AUIViewEffectHandler nillable)effectHandler;
- (Task<id> *nillable)useTaskWithDependencies: (OFArray<id> *nillable)dependencies
                                         name: (OFString *nillable)name
                                   launchTask: (id (^nillable)(AsyncTaskGroup *taskGroup))launchBlock;
- (AUIRenderContext *)useRenderContext;
- (AUIViewNode *)renderChildViewComponent: (AUIViewComponent *nonnil)childViewComponent
                                      key: (OFString *nonnil)key;

- (instancetype)init [[designated_initailiser]];

@end

#pragma clang assume_nonnull end
