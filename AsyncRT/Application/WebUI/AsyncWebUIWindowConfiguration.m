#import "AsyncWebUIView.h"

@implementation AsyncWebUIWindowConfiguration

+ (instancetype)configuration
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _title = @"AsyncRT WebUI";
        _width = 800;
        _height = 600;
        _resizable = true;
    }
    return self;
}

- (id)copy
{
    AsyncWebUIWindowConfiguration *copy = [[AsyncWebUIWindowConfiguration alloc] init];
    copy.title = self.title;
    copy.width = self.width;
    copy.height = self.height;
    copy.resizable = self.resizable;
    return copy;
}

@end
