#import "UI/Backend/AUIWindowOptions.h"

#pragma clang assume_nonnull begin

@interface AUIWindowOptions ()

- (instancetype)initWithTitle: (OFString *nillable)title
                         size: (AUISize)initialSize
                    resizable: (bool)resizable [[designated_initailiser]];

@end

@implementation AUIWindowOptions {
    OFString *_title;
    AUISize _initialSize;
    bool _resizable;
}

@synthesize isResizable = _resizable;

+ (instancetype)title: (OFString *nillable)title
                 size: (AUISize)initialSize
            resizable: (bool)resizable
{
    return [[self alloc] initWithTitle: title size: initialSize resizable: resizable];
}

+ (instancetype)defaultOptions
{
    return [self title: @"asyncrt UI"
                  size: (AUISize){ 960, 640 }
             resizable: true];
}

- (instancetype)initWithTitle: (OFString *nillable)title
                         size: (AUISize)initialSize
                    resizable: (bool)resizable
{
    if (title == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _title = [$assert_nonnil(title) copy];
    _initialSize = initialSize;
    _resizable = resizable;
    return self;
}

@end

#pragma clang assume_nonnull end
