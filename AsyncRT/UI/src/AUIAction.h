#pragma once

#import "AsyncRuntime.h"

#pragma clang assume_nonnull begin

typedef void (^AUIActionHandler)(void);
typedef id nillable (^AUIAsyncActionHandler)(AsyncTaskGroup *taskGroup);

[[subclassing_restricted]]
@interface AUIAction : OFObject

@property(copy, nonatomic) OFString *nillable name;
@property(copy, nonatomic) AUIActionHandler nillable handler;
@property(copy, nonatomic) AUIAsyncActionHandler nillable asyncHandler;

+ (instancetype)withHandler: (AUIActionHandler nillable)handler;
+ (instancetype)withName: (OFString *nillable)name
            asyncHandler: (AUIAsyncActionHandler nillable)handler;
- (void)invokeWithTaskGroup: (AsyncTaskGroup *nillable)taskGroup;

@end

#pragma clang assume_nonnull end
