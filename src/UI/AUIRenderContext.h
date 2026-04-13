#pragma once

#include "Utilities/common.h"

#pragma clang assume_nonnull begin

@class AUIApplication;
@class AUIWindow;

typedef struct AUISize {
    float width;
    float height;
} AUISize;

[[subclassing_restricted, direct_members]]
@interface AUIRenderContext : OFObject

@property(class, readonly, nonatomic) AUIRenderContext *nillable currentContext;
@property(readonly, nonatomic) AUIApplication *application;
@property(readonly, nonatomic) AUIWindow *window;
@property(readonly, nonatomic) AUISize viewportSize;
@property(readonly, nonatomic) OFDate *frameDate;
@property(readonly, nonatomic) OFTimeInterval elapsedTime;

+ (AUIRenderContext *nillable)currentContext;
- (instancetype)initWithApplication: (AUIApplication *nillable)application
                             window: (AUIWindow *nillable)window
                       viewportSize: (AUISize)viewportSize
                          frameDate: (OFDate *nillable)frameDate
                        elapsedTime: (OFTimeInterval)elapsedTime [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
