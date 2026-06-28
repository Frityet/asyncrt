#include "Coroutine.h"

#include <errno.h>
#include <limits.h>
#include <stdatomic.h>
#if defined(NDEBUG)
#   define MCO_NO_DEBUG
#endif

#define MINICORO_IMPL
#define MCO_USE_VMEM_ALLOCATOR
#include <AsyncRT/Vendor/minicoro.h>

#define ASAN __has_feature(address_sanitizer)
#define TSAN __has_feature(thread_sanitizer)

#pragma clang assume_nonnull begin


#if ASAN or TSAN
    static atomic_t(size_t) default_stack_size = 2 * 1024 * 1024;
#else
    static atomic_t(size_t) default_stack_size = 256 * 1024;
#endif

static thread_local unretained Coroutine *nillable current_coroutine;
static void coroutine_entry(mco_coro *nativeCoroutine);

@implementation CoroutineException
- (instancetype)initWithCoroutine: (Coroutine *)coroutine
{
    self = [super init];
    _coroutine = [coroutine retain];
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
    _operation = [operation copy];
    return self;
}

- (OFString *)description
{ return [OFString stringWithFormat: @"Coroutine missing caller in coroutine %@ for operation %@", _coroutine, _operation]; }

@end

@implementation CoroutineStackSetupFailedException

- (instancetype)initWithCoroutine: (Coroutine *)coroutine operation: (OFString *)operation errorCode: (int)errorCode
{
    self = [super initWithCoroutine: coroutine];
    _operation = [operation copy];
    _errorCode = errorCode;
    return self;
}

- (OFString *)description
{ return [OFString stringWithFormat: @"Coroutine stack setup failed in coroutine %@ for operation %@! Error code: %d", _coroutine, _operation, _errorCode]; }

@end

@implementation Coroutine {
    mco_coro *_coro;
}

+ (instancetype)fromBlock: (id (^)(unretained Coroutine *co))block
{ return [[[self alloc] initWithBlock: block] autorelease]; }

+ (size_t)defaultStackSize
{ return default_stack_size; }

+ (void)setDefaultStackSize: (size_t)stackSize
{ default_stack_size = stackSize; }

- (instancetype)initWithBlock: (id (^)(unretained Coroutine *co))block
{ return [self initWithBlock: block stackSize: default_stack_size]; }

- (instancetype)initWithBlock: (id nonnil (^)(Coroutine *nonnil))block stackSize: (size_t)stksz
{
    if (stksz < MCO_MIN_STACK_SIZE)
        @throw [[[CoroutineStackSetupFailedException alloc] initWithCoroutine: self operation: @"mco_desc_init" errorCode: EINVAL] autorelease];
    
    self = [super init];
    _status = CoroutineStatus_READY;
    _block = [block copy];

    mco_desc desc = mco_desc_init(coroutine_entry, stksz);
    desc.user_data = self;

    mco_result stat = mco_create(&_coro, &desc);
    if (stat != MCO_SUCCESS)
        @throw [[[CoroutineStackSetupFailedException alloc] initWithCoroutine: self operation: @"mco_create" errorCode: stat] autorelease];
    _stackSize = _coro->stack_size;

    return self;
}

- (instancetype)_initAsRootCoroutine [[direct]]
{
    self = [super init];
    _status = CoroutineStatus_RUNNING;
    _isRootCoroutine = true;
    return self;
}

+ (Coroutine *)_current [[direct]]
{
    if (current_coroutine == nilptr)
        current_coroutine = [[Coroutine alloc] _initAsRootCoroutine];

    return $assert_nonnil(current_coroutine);
}

- (void)_clearYieldedState [[direct]]
{
    _didYieldObject = false;
    _yieldedObject = nilptr;
}

- (void)_clearReturnedState [[direct]]
{
    _didReturnObject = false;
    _returnedObject = nilptr;
}

- (id nillable)resume
{
    if (_status == CoroutineStatus_DEAD or _status == CoroutineStatus_RUNNING)
        @throw [[[CoroutineStateTransitionFailedException alloc] initWithCoroutine: self fromState: self.status toState: CoroutineStatus_RUNNING] autorelease];

    auto prev = Coroutine._current;
    [self _clearYieldedState];
    [self _clearReturnedState];

    [_raisedException release];
    _raisedException = nilptr;

    current_coroutine = self;
    _caller = prev;

    if (prev->_status == CoroutineStatus_RUNNING)
        prev->_status = CoroutineStatus_SUSPENDED;

    mco_result result = mco_resume(_coro);

    current_coroutine = prev;
    prev->_status = CoroutineStatus_RUNNING;

    // [Coroutine _throwForMCOResult: result coroutine: self operation: @"mco_resume"];
    if (result != MCO_SUCCESS)
        @throw [[[CoroutineStackSetupFailedException alloc] initWithCoroutine: self operation: @"mco_resume" errorCode: result] autorelease];

    if (_raisedException != nilptr)
        @throw [[_raisedException retain] autorelease];

    return _didYieldObject ? _yieldedObject : _returnedObject;
}

