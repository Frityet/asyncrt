#import "AsyncRuntimeInternal.h"

#pragma clang assume_nonnull begin

@class AsyncChannelSendWaitRegistration;
@class AsyncChannelReceiveWaitRegistration;

[[subclassing_restricted]]
@interface AsyncChannelSendWaitRegistration : AsyncTaskWaitRegistration

@property(readonly, nonatomic) AsyncChannel *channel;
@property(readonly, nonatomic) id value;
@property(readonly, nonatomic) bool isClosed;

- (instancetype)initWithChannel: (AsyncChannel *)channel value: (id)value scheduler: (AsyncScheduler *)scheduler task: (Task *)task [[designated_initailiser]];
- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (Task *)task OF_UNAVAILABLE;
- (bool)_finishOnce [[direct]];
- (void)signalDelivered [[direct]];
- (void)signalClosed [[direct]];

@end

[[subclassing_restricted]]
@interface AsyncChannelReceiveWaitRegistration : AsyncTaskWaitRegistration

@property(readonly, nonatomic) AsyncChannel *channel;
@property(readonly, nonatomic) id nillable receivedValue;
@property(readonly, nonatomic) bool hasReceivedValue;
@property(readonly, nonatomic) bool isClosed;

- (instancetype)initWithChannel: (AsyncChannel *)channel scheduler: (AsyncScheduler *)scheduler task: (Task *)task [[designated_initailiser]];
- (instancetype)initWithScheduler: (AsyncScheduler *)scheduler task: (Task *)task OF_UNAVAILABLE;
- (bool)_finishOnce [[direct]];
- (void)signalReceivedValue: (id)value [[direct]];
- (void)signalClosed [[direct]];

@end

@implementation AsyncChannelClosedException


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

[[direct_members]]
@implementation AsyncChannel {
    OFMutex *_lock;
    bool _closed;
    OFMutableArray<id> *_buffer;
    OFMutableArray<AsyncChannelSendWaitRegistration *> *_sendWaitRegistrations;
    OFMutableArray<AsyncChannelReceiveWaitRegistration *> *_receiveWaitRegistrations;
}


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

    [_lock lock];
    @try {
        closed = _closed;
    } @finally {
        [_lock unlock];
    }

    return closed;
}

- (void)send: (id)value
{
    Task *currentTask = Task.currentTask;
    block_reference bool didSendImmediately = false;

    if (currentTask == nilptr)
        @throw [OFInvalidArgumentException exception];

    [Task checkCancellation];

    [_lock lock];
    @try {
        if (_closed)
            @throw [[AsyncChannelClosedException alloc] initWithChannel: self operation: @"send"];

        if (_receiveWaitRegistrations.count > 0) {
            AsyncChannelReceiveWaitRegistration *receiveRegistration = _receiveWaitRegistrations[0];
            [_receiveWaitRegistrations removeObjectAtIndex: 0];
            [receiveRegistration signalReceivedValue: value];
            didSendImmediately = true;
            return;
        }

        if (_capacity > 0 and _buffer.count < _capacity) {
            [_buffer addObject: value];
            didSendImmediately = true;
        }
    } @finally {
        [_lock unlock];
    }

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

    [_lock lock];
    @try {
        if (_buffer.count > 0) {
            receivedValue = _buffer[0];
            [_buffer removeObjectAtIndex: 0];

            if (_sendWaitRegistrations.count > 0) {
                AsyncChannelSendWaitRegistration *sendRegistration = _sendWaitRegistrations[0];
                [_sendWaitRegistrations removeObjectAtIndex: 0];
                [_buffer addObject: sendRegistration.value];
                [sendRegistration signalDelivered];
            }

            didReceiveImmediately = true;
        } else if (_sendWaitRegistrations.count > 0) {
            AsyncChannelSendWaitRegistration *sendRegistration = _sendWaitRegistrations[0];
            [_sendWaitRegistrations removeObjectAtIndex: 0];
            receivedValue = sendRegistration.value;
            [sendRegistration signalDelivered];
            didReceiveImmediately = true;
        }

        if (_closed and not didReceiveImmediately)
            @throw [[AsyncChannelClosedException alloc] initWithChannel: self operation: @"receive"];
    } @finally {
        [_lock unlock];
    }

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

    [_lock lock];
    @try {
        if (not _closed) {
            shouldClose = true;
            _closed = true;
            sendRegistrations = [_sendWaitRegistrations copy];
            receiveRegistrations = [_receiveWaitRegistrations copy];
            [_sendWaitRegistrations removeAllObjects];
            [_receiveWaitRegistrations removeAllObjects];
        }
    } @finally {
        [_lock unlock];
    }

    if (not shouldClose)
        return;

    for (AsyncChannelSendWaitRegistration *registration in sendRegistrations)
        [registration signalClosed];
    for (AsyncChannelReceiveWaitRegistration *registration in receiveRegistrations)
        [registration signalClosed];
}

