#include <errno.h>
#include <limits.h>
#include <stdatomic.h>
// #if defined(NDEBUG)
#define MCO_NO_DEBUG
// #endif
#define MINICORO_IMPL
#include <AsyncRT/Vendor/minicoro.h>
#import <AsyncRT/Core/AsyncCoroutine.h>

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
static thread_local unretained AsyncCoroutine *nillable current_coroutine;
static OFConstantString *coroutine_root_key = @"asyncrt.AsyncCoroutine.root";
static void coroutine_entry(mco_coro *nativeCoroutine);

@implementation AsyncCoroutineException


- (instancetype)initWithCoroutine: (AsyncCoroutine *)coroutine
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
    return [OFString stringWithFormat: @"AsyncCoroutineException: %@", self.coroutine.describe];
}

@end

@implementation AsyncCoroutineStateTransitionFailedException


- (instancetype)initWithCoroutine: (AsyncCoroutine *)coroutine fromState: (enum AsyncCoroutineStatus)fromState toState: (enum AsyncCoroutineStatus)toState
{
    self = [super initWithCoroutine: coroutine];
    _fromState = fromState;
    _toState = toState;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"AsyncCoroutineStateTransitionFailedException: %@ cannot transition from %@ to %@", self.coroutine.describe, [AsyncCoroutine describeStatus: self.fromState], [AsyncCoroutine describeStatus: self.toState]];
}

@end

@implementation AsyncCoroutineMissingCallerException


- (instancetype)initWithCoroutine: (AsyncCoroutine *)coroutine operation: (OFString *)operation
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
    return [OFString stringWithFormat: @"AsyncCoroutineMissingCallerException: %@ cannot %@ without a caller", self.coroutine.describe, self.operation];
}

@end

@implementation AsyncCoroutineStackSetupFailedException


- (instancetype)initWithCoroutine: (AsyncCoroutine *)coroutine operation: (OFString *)operation errorCode: (int)errorCode
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

    return [OFString stringWithFormat: @"AsyncCoroutineStackSetupFailedException: %@ failed during %@: %@", self.coroutine.describe, self.operation, reason];
}

@end

@implementation AsyncCoroutine

+ (void)_replaceOwnedObjectAtSlot: (id nillable *)slot withObject: (id nillable)object [[direct]]
{
    if (*slot == object)
        return;

    [object retain];
    [*slot release];
    *slot = object;
}

+ (int)_errorCodeForMCOResult: (mco_result)result [[direct]]
{
    if (result == MCO_OUT_OF_MEMORY)
        return ENOMEM;

    return -(int)result;
}

+ (void)_throwForMCOResult: (mco_result)result coroutine: (AsyncCoroutine *)co operation: (OFString *)operation [[direct]]
{
    if (result == MCO_SUCCESS)
        return;

    @throw [[[AsyncCoroutineStackSetupFailedException alloc]
        initWithCoroutine: co
                 operation: operation
                 errorCode: [AsyncCoroutine _errorCodeForMCOResult: result]] autorelease];
}

+ (void)_enterNativeCoroutine: (mco_coro *)nativeCoroutine [[direct]]
{
    AsyncCoroutine *co = (AsyncCoroutine *)mco_get_user_data(nativeCoroutine);

    current_coroutine = co;
    co->_status = AsyncCoroutineStatus_RUNNING;

    @try {
        [co _finishWithResult: co->_block(co)];
    } @catch (id exception) {
        [co _clearYieldedState];
        [co _clearReturnedState];
        [AsyncCoroutine _replaceOwnedObjectAtSlot: &co->_raisedException withObject: exception];
        co->_caller = nilptr;
        co->_status = AsyncCoroutineStatus_DEAD;
    }
}

+ (AsyncCoroutine *)_currentCoroutine [[direct]]
{
    if (current_coroutine == nilptr) {
        OFMutableDictionary<OFString *, AsyncCoroutine *> *threadDictionary = OFThread.threadDictionary;
        AsyncCoroutine *rootCoroutine = nilptr;

        if (threadDictionary != nilptr)
            rootCoroutine = threadDictionary[coroutine_root_key];

        if (rootCoroutine == nilptr) {
            rootCoroutine = [[AsyncCoroutine alloc] _initAsRootCoroutine];
            threadDictionary[coroutine_root_key] = rootCoroutine;
            [rootCoroutine release];
        }

        current_coroutine = rootCoroutine;
    }

    return $assert_nonnil(current_coroutine);
}

- (void)_clearYieldedState [[direct]]
{
    _didYieldObject = false;
    [_yieldedObject release];
    _yieldedObject = nilptr;
}

- (void)_clearReturnedState [[direct]]
{
    _didReturnObject = false;
    [_returnedObject release];
    _returnedObject = nilptr;
}

- (void)_finishWithResult: (id nillable)result [[direct]]
{
    AsyncCoroutine *target = _caller;
    mco_coro *nativeCoroutine = (mco_coro *)_nativeCoroutine;

    [self _clearYieldedState];
    [self _clearReturnedState];
    [AsyncCoroutine _replaceOwnedObjectAtSlot: &_returnedObject withObject: result];
    [AsyncCoroutine _replaceOwnedObjectAtSlot: &_raisedException withObject: nilptr];
    _didReturnObject = true;
    _caller = nilptr;
    _status = AsyncCoroutineStatus_DEAD;
    current_coroutine = target;

    if (target != nilptr)
        target->_status = AsyncCoroutineStatus_RUNNING;

    nativeCoroutine->state = MCO_DEAD;
    _mco_jumpout(nativeCoroutine);
    __builtin_unreachable();
}

