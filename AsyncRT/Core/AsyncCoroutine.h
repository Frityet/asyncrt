#pragma once

#include <AsyncRT/Common/common.h>

#pragma clang assume_nonnull begin

enum [[clang::enum_extensibility(closed)]] AsyncCoroutineStatus {
    AsyncCoroutineStatus_READY,
    AsyncCoroutineStatus_RUNNING,
    AsyncCoroutineStatus_SUSPENDED,
    AsyncCoroutineStatus_DEAD
};

@class AsyncCoroutine;

@interface AsyncCoroutineException : OFException

@property(readonly) AsyncCoroutine *coroutine;

- (instancetype)initWithCoroutine: (AsyncCoroutine *)coroutine [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncCoroutineStateTransitionFailedException : AsyncCoroutineException

@property(readonly) enum AsyncCoroutineStatus fromState;
@property(readonly) enum AsyncCoroutineStatus toState;

- (instancetype)initWithCoroutine: (AsyncCoroutine *)coroutine fromState: (enum AsyncCoroutineStatus)fromState toState: (enum AsyncCoroutineStatus)toState [[designated_initailiser]];
- (instancetype)initWithCoroutine: (AsyncCoroutine *)coroutine OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncCoroutineMissingCallerException : AsyncCoroutineException

@property(readonly) OFString *operation;

- (instancetype)initWithCoroutine: (AsyncCoroutine *)coroutine operation: (OFString *)operation [[designated_initailiser]];
- (instancetype)initWithCoroutine: (AsyncCoroutine *)coroutine OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncCoroutineStackSetupFailedException : AsyncCoroutineException

@property(readonly) OFString *operation;
@property(readonly) int errorCode;

- (instancetype)initWithCoroutine: (AsyncCoroutine *)coroutine operation: (OFString *)operation errorCode: (int)errorCode [[designated_initailiser]];
- (instancetype)initWithCoroutine: (AsyncCoroutine *)coroutine OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface AsyncCoroutine<covariant T> : OFObject<OFFastEnumeration> {
@public // public so that the assembly trampoline can access these fields directly
    enum AsyncCoroutineStatus _status;
    void *nillable _nativeCoroutine;
    size_t _stackSize;
    bool _isRootCoroutine;
    T (^_block)(unretained AsyncCoroutine *co);
    unretained AsyncCoroutine *nillable _caller;
    T nillable _yieldedObject;
    bool _didYieldObject;
    T nillable _returnedObject;
    bool _didReturnObject;
    id nillable _raisedException;
    OFMutableArray *nillable _fastEnumerationBatch;
    unsigned long _fastEnumerationMutations;
}

@property(readonly) enum AsyncCoroutineStatus status;
@property(readonly) T nillable yieldedObject;
@property(readonly) bool didYieldObject;
@property(readonly) T nillable returnedObject;
@property(readonly) bool didReturnObject;
@property(class, nonatomic) size_t defaultStackSize;
@property(readonly) size_t stackSize;

+ (instancetype)withBlock: (T (^)(unretained AsyncCoroutine *co))block;
+ (OFString *)describeStatus: (enum AsyncCoroutineStatus)status;
- (instancetype)initWithBlock: (T (^)(unretained AsyncCoroutine *co))block;
- (instancetype)initWithBlock: (T (^)(unretained AsyncCoroutine *co))block stackSize: (size_t)stackSize;
- (OFString *)describe;
- (T nillable)resume;
- (void)yield;
- (void)yield: (T nillable)object;
- (void)return;
- (void)return: (T nillable)object;

@end

#pragma clang assume_nonnull end
