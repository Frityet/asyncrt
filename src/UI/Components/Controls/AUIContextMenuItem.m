#import "UI/Components/Controls/AUIContextMenuItem.h"

#pragma clang assume_nonnull begin

@interface AUIContextMenuItem ()

- (instancetype)initWithTitle: (OFString *nillable)title
                      enabled: (bool)enabled
                     onSelect: (void (^nillable)(void))selectHandler designated_initaliser;

@end

@implementation AUIContextMenuItem {
    OFString *_title;
    bool _enabled;
    void (^nillable _selectHandler)(void);
}

@synthesize title = _title;
@synthesize enabled = _enabled;
@synthesize selectHandler = _selectHandler;

+ (instancetype)title: (OFString *nillable)title
              enabled: (bool)enabled
             onSelect: (void (^nillable)(void))selectHandler
{
    return [[self alloc] initWithTitle: title enabled: enabled onSelect: selectHandler];
}

- (instancetype)initWithTitle: (OFString *nillable)title
                      enabled: (bool)enabled
                     onSelect: (void (^nillable)(void))selectHandler
{
    if (title == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _title = [$assert_nonnil(title) copy];
    _enabled = enabled;
    _selectHandler = [selectHandler copy];
    return self;
}

@end

#pragma clang assume_nonnull end
