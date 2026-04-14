#import "UI/Backend/AUIWindowOptions.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@interface AUIWindowOptions ()

- (instancetype)initWithTitle: (OFString *nillable)title
                         size: (AUISize)initialSize
                    resizable: (bool)resizable
  autoResizeToRootComponent: (bool)automaticallyResizesToRootComponent [[designated_initailiser]];

@end

[[direct_members]]
@implementation AUIWindowOptions {
    OFString *_title;
    AUISize _initialSize;
    bool _resizable;
    bool _automaticallyResizesToRootComponent;
}

@synthesize isResizable = _resizable;
@synthesize automaticallyResizesToRootComponent = _automaticallyResizesToRootComponent;

+ (instancetype)title: (OFString *nillable)title
                 size: (AUISize)initialSize
            resizable: (bool)resizable
{
    return [[self alloc] initWithTitle: title
                                  size: initialSize
                             resizable: resizable
               autoResizeToRootComponent: false];
}

+ (instancetype)title: (OFString *nillable)title
                 size: (AUISize)initialSize
            resizable: (bool)resizable
          autoResizeToRootComponent: (bool)automaticallyResizesToRootComponent
{
    return [[self alloc] initWithTitle: title
                                  size: initialSize
                             resizable: resizable
               autoResizeToRootComponent: automaticallyResizesToRootComponent];
}

+ (instancetype)defaultOptions
{
    return [self        title: @"AsyncRT UI"
                         size: (AUISize){ 960, 640 }
                    resizable: true
    autoResizeToRootComponent: true];
}

- (instancetype)initWithTitle: (OFString *nillable)title
                         size: (AUISize)initialSize
                    resizable: (bool)resizable
  autoResizeToRootComponent: (bool)automaticallyResizesToRootComponent
{
    if (title == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _title = [$assert_nonnil(title) copy];
    _initialSize = initialSize;
    _resizable = resizable;
    _automaticallyResizesToRootComponent = automaticallyResizesToRootComponent;
    return self;
}

@end

#pragma clang assume_nonnull end
