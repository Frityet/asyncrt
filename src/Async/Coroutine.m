#include <errno.h>
#include <limits.h>
#include <stdatomic.h>
// #if defined(NDEBUG)
#define MCO_NO_DEBUG
// #endif
#define MINICORO_IMPL
#include "extern/minicoro.h"
#import "Async/Coroutine.h"

#if defined(__has_feature)
# if __has_feature(address_sanitizer)
#  define ASYNC_HAVE_ASAN 1
# endif
# if __has_feature(thread_sanitizer)
#  define ASYNC_HAVE_TSAN 1
# endif
#endif

#if defined(__SANITIZE_ADDRESS__)
# define ASYNC_HAVE_ASAN 1
#endif

#if defined(__SANITIZE_THREAD__)
# define ASYNC_HAVE_TSAN 1
#endif

#pragma clang assume_nonnull begin

#if defined(ASYNC_HAVE_ASAN) || defined(ASYNC_HAVE_TSAN)
static atomic_t(size_t) coroutine_default_stack_size = 2 * 1024 * 1024;
#else
static atomic_t(size_t) coroutine_default_stack_size = 256 * 1024;
#endif
static thread_local unretained Coroutine *nillable current_coroutine;
static OFConstantString *coroutine_root_key = @"asyncrt.Coroutine.root";

[[direct_members]]
@interface Coroutine ()

- (instancetype)_initAsRootCoroutine;
+ (void)_replaceOwnedObjectAtSlot: (id nillable *)slot withObject: (id nillable)object;
+ (int)_errorCodeForMCOResult: (mco_result)result;
+ (void)_throwForMCOResult: (mco_result)result coroutine: (Coroutine *)co operation: (OFString *)operation;
+ (void)_enterNativeCoroutine: (mco_coro *)nativeCoroutine;
+ (Coroutine *)_currentCoroutine;
- (void)_clearYieldedState;
- (void)_clearReturnedState;
- (void)_finishWithResult: (id nillable)result;

@end

static void coroutine_entry(mco_coro *nativeCoroutine)
{
    [Coroutine _enterNativeCoroutine: nativeCoroutine];
}

@implementation CoroutineException


- (instancetype)initWithCoroutine: (Coroutine *)coroutine
{
    self = [super init];
    _coroutine = [coroutine retain];
    return self;
}

- (void)dealloc
{
    [_coroutine release];
    [super dealloc];
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"CoroutineException: %@", self.coroutine.describe];
}

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
{
    return [OFString stringWithFormat: @"CoroutineStateTransitionFailedException: %@ cannot transition from %@ to %@", self.coroutine.describe, [Coroutine describeStatus: self.fromState], [Coroutine describeStatus: self.toState]];
}

@end

@implementation CoroutineMissingCallerException


- (instancetype)initWithCoroutine: (Coroutine *)coroutine operation: (OFString *)operation
{
    self = [super initWithCoroutine: coroutine];
    _operation = [operation copy];
    return self;
}

- (void)dealloc
{
    [_operation release];
    [super dealloc];
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"CoroutineMissingCallerException: %@ cannot %@ without a caller", self.coroutine.describe, self.operation];
}

@end

@implementation CoroutineStackSetupFailedException


- (instancetype)initWithCoroutine: (Coroutine *)coroutine operation: (OFString *)operation errorCode: (int)errorCode
{
    self = [super initWithCoroutine: coroutine];
    _operation = [operation copy];
    _errorCode = errorCode;
    return self;
}

- (void)dealloc
{
    [_operation release];
    [super dealloc];
}

- (OFString *)description
{
    OFString *reason;

    if (self.errorCode < 0)
        reason = [OFString stringWithUTF8String: mco_result_description((mco_result)-self.errorCode)];
    else
        reason = OFStrError(self.errorCode);

    return [OFString stringWithFormat: @"CoroutineStackSetupFailedException: %@ failed during %@: %@", self.coroutine.describe, self.operation, reason];
}

@end

@implementation Coroutine

+ (void)_replaceOwnedObjectAtSlot: (id nillable *)slot withObject: (id nillable)object
{
    if (*slot == object)
        return;

    [object retain];
    [*slot release];
    *slot = object;
}

