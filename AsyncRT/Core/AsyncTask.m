#include "AsyncTask.h"

#pragma clang assume_nonnull begin

@implementation AsyncTask

- (instancetype)initResolvedWithResult: (id nillability_unspecified)result
{
    self = [super init];
    _status = AsyncTaskStatus_RESOLVED;
    _result = result;
    return self;
}

- (instancetype)initRejectedWithError: (OFException *)error
{
    self = [super init];
    _status = AsyncTaskStatus_REJECTED;
    _error = [error retain];
    return self;
}

+ (instancetype)resolvedWithResult: (id nillability_unspecified)result
{ return [[self alloc] initResolvedWithResult: result]; }

+ (instancetype)rejectedWithError: (OFException *)error
{ return [[self alloc] initRejectedWithError: error]; }

- (instancetype)initExecutingBlock: (id nillability_unspecified (^)())block
{
    self = [super init];
    _block = [block copy];
    _status = AsyncTaskStatus_PENDING;
    return self;
}

+ (instancetype)spawn: (id nillability_unspecified (^)())block
{ return [[self alloc] initExecutingBlock: block]; }
+ (instancetype)spawnOffloaded: (id nillability_unspecified (^)())block
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (id nillability_unspecified)await
{
    @throw [OFNotImplementedException exceptionWithSelector: _cmd object: self];
}

- (id nillability_unspecified)runUntilCompletion
{
    while (not self.isComplete)
        [OFRunLoop.currentRunLoop runUntilDate: [OFDate dateWithTimeIntervalSinceNow: 0.1]];
    return self->_result;
}


@end

#pragma clang assume_nonnull end
