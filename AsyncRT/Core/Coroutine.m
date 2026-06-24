#include "Coroutine.h"

#define MINICORO_IMPL
#include <AsyncRT/Vendor/minicoro.h>

#pragma clang assume_nonnull begin

@implementation CoroutineException
- (instancetype)initWithCoroutine: (Coroutine *)coroutine
{
    self = [super init];
    _coroutine = coroutine;
    return self;
}

- (OFString *)description
{ return [OFString stringWithFormat: @"Coroutine exception in coroutine %@", _coroutine]; }

@end

@implementation CoroutineStateTransitionFailedException

- (instancetype)initWithCoroutine: (Coroutine *)coroutine fromState: (enum CoroutineStatus)fromState toState: (enum CoroutineStatus)toState
{
    self = [super initWithCoroutine: coroutine];
    _fromState = fromState;
    _toState = toState;
    return self;
}

- (OFString *)description
{ return [OFString stringWithFormat: @"Coroutine state transition failed in coroutine %@ from state %@ to state %@", _coroutine, describe(_fromState), describe(_toState)]; }

@end

@implementation CoroutineMissingCallerException

- (instancetype)initWithCoroutine: (Coroutine *)coroutine operation: (OFString *)operation
{
    self = [super initWithCoroutine: coroutine];
    _operation = operation;
    return self;
}

- (OFString *)description
{ return [OFString stringWithFormat: @"Coroutine missing caller in coroutine %@ for operation %@", _coroutine, _operation]; }

@end

@implementation CoroutineStackSetupFailedException

- (instancetype)initWithCoroutine: (Coroutine *)coroutine operation: (OFString *)operation errorCode: (int)errorCode
{
    self = [super initWithCoroutine: coroutine];
    _operation = operation;
    _errorCode = errorCode;
    return self;
}

- (OFString *)description
{ return [OFString stringWithFormat: @"Coroutine stack setup failed in coroutine %@ for operation %@! Error code: %d", _coroutine, _operation, _errorCode]; }

@end

static size_t default_stack_size = 1024 * 1024;

@implementation Coroutine {
    mco_coro _coro;
}

+ (instancetype)fromBlock: (id (^)(unretained Coroutine *co))block
{ return [[self alloc] initWithBlock: block]; }

+ (size_t)defaultStackSize
{ return default_stack_size; }

+ (void)setDefaultStackSize: (size_t)stackSize
{
    default_stack_size = stackSize;
}

- (instancetype)initWithBlock: (id (^)(unretained Coroutine *co))block
{ return [self initWithBlock: block stackSize: default_stack_size]; }

@end

#pragma clang assume_nonnull end
