#pragma once

#include "Utilities/common.h"

#pragma clang assume_nonnull begin

@class AsyncChannel;

@interface AsyncChannelClosedException : OFException

@property(readonly, nonatomic) AsyncChannel *channel;
@property(readonly, nonatomic) OFString *operation;

- (instancetype)initWithChannel: (AsyncChannel *)channel operation: (OFString *)operation designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncChannel<__covariant T> : OFObject

@property(readonly, nonatomic) size_t capacity;
@property(readonly, nonatomic) bool isClosed;

- (instancetype)initWithCapacity: (size_t)capacity designated_initaliser;
- (void)send: (T)value;
- (T)receive;
- (void)close;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
