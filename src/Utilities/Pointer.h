#pragma once

#import <ObjFW/OFData.h>

#pragma clang assume_nonnull begin

[[clang::objc_subclassing_restricted, clang::objc_direct_members]]
@interface Pointer : OFData

@property (readonly, nonatomic) const void *nillable pointer;
+ (instancetype)from: (const void *nillable)pointer;

@end

#pragma clang assume_nonnull end
