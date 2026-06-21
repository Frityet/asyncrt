#import "DashboardSample.h"

#import <math.h>
#import <sys/resource.h>

#pragma clang assume_nonnull begin

@implementation DashboardSample @end

@implementation DashboardSampler {
    bool _hasPreviousSample;
    double _previousWallSeconds;
    double _previousCPUSeconds;
    uint64_t _sampleIndex;
}

+ (double)_secondsFromTimeValue: (struct timeval)value
{
    return (double)value.tv_sec + ((double)value.tv_usec / 1000000.0);
}

+ (double)_residentMemoryMBFromUsage: (struct rusage)usage
{
#if defined(__APPLE__)
    return (double)usage.ru_maxrss / (1024.0 * 1024.0);
#else
    return (double)usage.ru_maxrss / 1024.0;
#endif
}

- (DashboardSample *)sampleWithJavaScriptClock: (double)javaScriptClockMS
{
    struct rusage usage;
    if (getrusage(RUSAGE_SELF, &usage) != 0)
        @throw [OFInvalidArgumentException exception];

    double wallSeconds = OFDate.date.timeIntervalSince1970;
    double cpuSeconds = [DashboardSampler _secondsFromTimeValue: usage.ru_utime]
        + [DashboardSampler _secondsFromTimeValue: usage.ru_stime];
    double cpuPercent = 0.0;

    if (_hasPreviousSample) {
        double wallDelta = wallSeconds - _previousWallSeconds;
        double cpuDelta = cpuSeconds - _previousCPUSeconds;

        if (wallDelta > 0.0001)
            cpuPercent = fmax(0.0, fmin(100.0, (cpuDelta / wallDelta) * 100.0));
    }

    _hasPreviousSample = true;
    _previousWallSeconds = wallSeconds;
    _previousCPUSeconds = cpuSeconds;

    AsyncSchedulerSnapshot *snapshot = [AsyncRuntime snapshot];
    auto sample = [[DashboardSample alloc] init];
    sample.cpuPercent = cpuPercent;
    sample.memoryMB = [DashboardSampler _residentMemoryMBFromUsage: usage];
    sample.jsClockMS = javaScriptClockMS;
    sample.queuedTasks = snapshot.queuedTaskCount;
    sample.runningTasks = snapshot.runningTaskCount;
    sample.completedTasks = snapshot.completedTaskCount;
    sample.cancelledTasks = snapshot.cancelledTaskCount;
    sample.sampleIndex = ++_sampleIndex;
    return sample;
}

@end

#pragma clang assume_nonnull end
