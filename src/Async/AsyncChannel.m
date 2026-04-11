#import "Async/AsyncRuntimeInternal.h"

#pragma clang assume_nonnull begin

@class AsyncChannelSendWaitRegistration;
@class AsyncChannelReceiveWaitRegistration;

@interface AsyncChannel ()

- (void)_armSendRegistration: (AsyncChannelSendWaitRegistration *)registration;
- (void)_cancelSendRegistration: (AsyncChannelSendWaitRegistration *)registration;
- (void)_armReceiveRegistration: (AsyncChannelReceiveWaitRegistration *)registration;
- (void)_cancelReceiveRegistration: (AsyncChannelReceiveWaitRegistration *)registration;

@end

@interface AsyncChannelSendWaitRegistration : AsyncTaskWaitRegistration

@property(readonly, nonatomic) AsyncChannel *channel;
@property(readonly, nonatomic) id value;
@property(readonly, nonatomic, getter=isClosed) bool closed;

- (instancetype)initWithChannel: (AsyncChannel *)channel value: (id)value scheduler: (AsyncScheduler *)scheduler task: (Task *)task OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (Task *)task OF_UNAVAILABLE;
- (void)signalDelivered;
- (void)signalClosed;

@end

@interface AsyncChannelReceiveWaitRegistration : AsyncTaskWaitRegistration

@property(readonly, nonatomic) AsyncChannel *channel;
@property(readonly, nonatomic) id nillable receivedValue;
@property(readonly, nonatomic) bool hasReceivedValue;
@property(readonly, nonatomic, getter=isClosed) bool closed;

- (instancetype)initWithChannel: (AsyncChannel *)channel scheduler: (AsyncScheduler *)scheduler task: (Task *)task OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (Task *)task OF_UNAVAILABLE;
- (void)signalReceivedValue: (id)value;
- (void)signalClosed;

@end

@implementation AsyncChannelClosedException

@synthesize channel = _channel;
@synthesize operation = _operation;

- (instancetype)initWithChannel: (AsyncChannel *)channel operation: (OFString *)operation
{
    self = [super init];
    _channel = channel;
    _operation = [operation copy];
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"AsyncChannelClosedException: %@ cannot %@ after close", self.channel, self.operation];
}

@end

@implementation AsyncChannel {
    size_t _capacity;
    OFMutex *_lock;
    bool _closed;
    OFMutableArray<id> *_buffer;
    OFMutableArray<AsyncChannelSendWaitRegistration *> *_sendWaitRegistrations;
    OFMutableArray<AsyncChannelReceiveWaitRegistration *> *_receiveWaitRegistrations;
}

@synthesize capacity = _capacity;

- (instancetype)initWithCapacity: (size_t)capacity
{
    self = [super init];
    _capacity = capacity;
    _lock = [OFMutex mutex];
    _closed = false;
    _buffer = [OFMutableArray array];
    _sendWaitRegistrations = [OFMutableArray array];
    _receiveWaitRegistrations = [OFMutableArray array];
    return self;
}

- (bool)isClosed
{
    block_reference bool closed;

    [_lock scopedLock: ^{
        closed = _closed;
    }];

    return closed;
}

- (void)send: (id)value
{
    Task *currentTask = Task.currentTask;
    block_reference bool didSendImmediately = false;

    if (currentTask == nilptr)
        @throw [OFInvalidArgumentException exception];

    [Task checkCancellation];

    [_lock scopedLock: ^{
        if (_closed)
            @throw [[AsyncChannelClosedException alloc] initWithChannel: self operation: @"send"];

        if (_receiveWaitRegistrations.count > 0) {
            AsyncChannelReceiveWaitRegistration *receiveRegistration = [_receiveWaitRegistrations objectAtIndex: 0];
            [_receiveWaitRegistrations removeObjectAtIndex: 0];
            [receiveRegistration signalReceivedValue: value];
            didSendImmediately = true;
            return;
        }

        if (_capacity > 0 and _buffer.count < _capacity) {
            [_buffer addObject: value];
            didSendImmediately = true;
        }
    }];

    if (didSendImmediately)
        return;

    auto registration = [[AsyncChannelSendWaitRegistration alloc] initWithChannel: self value: value scheduler: currentTask.scheduler task: currentTask];
    [currentTask _yieldWithRegistration: registration waitReason: @"channel send"];
    [Task checkCancellation];

    if (registration.isClosed)
        @throw [[AsyncChannelClosedException alloc] initWithChannel: self operation: @"send"];
}

