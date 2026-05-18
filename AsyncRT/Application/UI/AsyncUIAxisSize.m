#import <AsyncRT/Application/UI/AsyncUIAxisSize.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIAxisSize

+ (instancetype)grow
{
    return [self growWithMinimum: 0];
}

+ (instancetype)growWithMinimum: (float)minimumSize
{
    auto axisSize = [[self alloc] init];
    axisSize.mode = AsyncUIAxisSizeModeGrow;
    axisSize.value = minimumSize;
    return axisSize;
}

+ (instancetype)fit
{
    return [self fitWithMinimum: 0];
}

+ (instancetype)fitWithMinimum: (float)minimumSize
{
    auto axisSize = [[self alloc] init];
    axisSize.mode = AsyncUIAxisSizeModeFit;
    axisSize.value = minimumSize;
    return axisSize;
}

+ (instancetype)fixed: (float)size
{
    auto axisSize = [[self alloc] init];
    axisSize.mode = AsyncUIAxisSizeModeFixed;
    axisSize.value = size;
    return axisSize;
}

+ (instancetype)percent: (float)percent
{
    auto axisSize = [[self alloc] init];
    axisSize.mode = AsyncUIAxisSizeModePercent;
    axisSize.value = percent;
    return axisSize;
}

@end

#pragma clang assume_nonnull end
