#import "AUIKeyedContent.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIKeyedContent

+ (instancetype)withKey: (OFString *)key content: (id<AUIContent>)content
{
    return [[self alloc] initWithKey: key content: content];
}

- (instancetype)initWithKey: (OFString *)key
                    content: (id<AUIContent>)content
{
    if (key.length == 0)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _key = [key copy];
    _content = content;
    return self;
}

- (AUIContentKind)contentKind
{
    return AUIContentKindKeyed;
}

@end

#pragma clang assume_nonnull end
