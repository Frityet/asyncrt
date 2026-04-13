#import "UI/Backend/AUIRendererBackend.h"
#import "UI/AUIApplication.h"

#pragma clang assume_nonnull begin

@implementation AUIRendererBackend {
    AUIApplication *_application;
}

@synthesize application = _application;

- (instancetype)initWithApplication: (AUIApplication *nillable)application
{
    if (application == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _application = $assert_nonnil(application);
    return self;
}

@end

#pragma clang assume_nonnull end
