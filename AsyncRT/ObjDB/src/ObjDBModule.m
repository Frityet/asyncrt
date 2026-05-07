#import "ObjDBModule.h"

#pragma clang assume_nonnull begin

@namespace_implementation(ObjDBModule)

+ (OFString *)targetName
{
    return @"ObjDB";
}

+ (OFString *)moduleName
{
    return @"ObjDB";
}

+ (OFString *)toolName
{
    return @"odb";
}

@end

#pragma clang assume_nonnull end
