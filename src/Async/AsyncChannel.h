#pragma once

#include "Utilities/common.h"

#pragma clang assume_nonnull begin

@class AsyncChannel;

@interface AsyncChannelClosedException : OFException {
@private
    AsyncChannel *_channel;
    OFString *_operation;
}

@property(readonly, nonatomic) AsyncChannel *channel;
@property(readonly, nonatomic) OFString *operation;

- (instancetype)initWithChannel: (AsyncChannel *)channel operation: (OFString *)operation OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncChannel<__covariant T> : OFObject

@property(readonly, nonatomic) size_t capacity;
@property(readonly, nonatomic, getter=isClosed) bool closed;

- (instancetype)initWithCapacity: (size_t)capacity OF_DESIGNATED_INITIALIZER;
- (void)send: (T)value;
- (T)receive;
- (void)close;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