- (void)_armSendRegistration: (AsyncChannelSendWaitRegistration *)registration
{
    [_lock lock];
    @try {
        if (_closed) {
            [registration signalClosed];
            return;
        }

        if (_receiveWaitRegistrations.count > 0) {
            AsyncChannelReceiveWaitRegistration *receiveRegistration = _receiveWaitRegistrations[0];
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
    } @finally {
        [_lock unlock];
    }
}

- (void)_cancelSendRegistration: (AsyncChannelSendWaitRegistration *)registration
{
    [_lock lock];
    @try {
        [_sendWaitRegistrations removeObjectIdenticalTo: registration];
    } @finally {
        [_lock unlock];
    }
}

- (void)_armReceiveRegistration: (AsyncChannelReceiveWaitRegistration *)registration
{
    [_lock lock];
    @try {
        if (_buffer.count > 0) {
            id value = _buffer[0];
            [_buffer removeObjectAtIndex: 0];

            if (_sendWaitRegistrations.count > 0) {
                AsyncChannelSendWaitRegistration *sendRegistration = _sendWaitRegistrations[0];
                [_sendWaitRegistrations removeObjectAtIndex: 0];
                [_buffer addObject: sendRegistration.value];
                [sendRegistration signalDelivered];
            }

            [registration signalReceivedValue: value];
            return;
        }

        if (_sendWaitRegistrations.count > 0) {
            AsyncChannelSendWaitRegistration *sendRegistration = _sendWaitRegistrations[0];
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
    } @finally {
        [_lock unlock];
    }
}

- (void)_cancelReceiveRegistration: (AsyncChannelReceiveWaitRegistration *)registration
{
    [_lock lock];
    @try {
        [_receiveWaitRegistrations removeObjectIdenticalTo: registration];
    } @finally {
        [_lock unlock];
    }
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"<AsyncChannel %p capacity=%zu closed=%s>", self, self.capacity, self.isClosed ? "true" : "false"];
}

@end

@implementation AsyncChannelSendWaitRegistration {
    OFMutex *_lock;
    bool _completed;
    bool _closed;
}


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

    [_lock lock];
    @try {
        shouldFinish = (not _completed);
        if (shouldFinish)
            _completed = true;
    } @finally {
        [_lock unlock];
    }

    return shouldFinish;
}

- (bool)isClosed
{
    block_reference bool closed;

    [_lock lock];
    @try {
        closed = _closed;
    } @finally {
        [_lock unlock];
    }

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
    [_lock lock];
    @try {
        _closed = true;
    } @finally {
        [_lock unlock];
    }

    [self signalDelivered];
}

@end

@implementation AsyncChannelReceiveWaitRegistration {
    OFMutex *_lock;
    bool _completed;
    bool _closed;
    bool _hasReceivedValue;
    id nillable _receivedValue;
}


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

    [_lock lock];
    @try {
        shouldFinish = (not _completed);
        if (shouldFinish)
            _completed = true;
    } @finally {
        [_lock unlock];
    }

    return shouldFinish;
}

- (bool)isClosed
{
    block_reference bool closed;

    [_lock lock];
    @try {
        closed = _closed;
    } @finally {
        [_lock unlock];
    }

    return closed;
}

- (id nillable)receivedValue
{
    block_reference id value;

    [_lock lock];
    @try {
        value = _receivedValue;
    } @finally {
        [_lock unlock];
    }

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
    [_lock lock];
    @try {
        _receivedValue = value;
        _hasReceivedValue = true;
    } @finally {
        [_lock unlock];
    }

    if (not [self _finishOnce])
        return;

    if ([self.task _resumeFromWaitRegistration: self])
        [self.scheduler _enqueueTask: self.task];
}

- (void)signalClosed
{
    [_lock lock];
    @try {
        _closed = true;
    } @finally {
        [_lock unlock];
    }

    if (not [self _finishOnce])
        return;

    if ([self.task _resumeFromWaitRegistration: self])
        [self.scheduler _enqueueTask: self.task];
}

@end

#pragma clang assume_nonnull end
