#pragma once

#include <AsyncRT/Common/common.h>
#import <ObjFW/OFData.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface Pointer : OFData

@property (readonly, nonatomic) const void *nillable pointer;
+ (instancetype)from: (const void *nillable)pointer;

@end

#pragma clang assume_nonnull end
