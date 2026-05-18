#pragma once

#import <AsyncRT/Common/common.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface TerminalLoadingView : OFObject

- (void)updateWithIndex: (size_t)index
                  total: (size_t)total
                 status: (OFString *)status
                 detail: (OFString *)detail;
- (void)finishWithMessage: (OFString *)message;
- (void)clear;

@end

#pragma clang assume_nonnull end
