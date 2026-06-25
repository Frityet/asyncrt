#include <AsyncRT/Common/Common.h>

#pragma clang assume_nonnull begin

enum [[clang::enum_extensibility(closed)]] CoroutineStatus {
    CoroutineStatus_READY,
    CoroutineStatus_RUNNING,
    CoroutineStatus_SUSPENDED,
    CoroutineStatus_DEAD
};

[[clang::overloadable]]
static inline OFString *describe(enum CoroutineStatus status)
{
    switch (status) {
        case CoroutineStatus_READY:
            return @"ready";
        case CoroutineStatus_RUNNING:
            return @"running";
        case CoroutineStatus_SUSPENDED:
            return @"suspended";
        case CoroutineStatus_DEAD:
            return @"dead";
    }

    return @"unknown";
}


@class Coroutine;

@interface CoroutineException : OFException {
    @protected Coroutine *_coroutine;
}

@property(readonly) Coroutine *coroutine;

- (instancetype)initWithCoroutine: (Coroutine *)coroutine [[designated_initailiser]];
- (instancetype)init [[unavailable]];

@end

[[subclassing_restricted, direct_members]]
@interface CoroutineStateTransitionFailedException : CoroutineException

@property(readonly) enum CoroutineStatus fromState;
@property(readonly) enum CoroutineStatus toState;

- (instancetype)initWithCoroutine: (Coroutine *)coroutine fromState: (enum CoroutineStatus)fromState toState: (enum CoroutineStatus)toState [[designated_initailiser]];
- (instancetype)initWithCoroutine: (Coroutine *)coroutine [[unavailable]];
- (instancetype)init [[unavailable]];

@end

[[subclassing_restricted, direct_members]]
@interface CoroutineMissingCallerException : CoroutineException

@property(readonly) OFString *operation;

- (instancetype)initWithCoroutine: (Coroutine *)coroutine operation: (OFString *)operation [[designated_initailiser]];
- (instancetype)initWithCoroutine: (Coroutine *)coroutine [[unavailable]];
- (instancetype)init [[unavailable]];

@end

[[subclassing_restricted, direct_members]]
@interface CoroutineStackSetupFailedException : CoroutineException

@property(readonly) OFString *operation;
@property(readonly) int errorCode;

- (instancetype)initWithCoroutine: (Coroutine *)coroutine operation: (OFString *)operation errorCode: (int)errorCode [[designated_initailiser]];
- (instancetype)initWithCoroutine: (Coroutine *)coroutine [[unavailable]];
- (instancetype)init [[unavailable]];

@end

[[subclassing_restricted, direct_members]]
@interface Coroutine<covariant T> : OFObject<OFFastEnumeration> {
@private
    bool _isRootCoroutine;
    T (^_block)(unretained Coroutine *co);
    unretained Coroutine *nillable _caller;
    id nillable _raisedException;
    OFMutableArray<T> *nillable _fastEnumerationBatch;
    unsigned long _fastEnumerationMutations;
}

@property(readonly) enum CoroutineStatus status;
@property(readonly) T nillable yieldedObject;
@property(readonly) bool didYieldObject;
@property(readonly) T nillable returnedObject;
@property(readonly) bool didReturnObject;
@property(class, nonatomic) size_t defaultStackSize;
@property(readonly) size_t stackSize;

+ (instancetype)fromBlock: (T (^)(unretained Coroutine *co))block;
- (instancetype)initWithBlock: (T (^)(unretained Coroutine *co))block;
- (instancetype)initWithBlock: (T (^)(unretained Coroutine *co))block stackSize: (size_t)stackSize;
- (T nillable)resume;
- (void)yield;
- (void)yield: (T nillable)object;
- (void)return;
- (void)return: (T nillable)object;

@end

#pragma clang assume_nonnull end
