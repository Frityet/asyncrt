#import <AsyncRT/Common/Common.h>

#import <AsyncRT/Common/Optional.h>

#pragma clang assume_nonnull begin

typedef void (^AsyncExecutorBlock)();

@interface AsyncExecutor : OFObject {
    @private OFMutableArray<AsyncExecutorBlock> *_workQueue;
    @private bool _drainScheduled, _isDraining;
    @private size_t _jobIdx;
    @private OFMutex *_lock;
    @private OFRunLoop *_runLoop;
    @private OFTimer *nillable _drainTimer;
    
}
@property(nonatomic) bool shouldShutdown;
@property(nonatomic) size_t maxDrainCount;

@property(readonly, nonatomic, class) AsyncExecutor *current;

- (instancetype)init [[unavailable("Use +current instead")]];

- (void)enqueue: (AsyncExecutorBlock)block;
- (void)runUntil: (bool (^)(void))condition;
- (void)runUntil: (bool (^)(void))condition timeout: (OFTimeInterval)timeout;

@end

#pragma clang assume_nonnull end
