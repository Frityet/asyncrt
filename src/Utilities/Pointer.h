#pragma once

#import <ObjFW/OFData.h>

#pragma clang assume_nonnull begin

@interface Pointer : OFData

@property (readonly, nonatomic) const void *nillable pointer;
+ (instancetype)pointer: (const void *nillable)pointer;

@end

#pragma clang assume_nonnull end
