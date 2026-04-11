#import "Async/AsyncRuntimeInternal.h"

#pragma clang assume_nonnull begin

static OFOnceControl async_unit_once = OFOnceControlInitValue;
static AsyncUnit *nillable async_unit_singleton;

static void create_async_unit_singleton(void)
{
    async_unit_singleton = [[AsyncUnit alloc] _initPrivate];
}

@implementation AsyncUnit

+ (AsyncUnit *)unit
{
    OFOnce(&async_unit_once, create_async_unit_singleton);
    if (async_unit_singleton == nilptr)
        @throw [[OFInitializationFailedException alloc] initWithClass: self];

    return (AsyncUnit *)async_unit_singleton;
}

- (instancetype)_initPrivate
{
    self = [super init];
    return self;
}

- (OFString *)description
{
    return @"AsyncUnit";
}

@end

#pragma clang assume_nonnull end