+ (int)_errorCodeForMCOResult: (mco_result)result
{
    if (result == MCO_OUT_OF_MEMORY)
        return ENOMEM;

    return -(int)result;
}

+ (void)_throwForMCOResult: (mco_result)result coroutine: (Coroutine *)co operation: (OFString *)operation
{
    if (result == MCO_SUCCESS)
        return;

    @throw [[[CoroutineStackSetupFailedException alloc]
        initWithCoroutine: co
                 operation: operation
                 errorCode: [Coroutine _errorCodeForMCOResult: result]] autorelease];
}

+ (void)_enterNativeCoroutine: (mco_coro *)nativeCoroutine
{
    Coroutine *co = (Coroutine *)mco_get_user_data(nativeCoroutine);

    current_coroutine = co;
    co->_status = CoroutineStatus_RUNNING;

    @try {
        [co _finishWithResult: co->_block(co)];
    } @catch (id exception) {
        [co _clearYieldedState];
        [co _clearReturnedState];
        [Coroutine _replaceOwnedObjectAtSlot: &co->_raisedException withObject: exception];
        co->_caller = nilptr;
        co->_status = CoroutineStatus_DEAD;
    }
}

+ (Coroutine *)_currentCoroutine
{
    if (current_coroutine == nilptr) {
        OFMutableDictionary<OFString *, Coroutine *> *threadDictionary = OFThread.threadDictionary;
        Coroutine *rootCoroutine = nilptr;

        if (threadDictionary != nilptr)
            rootCoroutine = threadDictionary[coroutine_root_key];

        if (rootCoroutine == nilptr) {
            rootCoroutine = [[Coroutine alloc] _initAsRootCoroutine];
            threadDictionary[coroutine_root_key] = rootCoroutine;
            [rootCoroutine release];
        }

        current_coroutine = rootCoroutine;
    }

    return $assert_nonnil(current_coroutine);
}

- (void)_clearYieldedState
{
    _didYieldObject = false;
    [_yieldedObject release];
    _yieldedObject = nilptr;
}

- (void)_clearReturnedState
{
    _didReturnObject = false;
    [_returnedObject release];
    _returnedObject = nilptr;
}

- (void)_finishWithResult: (id nillable)result
{
    Coroutine *target = _caller;
    mco_coro *nativeCoroutine = (mco_coro *)_nativeCoroutine;

    [self _clearYieldedState];
    [self _clearReturnedState];
    [Coroutine _replaceOwnedObjectAtSlot: &_returnedObject withObject: result];
    [Coroutine _replaceOwnedObjectAtSlot: &_raisedException withObject: nilptr];
    _didReturnObject = true;
    _caller = nilptr;
    _status = CoroutineStatus_DEAD;
    current_coroutine = target;

    if (target != nilptr)
        target->_status = CoroutineStatus_RUNNING;

    nativeCoroutine->state = MCO_DEAD;
    _mco_jumpout(nativeCoroutine);
    __builtin_unreachable();
}

+ (OFString *)describeStatus: (enum CoroutineStatus)status
{
    switch (status) {
        case CoroutineStatus_READY: return @"READY";
        case CoroutineStatus_RUNNING: return @"RUNNING";
        case CoroutineStatus_SUSPENDED: return @"SUSPENDED";
        case CoroutineStatus_DEAD: return @"DEAD";
    }
}

- (OFString *)description
{
    return self.describe;
}

- (OFString *)describe
{
    return [OFString stringWithFormat: @"%p (%@)", self, [Coroutine describeStatus: self.status]];
}

+ (size_t)defaultStackSize
{
    return atomic_load_explicit(&coroutine_default_stack_size, memory_order_relaxed);
}

+ (void)setDefaultStackSize: (size_t)defaultStackSize
{
    if (defaultStackSize == 0)
        @throw [OFInvalidArgumentException exception];

    atomic_store_explicit(&coroutine_default_stack_size, defaultStackSize, memory_order_relaxed);
}

- (size_t)stackSize
{
    return _stackSize;
}

- (instancetype)_initAsRootCoroutine
{
    self = [super init];
    _status = CoroutineStatus_RUNNING;
    _isRootCoroutine = true;
    return self;
}

