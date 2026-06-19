#pragma once

#import <AsyncRT/Application/UI/Geometry.h>

#pragma clang assume_nonnull begin

@class AsyncUIApplication;
@class AsyncUIWindow;

[[subclassing_restricted, direct_members]]
@interface AsyncUIRenderContext : OFObject

@property(class, readonly, nonatomic) AsyncUIRenderContext *nillable currentContext;
@property(readonly, nonatomic) AsyncUIApplication *application;
@property(readonly, nonatomic) AsyncUIWindow *window;
@property(readonly, nonatomic) AsyncUISize viewportSize;
@property(readonly, nonatomic) OFDate *frameDate;
@property(readonly, nonatomic) OFTimeInterval elapsedTime;

+ (AsyncUIRenderContext *nillable)currentContext;
- (instancetype)initWithApplication: (AsyncUIApplication *nonnil)application
                             window: (AsyncUIWindow *nonnil)window
                       viewportSize: (AsyncUISize)viewportSize
                          frameDate: (OFDate *nonnil)frameDate
                        elapsedTime: (OFTimeInterval)elapsedTime [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
