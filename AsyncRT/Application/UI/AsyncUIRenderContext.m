#import <AsyncRT/Application/UI/Internal/AsyncUIRenderContext+Private.h>

#pragma clang assume_nonnull begin

@namespace(AsyncUIRenderContextSupport)

+ (OFString *)contextStackKey;
+ (OFMutableArray<AsyncUIRenderContext *> *)contextStack;

@end

@namespace_implementation(AsyncUIRenderContextSupport)

+ (OFString *)contextStackKey
{
    return @"AsyncUIRenderContext.stack";
}

+ (OFMutableArray<AsyncUIRenderContext *> *)contextStack
{
    OFMutableDictionary<OFString *, OFMutableArray<AsyncUIRenderContext *> *> *threadDictionary = OFThread.threadDictionary;
    OFMutableArray<AsyncUIRenderContext *> *stack;

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
@implementation AsyncUIRenderContext


+ (AsyncUIRenderContext *nillable)currentContext
{
    OFMutableDictionary<OFString *, OFMutableArray<AsyncUIRenderContext *> *> *threadDictionary = OFThread.threadDictionary;
    OFMutableArray<AsyncUIRenderContext *> *nillable stack = nilptr;

    if (threadDictionary == nilptr)
        return nilptr;

    stack = threadDictionary[[AsyncUIRenderContextSupport contextStackKey]];
    if (stack == nilptr or stack.count == 0)
        return nilptr;

    return [stack objectAtIndex: stack.count - 1];
}

- (instancetype)initWithApplication: (AsyncUIApplication *nonnil)application
                             window: (AsyncUIWindow *nonnil)window
                       viewportSize: (AsyncUISize)viewportSize
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

+ (void)_pushCurrentContext: (AsyncUIRenderContext *nonnil)context
{
    [[AsyncUIRenderContextSupport contextStack] addObject: context];
}

+ (void)_popCurrentContext
{
    auto stack = [AsyncUIRenderContextSupport contextStack];

    if (stack.count == 0)
        @throw [OFOutOfRangeException exception];

    [stack removeObjectAtIndex: stack.count - 1];
}

@end

#pragma clang assume_nonnull end