+ (instancetype)withBlock: (id (^)(unretained Coroutine *co))block
{
    return [[[self alloc] initWithBlock: block] autorelease];
}

- (instancetype)initWithBlock: (id (^)(unretained Coroutine *co))block
{
    return [self initWithBlock: block stackSize: Coroutine.defaultStackSize];
}

- (instancetype)initWithBlock: (id (^)(unretained Coroutine *co))block stackSize: (size_t)stackSize
{
    mco_desc description;
    mco_coro *nativeCoroutine = nullptr;

    // even though the block parameter is marked as nonnull, we check it here jus in case the caller is a bit cheeky
    if (block == (id)0 or stackSize == 0)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _status = CoroutineStatus_READY;
    _block = [block copy];

    description = mco_desc_init(coroutine_entry, stackSize);
    description.user_data = self;
    [Coroutine _throwForMCOResult: mco_create(&nativeCoroutine, &description)
                        coroutine: self
                        operation: @"mco_create"];

    _nativeCoroutine = nativeCoroutine;
    _stackSize = nativeCoroutine->stack_size;

    return self;
}

- (void)dealloc
{
    [_block release];
    _block = (id (^)(unretained Coroutine *))0;
    _caller = nilptr;
    [_yieldedObject release];
    _yieldedObject = nilptr;
    [_returnedObject release];
    _returnedObject = nilptr;
    [_raisedException release];
    _raisedException = nilptr;
    [_fastEnumerationBatch release];
    _fastEnumerationBatch = nilptr;
    if (_nativeCoroutine != nullptr and not _isRootCoroutine) {
        (void)mco_destroy((mco_coro *)_nativeCoroutine);
        _nativeCoroutine = nullptr;
    }
    [super dealloc];
}

- (id nillable)resume
{
    mco_result result;

    if (_status == CoroutineStatus_DEAD or _status == CoroutineStatus_RUNNING)
        @throw [[[CoroutineStateTransitionFailedException alloc] initWithCoroutine: self fromState: self.status toState: CoroutineStatus_RUNNING] autorelease];

    Coroutine *previous = [Coroutine _currentCoroutine];
    [self _clearYieldedState];
    [self _clearReturnedState];
    [Coroutine _replaceOwnedObjectAtSlot: &_raisedException withObject: nilptr];
    current_coroutine = self;
    _caller = previous;

    if (previous->_status == CoroutineStatus_RUNNING)
        previous->_status = CoroutineStatus_SUSPENDED;

    result = mco_resume((mco_coro *)_nativeCoroutine);

    current_coroutine = previous;
    previous->_status = CoroutineStatus_RUNNING;

    [Coroutine _throwForMCOResult: result coroutine: self operation: @"mco_resume"];

    if (_raisedException != nilptr)
        @throw [[_raisedException retain] autorelease];

    return _didYieldObject ? _yieldedObject : _returnedObject;
}

- (void)yield
{
    [self yield: nilptr];
}

- (void)yield: (id nillable)object
{
    Coroutine *target;
    mco_result result;

    if (_status != CoroutineStatus_RUNNING)
        @throw [[[CoroutineStateTransitionFailedException alloc] initWithCoroutine: self fromState: self.status toState: CoroutineStatus_SUSPENDED] autorelease];
    if (_caller == nilptr)
        @throw [[[CoroutineMissingCallerException alloc] initWithCoroutine: self operation: @"yield"] autorelease];

    target = _caller;
    [Coroutine _replaceOwnedObjectAtSlot: &_yieldedObject withObject: object];
    _didYieldObject = true;
    _status = CoroutineStatus_SUSPENDED;
    current_coroutine = target;
    target->_status = CoroutineStatus_RUNNING;

    result = mco_yield((mco_coro *)_nativeCoroutine);

    if (result != MCO_SUCCESS) {
        current_coroutine = self;
        _status = CoroutineStatus_RUNNING;
        target->_status = CoroutineStatus_SUSPENDED;
        [Coroutine _throwForMCOResult: result coroutine: self operation: @"mco_yield"];
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
    [self _finishWithResult: object];
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

    state->state += (unsigned long)returned;
    return returned;
}

@end

#pragma clang assume_nonnull end
