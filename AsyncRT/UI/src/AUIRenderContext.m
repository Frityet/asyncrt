#import "AUIInternal.h"

#pragma clang assume_nonnull begin

@namespace(AUIRenderContextSupport)

+ (OFString *)contextStackKey;
+ (OFMutableArray<AUIRenderContext *> *)contextStack;

@end

@namespace_implementation(AUIRenderContextSupport)

+ (OFString *)contextStackKey
{
    return @"AUIRenderContext.stack";
}

+ (OFMutableArray<AUIRenderContext *> *)contextStack
{
    OFMutableDictionary<OFString *, OFMutableArray<AUIRenderContext *> *> *threadDictionary = OFThread.threadDictionary;
    OFMutableArray<AUIRenderContext *> *stack;

    if (threadDictionary == nilptr)
        @throw [OFInvalidArgumentException exception];

    stack = threadDictionary[self.contextStackKey];
    if (stack == nilptr) {
        stack = [OFMutableArray array];
        threadDictionary[self.contextStackKey] = stack;
    }

    return stack;
}

@end

[[direct_members]]
@implementation AUIRenderContext


+ (AUIRenderContext *nillable)currentContext
{
    OFMutableDictionary<OFString *, OFMutableArray<AUIRenderContext *> *> *threadDictionary = OFThread.threadDictionary;
    OFMutableArray<AUIRenderContext *> *nillable stack = nilptr;

    if (threadDictionary == nilptr)
        return nilptr;

    stack = threadDictionary[[AUIRenderContextSupport contextStackKey]];
    if (stack == nilptr or stack.count == 0)
        return nilptr;

    return [stack objectAtIndex: stack.count - 1];
}

- (instancetype)initWithApplication: (AUIApplication *nonnil)application
                             window: (AUIWindow *nonnil)window
                       viewportSize: (AUISize)viewportSize
                          frameDate: (OFDate *nonnil)frameDate
                        elapsedTime: (OFTimeInterval)elapsedTime
{
    self = [super init];
    _application = application;
    _window = window;
    _viewportSize = viewportSize;
    _frameDate = [frameDate copy];
    _elapsedTime = elapsedTime;
    return self;
}

+ (void)_pushCurrentContext: (AUIRenderContext *nonnil)context
{
    [[AUIRenderContextSupport contextStack] addObject: context];
}

+ (void)_popCurrentContext
{
    auto stack = [AUIRenderContextSupport contextStack];

    if (stack.count == 0)
        @throw [OFOutOfRangeException exception];

    [stack removeObjectAtIndex: stack.count - 1];
}

@end

#pragma clang assume_nonnull end
