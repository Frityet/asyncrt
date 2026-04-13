#import "UI/Components/Layout/AUISpacer.h"

#pragma clang assume_nonnull begin

@interface AUISpacer ()

- (instancetype)initWithWidth: (AUILayoutAxis)width height: (AUILayoutAxis)height designated_initaliser;

@end

@implementation AUISpacer {
    AUILayoutAxis _width;
    AUILayoutAxis _height;
}

@synthesize width = _width;
@synthesize height = _height;

+ (instancetype)width: (AUILayoutAxis)width height: (AUILayoutAxis)height
{
    return [[self alloc] initWithWidth: width height: height];
}

+ (instancetype)grow
{
    return [self width: [AUI axisGrow: 0] height: [AUI axisGrow: 0]];
}

- (instancetype)initWithWidth: (AUILayoutAxis)width height: (AUILayoutAxis)height
{
    self = [super init];
    _width = width;
    _height = height;
    return self;
}

- (id<AUIRenderable>)renderableBody
{
    return [AUIBox layout: (AUILayout){
                                .width = _width,
                                .height = _height,
                                .padding = [AUI insetsWithLeft: 0 right: 0 top: 0 bottom: 0],
                                .childGap = 0,
                                .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                                .direction = AUILayoutDirectionColumn
                            }
             background: [AUI colorWithRed: 0 green: 0 blue: 0 alpha: 0]
                 radius: 0
                 border: [AUI borderNone]
               children: @[]];
}

@end

#pragma clang assume_nonnull end
