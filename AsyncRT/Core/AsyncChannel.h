#pragma once

#include <AsyncRT/Common/common.h>

#pragma clang assume_nonnull begin

@class AsyncChannel;

[[subclassing_restricted, direct_members]]
@interface AsyncChannelClosedException : OFException

@property(readonly, nonatomic) AsyncChannel *channel;
@property(readonly, nonatomic) OFString *operation;

- (instancetype)initWithChannel: (AsyncChannel *)channel operation: (OFString *)operation [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncChannel<covariant T> : OFObject

@property(readonly, nonatomic) size_t capacity;
@property(readonly, nonatomic) bool isClosed;

- (instancetype)initWithCapacity: (size_t)capacity [[designated_initailiser]] [[direct]];
- (void)send: (T)value [[direct]];
- (T)receive [[direct]];
- (void)close [[direct]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
