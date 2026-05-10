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
    size_t _bufferHeadIndex;
    OFMutableArray<AsyncChannelSendWaitRegistration *> *_sendWaitRegistrations;
    size_t _sendWaitRegistrationHeadIndex;
    OFMutableArray<AsyncChannelReceiveWaitRegistration *> *_receiveWaitRegistrations;
    size_t _receiveWaitRegistrationHeadIndex;
}


- (instancetype)initWithCapacity: (size_t)capacity
{
    self = [super init];
    _capacity = capacity;
    _lock = [OFMutex mutex];
    _closed = false;
    _buffer = [OFMutableArray array];
    _bufferHeadIndex = 0;
    _sendWaitRegistrations = [OFMutableArray array];
    _sendWaitRegistrationHeadIndex = 0;
    _receiveWaitRegistrations = [OFMutableArray array];
    _receiveWaitRegistrationHeadIndex = 0;
    return self;
}

- (size_t)_liveBufferCount
{
    return _buffer.count - _bufferHeadIndex;
}

- (size_t)_liveSendWaitRegistrationCount
{
    return _sendWaitRegistrations.count - _sendWaitRegistrationHeadIndex;
}

- (size_t)_liveReceiveWaitRegistrationCount
{
    return _receiveWaitRegistrations.count - _receiveWaitRegistrationHeadIndex;
}

- (void)_compactBufferIfNeeded
{
    if (_bufferHeadIndex == 0)
        return;
    if (_bufferHeadIndex < 128 and _bufferHeadIndex * 2 < _buffer.count)
        return;

    auto compactedBuffer = [OFMutableArray<id> arrayWithCapacity: self._liveBufferCount];
    for (size_t index = _bufferHeadIndex; index < _buffer.count; index++)
        [compactedBuffer addObject: _buffer[index]];

    _buffer = compactedBuffer;
    _bufferHeadIndex = 0;
}

- (void)_compactSendWaitRegistrationsIfNeeded
{
    if (_sendWaitRegistrationHeadIndex == 0)
        return;
    if (_sendWaitRegistrationHeadIndex < 128 and _sendWaitRegistrationHeadIndex * 2 < _sendWaitRegistrations.count)
        return;

    auto compactedRegistrations = [OFMutableArray<AsyncChannelSendWaitRegistration *> arrayWithCapacity: self._liveSendWaitRegistrationCount];
    for (size_t index = _sendWaitRegistrationHeadIndex; index < _sendWaitRegistrations.count; index++)
        [compactedRegistrations addObject: _sendWaitRegistrations[index]];

    _sendWaitRegistrations = compactedRegistrations;
    _sendWaitRegistrationHeadIndex = 0;
}

- (void)_compactReceiveWaitRegistrationsIfNeeded
{
    if (_receiveWaitRegistrationHeadIndex == 0)
        return;
    if (_receiveWaitRegistrationHeadIndex < 128 and _receiveWaitRegistrationHeadIndex * 2 < _receiveWaitRegistrations.count)
        return;

    auto compactedRegistrations = [OFMutableArray<AsyncChannelReceiveWaitRegistration *> arrayWithCapacity: self._liveReceiveWaitRegistrationCount];
    for (size_t index = _receiveWaitRegistrationHeadIndex; index < _receiveWaitRegistrations.count; index++)
        [compactedRegistrations addObject: _receiveWaitRegistrations[index]];

    _receiveWaitRegistrations = compactedRegistrations;
    _receiveWaitRegistrationHeadIndex = 0;
}

- (id)_popBufferedValue
{
    id value = _buffer[_bufferHeadIndex++];
    [self _compactBufferIfNeeded];
    return value;
}

- (AsyncChannelSendWaitRegistration *)_popSendWaitRegistration
{
    AsyncChannelSendWaitRegistration *registration = _sendWaitRegistrations[_sendWaitRegistrationHeadIndex++];
    [self _compactSendWaitRegistrationsIfNeeded];
    return registration;
}

- (AsyncChannelReceiveWaitRegistration *)_popReceiveWaitRegistration
{
    AsyncChannelReceiveWaitRegistration *registration = _receiveWaitRegistrations[_receiveWaitRegistrationHeadIndex++];
    [self _compactReceiveWaitRegistrationsIfNeeded];
    return registration;
}

