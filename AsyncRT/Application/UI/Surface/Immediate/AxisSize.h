#pragma once

#include <AsyncRT/Common/common.h>

#pragma clang assume_nonnull begin

typedef enum [[clang::enum_extensibility(closed)]] AsyncUIAxisSizeMode {
    AsyncUIAxisSizeModeGrow,
    AsyncUIAxisSizeModeFit,
    AsyncUIAxisSizeModeFixed,
    AsyncUIAxisSizeModePercent
} AsyncUIAxisSizeMode;

[[subclassing_restricted, direct_members]]
@interface AsyncUIAxisSize : OFObject

@property(nonatomic) AsyncUIAxisSizeMode mode;
@property(nonatomic) float value;
@property(class, readonly, nonatomic) AsyncUIAxisSize *grow;
@property(class, readonly, nonatomic) AsyncUIAxisSize *fit;

+ (instancetype)grow;
+ (instancetype)growWithMinimum: (float)minimumSize;
+ (instancetype)fit;
+ (instancetype)fitWithMinimum: (float)minimumSize;
+ (instancetype)fixed: (float)size;
+ (instancetype)percent: (float)percent;

@end

#pragma clang assume_nonnull end
