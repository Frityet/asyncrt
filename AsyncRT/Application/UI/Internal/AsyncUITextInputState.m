#import <AsyncRT/Application/UI/Internal/AsyncUITextInputState.h>

#pragma clang assume_nonnull begin

[[direct_members]]
@implementation AsyncUITextInputState

+ (instancetype)caretIndex: (size_t)caretIndex
      selectionAnchorIndex: (size_t)selectionAnchorIndex
       selectionFocusIndex: (size_t)selectionFocusIndex
{
    return [[self alloc] initWithCaretIndex: caretIndex
                       selectionAnchorIndex: selectionAnchorIndex
                        selectionFocusIndex: selectionFocusIndex];
}

- (instancetype)initWithCaretIndex: (size_t)caretIndex
{
    return [self initWithCaretIndex: caretIndex
               selectionAnchorIndex: caretIndex
                selectionFocusIndex: caretIndex];
}

- (instancetype)initWithCaretIndex: (size_t)caretIndex
              selectionAnchorIndex: (size_t)selectionAnchorIndex
               selectionFocusIndex: (size_t)selectionFocusIndex
{
    self = [super init];
    _caretIndex = caretIndex;
    _selectionAnchorIndex = selectionAnchorIndex;
    _selectionFocusIndex = selectionFocusIndex;
    return self;
}

@end

#pragma clang assume_nonnull end
