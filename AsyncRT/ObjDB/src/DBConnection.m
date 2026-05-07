#import "DBConnection.h"

#pragma clang assume_nonnull begin

@implementation DBConnectionOptions

+ (instancetype)options
{
    return [[self alloc] init];
}

@end

@implementation DBWriteResult

+ (instancetype)resultWithAffectedRowCount: (uint64_t)affectedRowCount
{
    return [[self alloc] initWithAffectedRowCount: affectedRowCount];
}

- (instancetype)initWithAffectedRowCount: (uint64_t)affectedRowCount
{
    self = [super init];
    _affectedRowCount = affectedRowCount;
    return self;
}

- (bool)affectedRows
{
    return _affectedRowCount > 0;
}

@end

#pragma clang assume_nonnull end
