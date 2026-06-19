#import <math.h>

#import <AsyncRT/Application/UI/Window/Configuration.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUIWindowConfiguration

- (instancetype)init
{
    self = [super init];
    _title = @"AsyncRT UI";
    _initialWidth = 960;
    _initialHeight = 640;
    _isResizable = true;
    _automaticallyResizesToContent = true;
    _scalesWithWindowSize = false;
    _contentScale = 1.0;
    return self;
}

+ (instancetype)defaults
{
    return [[self alloc] init];
}

+ (instancetype)withTitle: (OFString *)title
                    width: (float)width
                   height: (float)height
{
    auto configuration = [[self alloc] init];
    configuration.title = [title copy];
    configuration.initialWidth = width;
    configuration.initialHeight = height;
    return configuration;
}

+ (instancetype)withTitle: (OFString *)title
                     size: (AsyncUISize)initialSize
                resizable: (bool)isResizable
automaticallyResizesToContent: (bool)automaticallyResizesToContent
     scalesWithWindowSize: (bool)scalesWithWindowSize
             contentScale: (double)contentScale
{
    auto configuration = [[self alloc] init];
    configuration.title = [title copy];
    configuration.initialSize = initialSize;
    configuration.isResizable = isResizable;
    configuration.automaticallyResizesToContent = automaticallyResizesToContent;
    configuration.scalesWithWindowSize = scalesWithWindowSize;
    configuration.contentScale = contentScale;
    return configuration;
}

- (AsyncUISize)initialSize
{
    return (AsyncUISize){
        .width = _initialWidth,
        .height = _initialHeight
    };
}

- (void)setInitialSize: (AsyncUISize)initialSize
{
    _initialWidth = initialSize.width;
    _initialHeight = initialSize.height;
}

- (void)setContentScale: (double)contentScale
{
    if (not isfinite(contentScale) or contentScale <= 0.0)
        @throw [OFInvalidArgumentException exception];

    _contentScale = contentScale;
}

- (id)copy
{
    return [AsyncUIWindowConfiguration withTitle: self.title
                                           size: self.initialSize
                                      resizable: self.isResizable
                   automaticallyResizesToContent: self.automaticallyResizesToContent
                            scalesWithWindowSize: self.scalesWithWindowSize
                                    contentScale: self.contentScale];
}

@end

#pragma clang assume_nonnull end
