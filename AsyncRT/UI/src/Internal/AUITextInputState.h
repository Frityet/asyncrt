#pragma once

#include "common.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AUITextInputState : OFObject

@property(nonatomic) size_t caretIndex;
@property(nonatomic) size_t selectionAnchorIndex;
@property(nonatomic) size_t selectionFocusIndex;

+ (instancetype)caretIndex: (size_t)caretIndex
      selectionAnchorIndex: (size_t)selectionAnchorIndex
       selectionFocusIndex: (size_t)selectionFocusIndex;
- (instancetype)initWithCaretIndex: (size_t)caretIndex;
- (instancetype)initWithCaretIndex: (size_t)caretIndex
              selectionAnchorIndex: (size_t)selectionAnchorIndex
               selectionFocusIndex: (size_t)selectionFocusIndex [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
