#pragma once

#import "AsyncRuntime.h"

#pragma clang assume_nonnull begin

@namespace(ObjDBModule)

@property(class, readonly, nonatomic) OFString *targetName;
@property(class, readonly, nonatomic) OFString *moduleName;
@property(class, readonly, nonatomic) OFString *toolName;

+ (OFString *)targetName;
+ (OFString *)moduleName;
+ (OFString *)toolName;

@end

#pragma clang assume_nonnull end
