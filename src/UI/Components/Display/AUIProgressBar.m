#import "UI/Components/Display/AUIProgressBar.h"

#pragma clang assume_nonnull begin

static float AUIClampFloat(float value, float minimum, float maximum)
{
    if (value < minimum)
        return minimum;
    if (value > maximum)
        return maximum;
    return value;
}

@interface AUIProgressBar ()

- (instancetype)initWithProgress: (float)progress
                         variant: (AUIControlVariant)variant designated_initaliser;

@end

@implementation AUIProgressBar {
    float _progress;
    AUIControlVariant _variant;
}

@synthesize progress = _progress;
@synthesize variant = _variant;

+ (instancetype)progress: (float)progress
{
    return [[self alloc] initWithProgress: progress variant: AUIControlVariantPrimary];
}

+ (instancetype)progress: (float)progress variant: (AUIControlVariant)variant
{
    return [[self alloc] initWithProgress: progress variant: variant];
}

- (instancetype)initWithProgress: (float)progress
                         variant: (AUIControlVariant)variant
{
    self = [super init];
    _progress = AUIClampFloat(progress, 0.0f, 1.0f);
    _variant = variant;
    return self;
}

- (id<AUIRenderable>)renderableBody
{
    AUIBoxProps trackProps = [AUIComponents progressTrackProps];
    float clamped = AUIClampFloat(_progress, 0.0f, 1.0f);

    trackProps.layout.height = [AUI axisFixed: 10];
    trackProps.layout.width = [AUI axisGrow: 0];

    return [AUIBox layout: trackProps.layout
               background: trackProps.backgroundColor
                   radius: trackProps.cornerRadius
                   border: trackProps.border
                 children: @[
        [AUIBox layout: (AUILayout){
                            .width = [AUI axisPercent: clamped],
                            .height = [AUI axisGrow: 0],
                            .padding = [AUI insetsAll: 0],
                            .childGap = 0,
                            .childAlignment = [AUI childAlignmentX: AUIAlignmentStart y: AUIAlignmentStart],
                            .direction = AUILayoutDirectionColumn
                        }
             background: [AUIComponents progressFillColorForVariant: _variant]
                 radius: 999
                 border: [AUI borderNone]
               children: @[]]
    ]];
}

@end

#pragma clang assume_nonnull end
