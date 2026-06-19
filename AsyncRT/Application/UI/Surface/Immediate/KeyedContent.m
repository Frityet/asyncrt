#import <AsyncRT/Application/UI/Surface/Immediate/KeyedContent.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIKeyedContent

+ (instancetype)withKey: (OFString *)key content: (id<AsyncUIContent>)content
{
    return [[self alloc] initWithKey: key content: content];
}

- (instancetype)initWithKey: (OFString *)key
                    content: (id<AsyncUIContent>)content
{
    if (key.length == 0)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _key = [key copy];
    _content = content;
    return self;
}

- (AsyncUIContentKind)contentKind
{
    return AsyncUIContentKindKeyed;
}

@end

#pragma clang assume_nonnull end
