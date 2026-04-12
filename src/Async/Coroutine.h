#pragma once

#include "Utilities/common.h"

#pragma clang assume_nonnull begin

enum [[clang::enum_extensibility(closed)]] CoroutineStatus {
    CoroutineStatus_READY,
    CoroutineStatus_RUNNING,
    CoroutineStatus_SUSPENDED,
    CoroutineStatus_DEAD
};

@class Coroutine;

@interface CoroutineException : OFException

@property(readonly) Coroutine *coroutine;

- (instancetype)initWithCoroutine: (Coroutine *)coroutine designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface CoroutineStateTransitionFailedException : CoroutineException

@property(readonly) enum CoroutineStatus fromState;
@property(readonly) enum CoroutineStatus toState;

- (instancetype)initWithCoroutine: (Coroutine *)coroutine fromState: (enum CoroutineStatus)fromState toState: (enum CoroutineStatus)toState designated_initaliser;
- (instancetype)initWithCoroutine: (Coroutine *)coroutine OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface CoroutineMissingCallerException : CoroutineException

@property(readonly) OFString *operation;

- (instancetype)initWithCoroutine: (Coroutine *)coroutine operation: (OFString *)operation designated_initaliser;
- (instancetype)initWithCoroutine: (Coroutine *)coroutine OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface CoroutineStackSetupFailedException : CoroutineException

@property(readonly) OFString *operation;
@property(readonly) int errorCode;

- (instancetype)initWithCoroutine: (Coroutine *)coroutine operation: (OFString *)operation errorCode: (int)errorCode designated_initaliser;
- (instancetype)initWithCoroutine: (Coroutine *)coroutine OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

[[clang::objc_subclassing_restricted, clang::objc_direct_members]]
@interface Coroutine<__covariant T> : OFObject<OFFastEnumeration> {
@public // public so that the assembly trampoline can access these fields directly
    enum CoroutineStatus _status;
    void *nillable _nativeCoroutine;
    size_t _stackSize;
    bool _isRootCoroutine;
    T (^_block)(unretained Coroutine *co);
    unretained Coroutine *nillable _caller;
    T nillable _yieldedObject;
    bool _didYieldObject;
    T nillable _returnedObject;
    bool _didReturnObject;
    id nillable _raisedException;
    OFMutableArray *nillable _fastEnumerationBatch;
    unsigned long _fastEnumerationMutations;
}

@property(readonly) enum CoroutineStatus status;
@property(readonly) T nillable yieldedObject;
@property(readonly) bool didYieldObject;
@property(readonly) T nillable returnedObject;
@property(readonly) bool didReturnObject;
@property(class, nonatomic) size_t defaultStackSize;
@property(readonly) size_t stackSize;

+ (instancetype)withBlock: (T (^)(unretained Coroutine *co))block;
+ (OFString *)describeStatus: (enum CoroutineStatus)status;
- (instancetype)initWithBlock: (T (^)(unretained Coroutine *co))block;
- (instancetype)initWithBlock: (T (^)(unretained Coroutine *co))block stackSize: (size_t)stackSize;
- (OFString *)describe;
- (T nillable)resume;
- (void)yield;
- (void)yield: (T nillable)object;
- (void)return;
- (void)return: (T nillable)object;

@end

#pragma clang assume_nonnull end