- (void)yield
{ [self yield: nilptr]; }

- (void)yield: (id nillable)object
{
    if (_status != CoroutineStatus_RUNNING)
        @throw [[[CoroutineStateTransitionFailedException alloc] initWithCoroutine: self fromState: self.status toState: CoroutineStatus_SUSPENDED] autorelease];
    if (_caller == nilptr)
        @throw [[[CoroutineMissingCallerException alloc] initWithCoroutine: self operation: @"yield"] autorelease];

    Coroutine *target = _caller;
    [_yieldedObject release];
    _yieldedObject = [object retain];
    _didYieldObject = true;
    _status = CoroutineStatus_SUSPENDED;
    current_coroutine = target;
    target->_status = CoroutineStatus_RUNNING;

    mco_result result = mco_yield(_coro);
    if (result != MCO_SUCCESS) {
        current_coroutine = self;
        _status = CoroutineStatus_RUNNING;
        target->_status = CoroutineStatus_SUSPENDED;

        if (result != MCO_SUCCESS)
            @throw [[[CoroutineStackSetupFailedException alloc] initWithCoroutine: self operation: @"mco_yield" errorCode: result] autorelease];
    }

    current_coroutine = self;
    _status = CoroutineStatus_RUNNING;
}

- (void)return
{
    [self return: nilptr];
}

- (void)return: (id nillable)object
{
    if (_status != CoroutineStatus_RUNNING)
        @throw [[[CoroutineStateTransitionFailedException alloc] initWithCoroutine: self fromState: self.status toState: CoroutineStatus_DEAD] autorelease];
    if (_caller == nilptr)
        @throw [[[CoroutineMissingCallerException alloc] initWithCoroutine: self operation: @"return"] autorelease];
    
    Coroutine *target = _caller;
    [self _clearYieldedState];
    [self _clearReturnedState];

    [_returnedObject release];
    _returnedObject = [object retain];

    [_raisedException release];
    _raisedException = nilptr;

    _didReturnObject = true;
    _caller = nilptr;
    _status = CoroutineStatus_DEAD;
    current_coroutine = target;

    if (target != nilptr)
        target->_status = CoroutineStatus_RUNNING;

    _coro->state = MCO_DEAD;
    _mco_jumpout(_coro);
    __builtin_unreachable();
}

- (void)dealloc
{
    if (not _isRootCoroutine)
        mco_destroy(_coro);
    [_block release];
    [super dealloc];
}

- (int)countByEnumeratingWithState: (OFFastEnumerationState *)state objects: (id unretained _Nonnull *_Nonnull)objects count: (int)count
 {
    if (count <= 0 or state->state == ULONG_MAX)
        return 0;

    if (_fastEnumerationBatch == nilptr)
        _fastEnumerationBatch = [[OFMutableArray arrayWithCapacity: (size_t)count] retain];
    else
        [_fastEnumerationBatch removeAllObjects];

    state->itemsPtr = objects;
    state->mutationsPtr = &_fastEnumerationMutations;

    if (_status == CoroutineStatus_DEAD) {
        state->state = ULONG_MAX;
        return 0;
    }

    int returned = 0;
    while (returned < count) {
        id object = [self resume];
        if (not _didYieldObject)
            break;
        if (object == nilptr)
            @throw [[[OFInvalidArgumentException alloc] init] autorelease];

        [_fastEnumerationBatch addObject: object];
        objects[returned++] = object;
    }

    if (returned == 0) {
        state->state = ULONG_MAX;
        return 0;
    }

    state->state += returned;
    return returned;
}

+ (void)_enterCoroutine: (mco_coro *)coro [[direct]]
{
    Coroutine *co = mco_get_user_data(coro);

    current_coroutine = co;
    co->_status = CoroutineStatus_RUNNING;

    @try {
        Coroutine *target = co->_caller;
        [co _clearYieldedState];
        [co _clearReturnedState];

        [co->_returnedObject release];
        co->_returnedObject = [co->_block(co) retain];

        [co->_raisedException release];
        co->_raisedException = nilptr;

        co->_didReturnObject = true;
        co->_caller = nilptr;
        co->_status = CoroutineStatus_DEAD;
        current_coroutine = target;

        if (target != nilptr)
            target->_status = CoroutineStatus_RUNNING;

        co->_coro->state = MCO_DEAD;
        _mco_jumpout(co->_coro);
        __builtin_unreachable();
    } @catch (id exception) {
        [co _clearYieldedState];
        [co _clearReturnedState];
        // [Coroutine _replaceOwnedObjectAtSlot: &co->_raisedException withObject: exception];
        [co->_raisedException release];
        co->_raisedException = [exception retain];

        co->_caller = nilptr;
        co->_status = CoroutineStatus_DEAD;
    }
}

@end

static void coroutine_entry(mco_coro *coro)
{
    [Coroutine _enterCoroutine: coro];
}

#pragma clang assume_nonnull end
