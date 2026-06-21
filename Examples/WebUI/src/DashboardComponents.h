#pragma once

#import "DashboardSample.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface DashboardRootComponent : AsyncWebUIComponent

@property(nonatomic) OFString *stressLabel;
@property(nonatomic) OFString *refreshLabel;
@property(nonatomic) OFString *sampleLabel;

- (void)applySample: (DashboardSample *)sample;
- (OFTimeInterval)refreshInterval;
- (bool)isStressEnabled;

@end

#pragma clang assume_nonnull end
