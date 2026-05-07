#import "AUIAxisSize.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIAxisSize

+ (instancetype)grow
{
    return [self growWithMinimum: 0];
}

+ (instancetype)growWithMinimum: (float)minimumSize
{
    auto axisSize = [[self alloc] init];
    axisSize.mode = AUIAxisSizeModeGrow;
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
    axisSize.mode = AUIAxisSizeModeFit;
    axisSize.value = minimumSize;
    return axisSize;
}

+ (instancetype)fixed: (float)size
{
    auto axisSize = [[self alloc] init];
    axisSize.mode = AUIAxisSizeModeFixed;
    axisSize.value = size;
    return axisSize;
}

+ (instancetype)percent: (float)percent
{
    auto axisSize = [[self alloc] init];
    axisSize.mode = AUIAxisSizeModePercent;
    axisSize.value = percent;
    return axisSize;
}

@end

#pragma clang assume_nonnull end
