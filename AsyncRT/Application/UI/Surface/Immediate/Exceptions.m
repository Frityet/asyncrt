#import <AsyncRT/Application/UI/Surface/Immediate/Exceptions.h>

#pragma clang assume_nonnull begin

@implementation AsyncUIException


- (instancetype)initWithReason: (OFString *nonnil)reason
{
    return [self initWithReason: reason underlyingException: nilptr];
}

- (instancetype)initWithReason: (OFString *nonnil)reason
           underlyingException: (OFException *nillable)underlyingException
{
    self = [super init];
    _reason = [reason copy];
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

@implementation AsyncUIInitializationException @end
@implementation AsyncUIRenderException @end

#pragma clang assume_nonnull end
