#pragma once

#import <AsyncRT/Core/AsyncRuntime.h>

#pragma clang assume_nonnull begin

typedef void (^AsyncUIActionHandler)(void);
typedef id nillable (^AsyncUIAsyncActionHandler)(AsyncTaskGroup *taskGroup);

[[subclassing_restricted]]
@interface AsyncUIAction : OFObject

@property(copy, nonatomic) OFString *nillable name;
@property(copy, nonatomic) AsyncUIActionHandler nillable handler;
@property(copy, nonatomic) AsyncUIAsyncActionHandler nillable asyncHandler;

+ (instancetype)withHandler: (AsyncUIActionHandler nillable)handler;
+ (instancetype)withName: (OFString *nillable)name
            asyncHandler: (AsyncUIAsyncActionHandler nillable)handler;
- (void)invokeWithTaskGroup: (AsyncTaskGroup *nillable)taskGroup;

@end

#pragma clang assume_nonnull end
