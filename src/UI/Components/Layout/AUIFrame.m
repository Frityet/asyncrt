#import "UI/Components/Layout/AUIFrame.h"

#pragma clang assume_nonnull begin

@interface AUIFrame ()

- (instancetype)initWithWidth: (AUILayoutAxis)width
                       height: (AUILayoutAxis)height
                    alignment: (AUIChildAlignment)alignment
                        child: (id<AUIRenderable>)child designated_initaliser;

@end

@implementation AUIFrame {
    AUILayoutAxis _width;
    AUILayoutAxis _height;
    AUIChildAlignment _alignment;
    id<AUIRenderable> _child;
}

@synthesize width = _width;
@synthesize height = _height;
@synthesize alignment = _alignment;
@synthesize child = _child;

+ (instancetype)width: (AUILayoutAxis)width height: (AUILayoutAxis)height child: (id<AUIRenderable>)child
{
    return [self width: width
                height: height
             alignment: [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart]
                 child: child];
}

+ (instancetype)width: (AUILayoutAxis)width
               height: (AUILayoutAxis)height
            alignment: (AUIChildAlignment)alignment
                child: (id<AUIRenderable>)child
{
    return [[self alloc] initWithWidth: width height: height alignment: alignment child: child];
}

- (instancetype)initWithWidth: (AUILayoutAxis)width
                       height: (AUILayoutAxis)height
                    alignment: (AUIChildAlignment)alignment
                        child: (id<AUIRenderable>)child
{
    self = [super init];
    _width = width;
    _height = height;
    _alignment = alignment;
    _child = child;
    return self;
}

- (id<AUIRenderable>)renderableBody
{
    AUILayout layout = [AUI layout];
    layout.width = _width;
    layout.height = _height;
    layout.childAlignment = _alignment;

    return [AUIBox layout: layout
               background: [AUI colorWithRed: 0 green: 0 blue: 0 alpha: 0]
                   radius: 0
                   border: [AUI borderNone]
                 children: @[ _child ]];
}

@end

#pragma clang assume_nonnull end
