#pragma once

#include <AsyncRT/Common/common.h>

#pragma clang assume_nonnull begin

// struct Behaviour;

// struct CownBase {
//   std::atomic<Request*> tail = nullptr;
//   std::uint64_t id;
// };

// struct Request {
//   CownBase* target;
//   Behaviour* owner;

//   std::atomic<Request*> next = nullptr;
//   std::atomic<bool> enqueue_done = false;
// };

// struct Behaviour {
//   std::atomic<int> pending;
//   std::vector<Request*> requests;
//   std::function<void()> body;
// };

@class AsyncBehaviour;
@class AsyncCown;
@interface Request : OFObject

@property(nonatomic, readonly) AsyncCown *target;
@property(nonatomic, readonly) AsyncBehaviour *owner;

@end

@interface AsyncCown<T> : OFObject {
    @private T _value;
    @private atomic_t(Request *) _tail;
    @private uint64_t _id;
}

+ (instancetype)withValue: (T)value;
- (instancetype)initWithValue: (T)value [[designated_initailiser]];
- (void)whenAvailable: (void (^)(T value))block;

@end

#pragma clang assume_nonnull end