- (id)receive
{
    Task *currentTask = Task.currentTask;
    block_reference id receivedValue = nilptr;
    block_reference bool didReceiveImmediately = false;

    if (currentTask == nilptr)
        @throw [OFInvalidArgumentException exception];

    [Task checkCancellation];

    [_lock scopedLock: ^{
        if (_buffer.count > 0) {
            receivedValue = [_buffer objectAtIndex: 0];
            [_buffer removeObjectAtIndex: 0];

            if (_sendWaitRegistrations.count > 0) {
                AsyncChannelSendWaitRegistration *sendRegistration = [_sendWaitRegistrations objectAtIndex: 0];
                [_sendWaitRegistrations removeObjectAtIndex: 0];
                [_buffer addObject: sendRegistration.value];
                [sendRegistration signalDelivered];
            }

            didReceiveImmediately = true;
            return;
        }

        if (_sendWaitRegistrations.count > 0) {
            AsyncChannelSendWaitRegistration *sendRegistration = [_sendWaitRegistrations objectAtIndex: 0];
            [_sendWaitRegistrations removeObjectAtIndex: 0];
            receivedValue = sendRegistration.value;
            [sendRegistration signalDelivered];
            didReceiveImmediately = true;
            return;
        }

        if (_closed)
            @throw [[AsyncChannelClosedException alloc] initWithChannel: self operation: @"receive"];
    }];

    if (didReceiveImmediately)
        return $assert_nonnil(receivedValue);

    auto registration = [[AsyncChannelReceiveWaitRegistration alloc] initWithChannel: self scheduler: currentTask.scheduler task: currentTask];
    [currentTask _yieldWithRegistration: registration waitReason: @"channel receive"];
    [Task checkCancellation];

    if (registration.isClosed)
        @throw [[AsyncChannelClosedException alloc] initWithChannel: self operation: @"receive"];

    return $assert_nonnil(registration.receivedValue);
}

- (void)close
{
    block_reference OFArray<AsyncChannelSendWaitRegistration *> *sendRegistrations;
    block_reference OFArray<AsyncChannelReceiveWaitRegistration *> *receiveRegistrations;
    block_reference bool shouldClose = false;

    [_lock scopedLock: ^{
        if (not _closed) {
            shouldClose = true;
            _closed = true;
            sendRegistrations = [_sendWaitRegistrations copy];
            receiveRegistrations = [_receiveWaitRegistrations copy];
            [_sendWaitRegistrations removeAllObjects];
            [_receiveWaitRegistrations removeAllObjects];
        }
    }];

    if (not shouldClose)
        return;

    for (AsyncChannelSendWaitRegistration *registration in sendRegistrations)
        [registration signalClosed];
    for (AsyncChannelReceiveWaitRegistration *registration in receiveRegistrations)
        [registration signalClosed];
}

- (void)_armSendRegistration: (AsyncChannelSendWaitRegistration *)registration
{
    [_lock scopedLock: ^{
        if (_closed) {
            [registration signalClosed];
            return;
        }

        if (_receiveWaitRegistrations.count > 0) {
            AsyncChannelReceiveWaitRegistration *receiveRegistration = [_receiveWaitRegistrations objectAtIndex: 0];
            [_receiveWaitRegistrations removeObjectAtIndex: 0];
            [receiveRegistration signalReceivedValue: registration.value];
            [registration signalDelivered];
            return;
        }

        if (_capacity > 0 and _buffer.count < _capacity) {
            [_buffer addObject: registration.value];
            [registration signalDelivered];
            return;
        }

        [_sendWaitRegistrations addObject: registration];
    }];
}

- (void)_cancelSendRegistration: (AsyncChannelSendWaitRegistration *)registration
{
    [_lock scopedLock: ^{
        [_sendWaitRegistrations removeObjectIdenticalTo: registration];
    }];
}

- (void)_armReceiveRegistration: (AsyncChannelReceiveWaitRegistration *)registration
{
    [_lock scopedLock: ^{
        if (_buffer.count > 0) {
            id value = [_buffer objectAtIndex: 0];
            [_buffer removeObjectAtIndex: 0];

            if (_sendWaitRegistrations.count > 0) {
                AsyncChannelSendWaitRegistration *sendRegistration = [_sendWaitRegistrations objectAtIndex: 0];
                [_sendWaitRegistrations removeObjectAtIndex: 0];
                [_buffer addObject: sendRegistration.value];
                [sendRegistration signalDelivered];
            }

            [registration signalReceivedValue: value];
            return;
        }

        if (_sendWaitRegistrations.count > 0) {
            AsyncChannelSendWaitRegistration *sendRegistration = [_sendWaitRegistrations objectAtIndex: 0];
            [_sendWaitRegistrations removeObjectAtIndex: 0];
            [registration signalReceivedValue: sendRegistration.value];
            [sendRegistration signalDelivered];
            return;
        }

        if (_closed) {
            [registration signalClosed];
            return;
        }

        [_receiveWaitRegistrations addObject: registration];
    }];
}

