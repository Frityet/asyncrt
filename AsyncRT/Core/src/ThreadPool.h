#import <Common.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface ThreadPool : OFObject

@property(readonly) size_t threadCount;

- (instancetype)initWithThreadCount: (size_t)threadCount;

/** Enqueues a task and wakes exactly one worker. */
- (void)enqueueTask: (void (^)(void))task;

/**
 * Stops the pool after allowing queued and currently executing tasks to finish,
 * then joins every worker before returning.
 *
 * This method must be called outside the pool's own worker tasks.
 */
- (void)invalidate;

/** Compatibility no-op: workers now consume the queue directly. */
- (void)runOnRunLoop: (OFRunLoop *)runLoop;

@end

#pragma clang assume_nonnull end
