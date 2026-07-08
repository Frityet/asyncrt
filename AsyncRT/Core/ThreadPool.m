#include "ThreadPool.h"
#include <AsyncRT/Common/Common.h>

@interface Worker : OFThread

@property(nonatomic, readonly) OFCondition *hasTaskCondition;
@property(copy) void (^nillable task)(void);

@end

@implementation Worker

- (instancetype)init
{
    self = [super init];
    _hasTaskCondition = [[OFCondition alloc] init];
    return self;
}

- (id)main
{
    while (true) {
        [self.hasTaskCondition wait];
        if (self.task) {
            self.task();
            self.task = nilptr;
        }
    }
}

@end

@implementation ThreadPool {
    OFMutableArray<OFThread *> *_threads;
}

- (instancetype)initWithThreadCount: (size_t)threadCount
{   
    self = [super init];
    _threadCount = threadCount;
    _tasks = [OFMutableArray<void (^)(void)> array];
    _threads = [OFMutableArray<OFThread *> array];
    for (size_t i = 0; i < threadCount; i++) {
        auto thread = [[Worker alloc] init];
        [_threads addObject: thread];
        [thread start];
    } 
    return self;
}

- (void)runOnRunLoop: (OFRunLoop *)runLoop
{
    [OFTimer scheduledTimerWithTimeInterval: 0 repeats: true block: ^(OFTimer *) {
        if (self.tasks.count == 0)
            return;

        auto next = (void(^nonnil)(void))self.tasks.firstObject;
        [self.tasks removeObjectAtIndex: 0];
        //get first available thread (available thread is one that has no task assigned to it)
        Worker *nillable worker = [self->_threads foldUsingBlock: ^(Worker *nillable left, Worker *right){
            if (left == nilptr)
                return right;
            if (left.task == nilptr)
                return left;
            if (right.task == nilptr)
                return right;
            return left;
        }];

        if (worker == nilptr) {
            //no available thread, put the task back to the queue
            [self.tasks insertObject: next atIndex: 0];
            return;
        }

        worker.task = next;
        [worker.hasTaskCondition signal];
    }];
}


@end
