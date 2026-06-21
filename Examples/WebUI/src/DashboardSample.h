#pragma once

#import <AsyncRT/Application/UI/Surface/Web/Web.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface DashboardSample : OFObject

@property(nonatomic) double cpuPercent;
@property(nonatomic) double memoryMB;
@property(nonatomic) double jsClockMS;
@property(nonatomic) uint64_t queuedTasks;
@property(nonatomic) uint64_t runningTasks;
@property(nonatomic) uint64_t completedTasks;
@property(nonatomic) uint64_t cancelledTasks;
@property(nonatomic) uint64_t sampleIndex;

@end

[[subclassing_restricted, direct_members]]
@interface DashboardSampler : OFObject

- (DashboardSample *)sampleWithJavaScriptClock: (double)javaScriptClockMS;

@end

#pragma clang assume_nonnull end