- (bool)isClosed
{
    bool closed;

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
    bool didSendImmediately = false;
    AsyncChannelReceiveWaitRegistration *nillable receiveRegistration = nilptr;

    if (currentTask == nilptr)
        @throw [OFInvalidArgumentException exception];

    [Task checkCancellation];

    [_lock lock];
    @try {
        if (_closed)
            @throw [[AsyncChannelClosedException alloc] initWithChannel: self operation: @"send"];

        if (self._liveReceiveWaitRegistrationCount > 0) {
            receiveRegistration = [self _popReceiveWaitRegistration];
            didSendImmediately = true;
        } else if (_capacity > 0 and self._liveBufferCount < _capacity) {
            [_buffer addObject: value];
            didSendImmediately = true;
        }
    } @finally {
        [_lock unlock];
    }

    if (receiveRegistration != nilptr)
        [$assert_nonnil(receiveRegistration) signalReceivedValue: value];

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
    id receivedValue = nilptr;
    bool didReceiveImmediately = false;
    AsyncChannelSendWaitRegistration *nillable deliveredSendRegistration = nilptr;

    if (currentTask == nilptr)
        @throw [OFInvalidArgumentException exception];

    [Task checkCancellation];

    [_lock lock];
    @try {
        if (self._liveBufferCount > 0) {
            receivedValue = [self _popBufferedValue];

            if (self._liveSendWaitRegistrationCount > 0) {
                deliveredSendRegistration = [self _popSendWaitRegistration];
                [_buffer addObject: $assert_nonnil(deliveredSendRegistration).value];
            }

            didReceiveImmediately = true;
        } else if (self._liveSendWaitRegistrationCount > 0) {
            deliveredSendRegistration = [self _popSendWaitRegistration];
            receivedValue = $assert_nonnil(deliveredSendRegistration).value;
            didReceiveImmediately = true;
        }

        if (_closed and not didReceiveImmediately)
            @throw [[AsyncChannelClosedException alloc] initWithChannel: self operation: @"receive"];
    } @finally {
        [_lock unlock];
    }

    if (deliveredSendRegistration != nilptr)
        [$assert_nonnil(deliveredSendRegistration) signalDelivered];

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
            auto activeSendRegistrations = [OFMutableArray<AsyncChannelSendWaitRegistration *> arrayWithCapacity: self._liveSendWaitRegistrationCount];
            for (size_t index = _sendWaitRegistrationHeadIndex; index < _sendWaitRegistrations.count; index++)
                [activeSendRegistrations addObject: _sendWaitRegistrations[index]];
            sendRegistrations = [activeSendRegistrations copy];

            auto activeReceiveRegistrations = [OFMutableArray<AsyncChannelReceiveWaitRegistration *> arrayWithCapacity: self._liveReceiveWaitRegistrationCount];
            for (size_t index = _receiveWaitRegistrationHeadIndex; index < _receiveWaitRegistrations.count; index++)
                [activeReceiveRegistrations addObject: _receiveWaitRegistrations[index]];
            receiveRegistrations = [activeReceiveRegistrations copy];

            [_sendWaitRegistrations removeAllObjects];
            [_receiveWaitRegistrations removeAllObjects];
            _sendWaitRegistrationHeadIndex = 0;
            _receiveWaitRegistrationHeadIndex = 0;
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
    AsyncChannelReceiveWaitRegistration *nillable receiveRegistration = nilptr;
    bool shouldSignalClosed = false;
    bool shouldSignalDelivered = false;

    [_lock lock];
    @try {
        if (_closed) {
            shouldSignalClosed = true;
        } else if (self._liveReceiveWaitRegistrationCount > 0) {
            receiveRegistration = [self _popReceiveWaitRegistration];
            shouldSignalDelivered = true;
        } else if (_capacity > 0 and self._liveBufferCount < _capacity) {
            [_buffer addObject: registration.value];
            shouldSignalDelivered = true;
        } else {
            [_sendWaitRegistrations addObject: registration];
        }
    } @finally {
        [_lock unlock];
    }

    if (receiveRegistration != nilptr)
        [$assert_nonnil(receiveRegistration) signalReceivedValue: registration.value];
    if (shouldSignalDelivered)
        [registration signalDelivered];
    if (shouldSignalClosed)
        [registration signalClosed];
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
    id nillable receivedValue = nilptr;
    AsyncChannelSendWaitRegistration *nillable deliveredSendRegistration = nilptr;
    bool shouldSignalReceived = false;
    bool shouldSignalClosed = false;

    [_lock lock];
    @try {
        if (self._liveBufferCount > 0) {
            receivedValue = [self _popBufferedValue];
            shouldSignalReceived = true;

            if (self._liveSendWaitRegistrationCount > 0) {
                deliveredSendRegistration = [self _popSendWaitRegistration];
                [_buffer addObject: $assert_nonnil(deliveredSendRegistration).value];
            }
        } else if (self._liveSendWaitRegistrationCount > 0) {
            deliveredSendRegistration = [self _popSendWaitRegistration];
            receivedValue = $assert_nonnil(deliveredSendRegistration).value;
            shouldSignalReceived = true;
        } else if (_closed) {
            shouldSignalClosed = true;
        } else {
            [_receiveWaitRegistrations addObject: registration];
        }
    } @finally {
        [_lock unlock];
    }

    if (shouldSignalReceived)
        [registration signalReceivedValue: $assert_nonnil(receivedValue)];
    if (deliveredSendRegistration != nilptr)
        [$assert_nonnil(deliveredSendRegistration) signalDelivered];
    if (shouldSignalClosed)
        [registration signalClosed];
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