- (void)_cancelReceiveRegistration: (AsyncChannelReceiveWaitRegistration *)registration
{
    [_lock scopedLock: ^{
        [_receiveWaitRegistrations removeObjectIdenticalTo: registration];
    }];
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"<AsyncChannel %p capacity=%zu closed=%s>", self, self.capacity, self.closed ? "true" : "false"];
}

@end

@implementation AsyncChannelSendWaitRegistration {
    AsyncChannel *_channel;
    id _value;
    OFMutex *_lock;
    bool _completed;
    bool _closed;
}

@synthesize channel = _channel;
@synthesize value = _value;

- (instancetype)initWithChannel: (AsyncChannel *)channel value: (id)value scheduler: (AsyncScheduler *)scheduler task: (Task *)task
{
    self = [super initWithScheduler: scheduler task: task];
    _channel = channel;
    _value = value;
    _lock = [OFMutex mutex];
    _completed = false;
    _closed = false;
    return self;
}

- (bool)_finishOnce
{
    block_reference bool shouldFinish;

    [_lock scopedLock: ^{
        shouldFinish = (not _completed);
        if (shouldFinish)
            _completed = true;
    }];

    return shouldFinish;
}

- (bool)isClosed
{
    block_reference bool closed;

    [_lock scopedLock: ^{
        closed = _closed;
    }];

    return closed;
}

- (void)arm
{
    [self.channel _armSendRegistration: self];
}

- (void)cancel
{
    if (not [self _finishOnce])
        return;

    [self.channel _cancelSendRegistration: self];
    if ([self.task _resumeFromWaitRegistration: self])
        [self.scheduler _enqueueTask: self.task];
}

- (void)signalDelivered
{
    if (not [self _finishOnce])
        return;

    if ([self.task _resumeFromWaitRegistration: self])
        [self.scheduler _enqueueTask: self.task];
}

- (void)signalClosed
{
    [_lock scopedLock: ^{
        _closed = true;
    }];

    [self signalDelivered];
}

@end

@implementation AsyncChannelReceiveWaitRegistration {
    AsyncChannel *_channel;
    OFMutex *_lock;
    bool _completed;
    bool _closed;
    bool _hasReceivedValue;
    id nillable _receivedValue;
}

@synthesize channel = _channel;
@synthesize receivedValue = _receivedValue;
@synthesize hasReceivedValue = _hasReceivedValue;

- (instancetype)initWithChannel: (AsyncChannel *)channel scheduler: (AsyncScheduler *)scheduler task: (Task *)task
{
    self = [super initWithScheduler: scheduler task: task];
    _channel = channel;
    _lock = [OFMutex mutex];
    _completed = false;
    _closed = false;
    _hasReceivedValue = false;
    return self;
}

- (bool)_finishOnce
{
    block_reference bool shouldFinish;

    [_lock scopedLock: ^{
        shouldFinish = (not _completed);
        if (shouldFinish)
            _completed = true;
    }];

    return shouldFinish;
}

- (bool)isClosed
{
    block_reference bool closed;

    [_lock scopedLock: ^{
        closed = _closed;
    }];

    return closed;
}

- (id nillable)receivedValue
{
    block_reference id value;

    [_lock scopedLock: ^{
        value = _receivedValue;
    }];

    return value;
}

- (void)arm
{
    [self.channel _armReceiveRegistration: self];
}

- (void)cancel
{
    if (not [self _finishOnce])
        return;

    [self.channel _cancelReceiveRegistration: self];
    if ([self.task _resumeFromWaitRegistration: self])
        [self.scheduler _enqueueTask: self.task];
}

- (void)signalReceivedValue: (id)value
{
    [_lock scopedLock: ^{
        _receivedValue = value;
        _hasReceivedValue = true;
    }];

    if (not [self _finishOnce])
        return;

    if ([self.task _resumeFromWaitRegistration: self])
        [self.scheduler _enqueueTask: self.task];
}

- (void)signalClosed
{
    [_lock scopedLock: ^{
        _closed = true;
    }];

    if (not [self _finishOnce])
        return;

    if ([self.task _resumeFromWaitRegistration: self])
        [self.scheduler _enqueueTask: self.task];
}

@end

#pragma clang assume_nonnull end