+ (OFString *)describeStatus: (enum AsyncCoroutineStatus)status
{
    switch (status) {
        case AsyncCoroutineStatus_READY: return @"READY";
        case AsyncCoroutineStatus_RUNNING: return @"RUNNING";
        case AsyncCoroutineStatus_SUSPENDED: return @"SUSPENDED";
        case AsyncCoroutineStatus_DEAD: return @"DEAD";
    }
}

- (OFString *)description
{
    return self.describe;
}

- (OFString *)describe
{
    return [OFString stringWithFormat: @"%p (%@)", self, [AsyncCoroutine describeStatus: self.status]];
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

- (instancetype)_initAsRootCoroutine [[direct]]
{
    self = [super init];
    _status = AsyncCoroutineStatus_RUNNING;
    _isRootCoroutine = true;
    return self;
}

+ (instancetype)withBlock: (id (^)(unretained AsyncCoroutine *co))block
{
    return [[[self alloc] initWithBlock: block] autorelease];
}

- (instancetype)initWithBlock: (id (^)(unretained AsyncCoroutine *co))block
{
    return [self initWithBlock: block stackSize: AsyncCoroutine.defaultStackSize];
}

- (instancetype)initWithBlock: (id (^)(unretained AsyncCoroutine *co))block stackSize: (size_t)stackSize
{
    mco_desc description;
    mco_coro *nativeCoroutine = nullptr;

    // even though the block parameter is marked as nonnull, we check it here jus in case the caller is a bit cheeky
    if (block == (id)0 or stackSize == 0)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _status = AsyncCoroutineStatus_READY;
    _block = [block copy];

    description = mco_desc_init(coroutine_entry, stackSize);
    description.user_data = self;
    [AsyncCoroutine _throwForMCOResult: mco_create(&nativeCoroutine, &description)
                        coroutine: self
                        operation: @"mco_create"];

    _nativeCoroutine = nativeCoroutine;
    _stackSize = nativeCoroutine->stack_size;

    return self;
}

- (void)dealloc
{
    [_block release];
    _block = (id (^)(unretained AsyncCoroutine *))0;
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

    if (_status == AsyncCoroutineStatus_DEAD or _status == AsyncCoroutineStatus_RUNNING)
        @throw [[[AsyncCoroutineStateTransitionFailedException alloc] initWithCoroutine: self fromState: self.status toState: AsyncCoroutineStatus_RUNNING] autorelease];

    AsyncCoroutine *previous = [AsyncCoroutine _currentCoroutine];
    [self _clearYieldedState];
    [self _clearReturnedState];
    [AsyncCoroutine _replaceOwnedObjectAtSlot: &_raisedException withObject: nilptr];
    current_coroutine = self;
    _caller = previous;

    if (previous->_status == AsyncCoroutineStatus_RUNNING)
        previous->_status = AsyncCoroutineStatus_SUSPENDED;

    result = mco_resume((mco_coro *)_nativeCoroutine);

    current_coroutine = previous;
    previous->_status = AsyncCoroutineStatus_RUNNING;

    [AsyncCoroutine _throwForMCOResult: result coroutine: self operation: @"mco_resume"];

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
    AsyncCoroutine *target;
    mco_result result;

    if (_status != AsyncCoroutineStatus_RUNNING)
        @throw [[[AsyncCoroutineStateTransitionFailedException alloc] initWithCoroutine: self fromState: self.status toState: AsyncCoroutineStatus_SUSPENDED] autorelease];
    if (_caller == nilptr)
        @throw [[[AsyncCoroutineMissingCallerException alloc] initWithCoroutine: self operation: @"yield"] autorelease];

    target = _caller;
    [AsyncCoroutine _replaceOwnedObjectAtSlot: &_yieldedObject withObject: object];
    _didYieldObject = true;
    _status = AsyncCoroutineStatus_SUSPENDED;
    current_coroutine = target;
    target->_status = AsyncCoroutineStatus_RUNNING;

    result = mco_yield((mco_coro *)_nativeCoroutine);

    if (result != MCO_SUCCESS) {
        current_coroutine = self;
        _status = AsyncCoroutineStatus_RUNNING;
        target->_status = AsyncCoroutineStatus_SUSPENDED;
        [AsyncCoroutine _throwForMCOResult: result coroutine: self operation: @"mco_yield"];
    }

    current_coroutine = self;
    _status = AsyncCoroutineStatus_RUNNING;
}

- (void)return
{
    [self return: nilptr];
}

- (void)return: (id nillable)object
{
    if (_status != AsyncCoroutineStatus_RUNNING)
        @throw [[[AsyncCoroutineStateTransitionFailedException alloc] initWithCoroutine: self fromState: self.status toState: AsyncCoroutineStatus_DEAD] autorelease];
    if (_caller == nilptr)
        @throw [[[AsyncCoroutineMissingCallerException alloc] initWithCoroutine: self operation: @"return"] autorelease];
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

    if (_status == AsyncCoroutineStatus_DEAD) {
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

static void coroutine_entry(mco_coro *nativeCoroutine)
{
    [AsyncCoroutine _enterNativeCoroutine: nativeCoroutine];
}

#pragma clang assume_nonnull end
