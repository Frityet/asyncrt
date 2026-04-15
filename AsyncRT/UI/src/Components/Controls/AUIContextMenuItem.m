#import "Components/Controls/AUIContextMenuItem.h"

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AUIContextMenuItem {
    OFString *_title;
    bool _isEnabled;
    void (^nillable _selectHandler)(void);
}

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
    _isEnabled = enabled;
    _selectHandler = [selectHandler copy];
    return self;
}

@end

#pragma clang assume_nonnull end
