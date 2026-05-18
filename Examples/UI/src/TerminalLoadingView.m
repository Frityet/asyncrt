#import "TerminalLoadingView.h"

#pragma clang assume_nonnull begin

@implementation TerminalLoadingView {
    bool _isVisible;
}

- (void)updateWithIndex: (size_t)index
                  total: (size_t)total
                 status: (OFString *)status
                 detail: (OFString *)detail
{
    [OFStdErr writeFormat: @"\r\033[2K[%zu/%zu] %@ %@", index, total, status, detail];
    _isVisible = true;
}

- (void)finishWithMessage: (OFString *)message
{
    [self clear];
    [OFStdErr writeFormat: @"%@\n", message];
}

- (void)clear
{
    if (not _isVisible)
        return;

    [OFStdErr writeString: @"\r\033[2K"];
    _isVisible = false;
}

@end

#pragma clang assume_nonnull end
