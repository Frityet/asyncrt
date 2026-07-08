#import <ObjFW/ObjFW.h>

#pragma clang assume_nonnull begin

@interface ThreadPool : OFObject

@property(readonly) size_t threadCount;
@property(readonly) OFMutableArray<void (^)(void)> *tasks;

- (instancetype)initWithThreadCount: (size_t)threadCount;

- (void)runOnRunLoop: (OFRunLoop *)runLoop;

@end

#pragma clang assume_nonnull end
