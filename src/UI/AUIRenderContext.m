#import "UI/AUIInternal.h"

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

@implementation AUIRenderContext

@synthesize application = _application;
@synthesize viewportSize = _viewportSize;
@synthesize frameDate = _frameDate;
@synthesize elapsedTime = _elapsedTime;

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

- (instancetype)initWithApplication: (AUIApplication *nillable)application
                       viewportSize: (AUISize)viewportSize
                          frameDate: (OFDate *nillable)frameDate
                        elapsedTime: (OFTimeInterval)elapsedTime
{
    if (application == nilptr or frameDate == nilptr)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _application = $assert_nonnil(application);
    _viewportSize = viewportSize;
    _frameDate = [$assert_nonnil(frameDate) copy];
    _elapsedTime = elapsedTime;
    return self;
}

+ (void)_pushCurrentContext: (AUIRenderContext *nillable)context
{
    if (context == nilptr)
        @throw [OFInvalidArgumentException exception];

    [[AUIRenderContextSupport contextStack] addObject: $assert_nonnil(context)];
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
