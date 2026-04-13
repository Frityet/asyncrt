#pragma once

#include "Utilities/common.h"

#pragma clang assume_nonnull begin

@class AUIApplication;

typedef struct AUISize {
    float width;
    float height;
} AUISize;

@interface AUIRenderContext : OFObject

@property(class, readonly, nonatomic) AUIRenderContext *nillable currentContext;
@property(readonly, nonatomic) AUIApplication *application;
@property(readonly, nonatomic) AUISize viewportSize;
@property(readonly, nonatomic) OFDate *frameDate;
@property(readonly, nonatomic) OFTimeInterval elapsedTime;

+ (AUIRenderContext *nillable)currentContext;
- (instancetype)initWithApplication: (AUIApplication *nillable)application
                       viewportSize: (AUISize)viewportSize
                          frameDate: (OFDate *nillable)frameDate
                        elapsedTime: (OFTimeInterval)elapsedTime designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
