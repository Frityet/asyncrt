#import "DashboardApplication.h"

#import <math.h>

#pragma clang assume_nonnull begin

@implementation AsyncWebUIExampleApplication {
    DashboardRootComponent *nillable _dashboard;
}

- (AsyncUIWindowConfiguration *)windowConfiguration
{
    auto configuration = super.windowConfiguration;
    configuration.title = @"AsyncRT Resource Dashboard";
    configuration.initialSize = (AsyncUISize){ .width = 1180.0f, .height = 820.0f };
    configuration.isResizable = true;
    configuration.automaticallyResizesToContent = false;
    return configuration;
}

- (OFString *)documentStyle
{
    return @$raw(
        * { box-sizing: border-box; }
        html, body {
            margin: 0;
            min-height: 100%;
            background: #eef5f0;
        }
        body {
            min-height: 100vh;
            --cpu-load: 0;
        }
        body.stress-enabled {
            background:
                linear-gradient(135deg, rgba(32,139,102,.14), transparent 38%),
                rgb(238 245 240);
        }
    );
}

- (AsyncWebUIComponent *)createRootComponent
{
    _dashboard = [[DashboardRootComponent alloc] init];
    return $assert_nonnil(_dashboard);
}

- (void)applicationDidStartWithWebView: (AsyncWebUIView *)webView
{
    DashboardRootComponent *dashboard = $assert_nonnil(_dashboard);
    auto sampler = [[DashboardSampler alloc] init];

    [AsyncRuntime spawnNamed: @"dashboard-sampler" block: ^{
        while (not webView.isClosed) {
            double javaScriptClock = 0.0;

            id value = [[webView.document taskToEvaluateExpression: @"performance.now()"] await];
            if ([value isKindOfClass: OFNumber.class])
                javaScriptClock = ((OFNumber *)value).doubleValue;
            
            DashboardSample *sample = [sampler sampleWithJavaScriptClock: javaScriptClock];
            [dashboard applySample: sample];
            [[dashboard taskToRenderTree] await];

            auto cpuLoad = [OFString stringWithFormat: @"%.3f", fmax(0.0, fmin(1.0, sample.cpuPercent / 100.0))];
            auto clockText = [OFString stringWithFormat: @"browser %.1f ms", sample.jsClockMS];
            auto mutations = @[
                [AsyncWebUIDOMMutation setStyleProperty: @"--cpu-load" value: cpuLoad selector: @"body"],
                [AsyncWebUIDOMMutation toggleClass: @"stress-enabled" enabled: dashboard.isStressEnabled selector: @"body"],
                [AsyncWebUIDOMMutation setText: clockText selector: @".native-clock"],
            ];
            [[webView.document taskToApplyMutations: mutations] await];

            [[AsyncRuntime sleepForTimeInterval: dashboard.refreshInterval] await];
        }

        return AsyncUnit.unit;
    }];
}

@end

#pragma clang assume_nonnull end
