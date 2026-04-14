#import "AsyncRuntimeInternal.h"

#pragma clang assume_nonnull begin

static OFOnceControl async_unit_once = OFOnceControlInitValue;
static AsyncUnit *nillable async_unit_singleton;

[[direct_members]]
@interface AsyncUnit ()

+ (void)_createSingleton;

@end

static void create_async_unit_singleton(void)
{
    [AsyncUnit _createSingleton];
}

@implementation AsyncUnit

+ (void)_createSingleton
{
    async_unit_singleton = [[AsyncUnit alloc] _initPrivate];
}

+ (AsyncUnit *)unit
{
    OFOnce(&async_unit_once, create_async_unit_singleton);
    return $as_nonnil((AsyncUnit *)async_unit_singleton);
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
