#pragma once

#include "common.h"

#pragma clang assume_nonnull begin

typedef enum [[clang::enum_extensibility(closed)]] AUIAxisSizeMode {
    AUIAxisSizeModeGrow,
    AUIAxisSizeModeFit,
    AUIAxisSizeModeFixed,
    AUIAxisSizeModePercent
} AUIAxisSizeMode;

[[subclassing_restricted, direct_members]]
@interface AUIAxisSize : OFObject

@property(nonatomic) AUIAxisSizeMode mode;
@property(nonatomic) float value;
@property(class, readonly, nonatomic) AUIAxisSize *grow;
@property(class, readonly, nonatomic) AUIAxisSize *fit;

+ (instancetype)grow;
+ (instancetype)growWithMinimum: (float)minimumSize;
+ (instancetype)fit;
+ (instancetype)fitWithMinimum: (float)minimumSize;
+ (instancetype)fixed: (float)size;
+ (instancetype)percent: (float)percent;

@end

#pragma clang assume_nonnull end
