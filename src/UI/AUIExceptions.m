#import "UI/AUIExceptions.h"

#pragma clang assume_nonnull begin

@implementation AUIException


- (instancetype)initWithReason: (OFString *nillable)reason
{
    return [self initWithReason: reason underlyingException: nilptr];
}

- (instancetype)initWithReason: (OFString *nillable)reason
           underlyingException: (OFException *nillable)underlyingException
{
    if (reason == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _reason = [$as_nonnil(reason) copy];
    _underlyingException = underlyingException;
    return self;
}

- (OFString *)description
{
    if (self.underlyingException != nilptr)
        return [OFString stringWithFormat: @"%@: %@ (%@)",
                                           self.className,
                                           self.reason,
                                           self.underlyingException];

    return [OFString stringWithFormat: @"%@: %@", self.className, self.reason];
}

@end

@implementation AUIInitializationException @end
@implementation AUIRenderException @end

#pragma clang assume_nonnull end
