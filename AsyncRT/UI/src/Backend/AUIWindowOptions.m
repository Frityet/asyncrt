#include <math.h>

#import "Backend/AUIWindowOptions.h"

#pragma clang assume_nonnull begin


[[direct_members]]
@implementation AUIWindowOptions {
    OFString *_title;
    AUISize _initialSize;
    bool _resizable;
    bool _automaticallyResizesToRootComponent;
    bool _scalesWithWindowSize;
    double _contentScale;
}

+ (instancetype)title: (OFString *)title
                 size: (AUISize)initialSize
            resizable: (bool)resizable
          autoResizeToRootComponent: (bool)autoResiz
               scaleWithWindowSize: (bool)scaleWithWindowSize
                      contentScale: (double)contentScale
{
    return [[self alloc] initWithTitle: title
                                  size: initialSize
                             resizable: resizable
               autoResizeToRootComponent: autoResiz
                    scaleWithWindowSize: scaleWithWindowSize
                           contentScale: contentScale];
}

+ (instancetype)defaultOptions
{
    return [self        title: @"AsyncRT UI"
                         size: (AUISize){ 960, 640 }
                    resizable: true
    autoResizeToRootComponent: true
          scaleWithWindowSize: false
                 contentScale: 1.0];
}

- (instancetype)initWithTitle: (OFString *)title
                         size: (AUISize)initialSize
                    resizable: (bool)resizable
    autoResizeToRootComponent: (bool)autoResiz
          scaleWithWindowSize: (bool)scaleWithWindowSize
                 contentScale: (double)contentScale
{
    if (not isfinite(contentScale) or contentScale <= 0.0)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _title = [title copy];
    _initialSize = initialSize;
    _resizable = resizable;
    _automaticallyResizesToRootComponent = autoResiz;
    _scalesWithWindowSize = scaleWithWindowSize;
    _contentScale = contentScale;
    return self;
}

@end

#pragma clang assume_nonnull end
