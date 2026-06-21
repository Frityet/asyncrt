#import "DashboardComponents.h"

#import <math.h>

#pragma clang assume_nonnull begin

static constexpr size_t DashboardHistoryLimit = 42;

[[subclassing_restricted]]
@interface DashboardHeroComponent : AsyncWebUIComponent

@property(nonatomic) OFString *cpuText;
@property(nonatomic) OFString *memoryText;
@property(nonatomic) OFString *statusText;
@property(nonatomic) double cpuLoad;

- (void)applySample: (DashboardSample *)sample stressEnabled: (bool)stressEnabled;

@end

@implementation DashboardHeroComponent

- (instancetype)init
{
    self = [super init];
    _cpuText = @"0%";
    _memoryText = @"0 MB";
    _statusText = @"monitoring";
    _cpuLoad = 0.0;
    return self;
}

+ (OFString *)layout
{
    return @$raw(
        <section class="hero">
            <div>
                <span class="eyebrow">process load</span>
                <strong>{{cpuText}}</strong>
                <span class="caption">{{statusText}}</span>
            </div>
            <div class="ring" style="--value: {{cpuLoad}}">
                <span>{{cpuText}}</span>
            </div>
            <div>
                <span class="eyebrow">resident memory</span>
                <strong>{{memoryText}}</strong>
                <span class="caption">sampled with getrusage</span>
            </div>
        </section>
    );
}

+ (OFString *)styling
{
    return @$raw(
        :host { display: block; }
        .hero {
            min-height: 210px;
            display: grid;
            grid-template-columns: minmax(0, 1fr) 180px minmax(0, 1fr);
            gap: 24px;
            align-items: center;
            padding: 28px;
            background: #111816;
            color: #f6fbf8;
            border-bottom: 1px solid rgba(255,255,255,.08);
        }
        .eyebrow, .caption {
            display: block;
            color: rgba(246,251,248,.62);
            font: 600 12px/1.2 ui-monospace, SFMono-Regular, Menlo, monospace;
            text-transform: uppercase;
        }
        strong {
            display: block;
            margin: 8px 0;
            font: 700 42px/1.05 system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }
        .ring {
            width: 180px;
            height: 180px;
            border-radius: 50%;
            display: grid;
            place-items: center;
            background:
                conic-gradient(#33d399 calc(var(--value) * 1turn), rgba(255,255,255,.08) 0),
                rgb(23 34 31);
            box-shadow: inset 0 0 0 16px #17221f;
        }
        .ring span {
            width: 116px;
            height: 116px;
            border-radius: 50%;
            display: grid;
            place-items: center;
            background: #111816;
            font: 700 30px/1 system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }
        @media (max-width: 760px) {
            .hero { grid-template-columns: 1fr; }
            .ring { width: 150px; height: 150px; }
        }
    );
}

- (void)applySample: (DashboardSample *)sample stressEnabled: (bool)stressEnabled
{
    self.cpuText = [OFString stringWithFormat: @"%.0f%%", sample.cpuPercent];
    self.memoryText = [OFString stringWithFormat: @"%.1f MB", sample.memoryMB];
    self.statusText = (stressEnabled ? @"stress worker active" : @"steady async monitor");
    self.cpuLoad = fmax(0.0, fmin(1.0, sample.cpuPercent / 100.0));
}

@end

[[subclassing_restricted]]
@interface DashboardSchedulerComponent : AsyncWebUIComponent

@property(nonatomic) OFString *queuedText;
@property(nonatomic) OFString *runningText;
@property(nonatomic) OFString *completedText;
@property(nonatomic) OFString *cancelledText;
@property(nonatomic) OFString *clockText;

- (void)applySample: (DashboardSample *)sample;

@end

@implementation DashboardSchedulerComponent

- (instancetype)init
{
    self = [super init];
    _queuedText = @"0";
    _runningText = @"0";
    _completedText = @"0";
    _cancelledText = @"0";
    _clockText = @"0.0 ms";
    return self;
}

+ (OFString *)layout
{
    return @$raw(
        <section class="scheduler">
            <article><span>queued</span><strong>{{queuedText}}</strong></article>
            <article><span>running</span><strong>{{runningText}}</strong></article>
            <article><span>completed</span><strong>{{completedText}}</strong></article>
            <article><span>cancelled</span><strong>{{cancelledText}}</strong></article>
            <article><span>browser clock</span><strong>{{clockText}}</strong></article>
        </section>
    );
}

+ (OFString *)styling
{
    return @$raw(
        :host { display: block; }
        .scheduler {
            display: grid;
            grid-template-columns: repeat(5, minmax(0, 1fr));
            gap: 1px;
            background: #dfe8e2;
            border-top: 1px solid #dfe8e2;
            border-bottom: 1px solid #dfe8e2;
        }
        article {
            min-width: 0;
            padding: 18px;
            background: #fbfdfb;
        }
        span {
            display: block;
            color: #60716a;
            font: 650 12px/1.2 ui-monospace, SFMono-Regular, Menlo, monospace;
            text-transform: uppercase;
        }
        strong {
            display: block;
            margin-top: 9px;
            color: #13211c;
            font: 720 24px/1.1 system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }
        @media (max-width: 900px) {
            .scheduler { grid-template-columns: repeat(2, minmax(0, 1fr)); }
        }
    );
}

- (void)applySample: (DashboardSample *)sample
{
    self.queuedText = [OFString stringWithFormat: @"%llu", (unsigned long long)sample.queuedTasks];
    self.runningText = [OFString stringWithFormat: @"%llu", (unsigned long long)sample.runningTasks];
    self.completedText = [OFString stringWithFormat: @"%llu", (unsigned long long)sample.completedTasks];
    self.cancelledText = [OFString stringWithFormat: @"%llu", (unsigned long long)sample.cancelledTasks];
    self.clockText = [OFString stringWithFormat: @"%.1f ms", sample.jsClockMS];
}

@end

[[subclassing_restricted]]
@interface DashboardChartComponent : AsyncWebUIComponent

@property(nonatomic) OFString *points;
@property(nonatomic) OFString *sampleText;
@property(nonatomic) OFString *intervalText;

- (void)applySample: (DashboardSample *)sample
           interval: (OFTimeInterval)interval
            history: (OFArray<OFNumber *> *)history;

@end

@implementation DashboardChartComponent

- (instancetype)init
{
    self = [super init];
    _points = @"0,120";
    _sampleText = @"sample 0";
    _intervalText = @"250 ms";
    return self;
}

+ (OFString *)layout
{
    return @$raw(
        <section class="chart">
            <header>
                <div>
                    <span>cpu history</span>
                    <strong>{{sampleText}}</strong>
                </div>
                <em>{{intervalText}}</em>
            </header>
            <svg viewBox="0 0 420 140" preserveAspectRatio="none" aria-hidden="true">
                <polyline points="{{points}}"></polyline>
            </svg>
        </section>
    );
}

+ (OFString *)styling
{
    return @$raw(
        :host { display: block; }
        .chart {
            padding: 22px;
            background: #fbfdfb;
            min-height: 250px;
        }
        header {
            display: flex;
            align-items: end;
            justify-content: space-between;
            gap: 16px;
            margin-bottom: 16px;
        }
        span, em {
            color: #60716a;
            font: 650 12px/1.2 ui-monospace, SFMono-Regular, Menlo, monospace;
            text-transform: uppercase;
            font-style: normal;
        }
        strong {
            display: block;
            margin-top: 6px;
            color: #13211c;
            font: 720 26px/1.1 system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }
        svg {
            width: 100%;
            height: 160px;
            border-left: 1px solid #dfe8e2;
            border-bottom: 1px solid #dfe8e2;
            background:
                linear-gradient(#eef5f0 1px, transparent 1px) 0 0 / 100% 35px,
                linear-gradient(90deg, #eef5f0 1px, transparent 1px) 0 0 / 42px 100%;
        }
        polyline {
            fill: none;
            stroke: #208b66;
            stroke-width: 4;
            stroke-linecap: round;
            stroke-linejoin: round;
        }
    );
}

- (void)applySample: (DashboardSample *)sample
           interval: (OFTimeInterval)interval
            history: (OFArray<OFNumber *> *)history
{
    auto points = [OFMutableString string];
    size_t count = history.count;

    if (count == 0) {
        [points appendString: @"0,120"];
    } else {
        for (size_t index = 0; index < count; index++) {
            double x = (count == 1 ? 0.0 : ((double)index / (double)(count - 1)) * 420.0);
            double y = 132.0 - fmax(0.0, fmin(100.0, [[history objectAtIndex: index] doubleValue])) * 1.2;

            if (index > 0)
                [points appendString: @" "];
            [points appendFormat: @"%.1f,%.1f", x, y];
        }
    }

    [points makeImmutable];
    self.points = points;
    self.sampleText = [OFString stringWithFormat: @"sample %llu", (unsigned long long)sample.sampleIndex];
    self.intervalText = [OFString stringWithFormat: @"%.0f ms refresh", interval * 1000.0];
}

@end

[[subclassing_restricted]]
@interface DashboardActivityComponent : AsyncWebUIComponent

@property(nonatomic) OFString *eventsText;

- (void)appendEvent: (OFString *)event;
- (void)clearEvents;

@end

@implementation DashboardActivityComponent {
    OFMutableArray<OFString *> *_events;
}

- (instancetype)init
{
    self = [super init];
    _events = [OFMutableArray array];
    _eventsText = @"waiting for samples...";
    return self;
}

+ (OFString *)layout
{
    return @$raw(
        <section class="activity">
            <header><span>activity</span></header>
            <pre>{{eventsText}}</pre>
        </section>
    );
}

+ (OFString *)styling
{
    return @$raw(
        :host { display: block; height: 100%; }
        .activity {
            height: 100%;
            min-height: 250px;
            padding: 22px;
            background: #13211c;
            color: #e8f4ee;
        }
        span {
            color: #7bd8b8;
            font: 650 12px/1.2 ui-monospace, SFMono-Regular, Menlo, monospace;
            text-transform: uppercase;
        }
        pre {
            margin: 16px 0 0;
            white-space: pre-wrap;
            color: rgba(232,244,238,.84);
            font: 500 13px/1.55 ui-monospace, SFMono-Regular, Menlo, monospace;
        }
    );
}

- (void)_syncEventsText
{
    self.eventsText = [_events componentsJoinedByString: @"\n"];
    if (self.eventsText.length == 0)
        self.eventsText = @"no events";
}

- (void)appendEvent: (OFString *)event
{
    [_events insertObject: event atIndex: 0];
    while (_events.count > 9)
        [_events removeLastObject];
    [self _syncEventsText];
}

- (void)clearEvents
{
    [_events removeAllObjects];
    [self _syncEventsText];
}

@end

@implementation DashboardRootComponent {
    DashboardHeroComponent *_hero;
    DashboardSchedulerComponent *_scheduler;
    DashboardChartComponent *_chart;
    DashboardActivityComponent *_activity;
    OFMutableArray<OFNumber *> *_cpuHistory;
    OFTimeInterval _refreshInterval;
    bool _stressEnabled;
    AsyncTask<id> *nillable _stressTask;
}

- (instancetype)init
{
    self = [super init];
    _hero = [[DashboardHeroComponent alloc] init];
    _scheduler = [[DashboardSchedulerComponent alloc] init];
    _chart = [[DashboardChartComponent alloc] init];
    _activity = [[DashboardActivityComponent alloc] init];
    _cpuHistory = [OFMutableArray array];
    _refreshInterval = 0.25;
    _stressEnabled = false;
    _stressLabel = @"Start stress";
    _refreshLabel = @"250 ms";
    _sampleLabel = @"sample 0";
    [_activity appendEvent: @"dashboard mounted"];
    return self;
}

+ (OFString *)layout
{
    return @$raw(
        <main class="dashboard">
            <slot name="hero"></slot>
            <div class="controls">
                <button onclick="[self onToggleStressClick:]">{{stressLabel}}</button>
                <button onclick="[self onFasterClick:]">Faster</button>
                <button onclick="[self onSlowerClick:]">Slower</button>
                <button onclick="[self onMarkClick:]">Mark</button>
                <button onclick="[self onClearLogClick:]">Clear log</button>
                <span>{{refreshLabel}}</span>
                <span class="native-clock">browser pending</span>
            </div>
            <slot name="scheduler"></slot>
            <section class="lower">
                <slot name="chart"></slot>
                <slot name="activity"></slot>
            </section>
        </main>
    );
}

+ (OFString *)styling
{
    return @$raw(
        :host { display: block; min-height: 100vh; color: #13211c; }
        .dashboard {
            min-height: 100vh;
            background: #eef5f0;
        }
        .controls {
            display: flex;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
            padding: 14px 18px;
            background: #fbfdfb;
            border-bottom: 1px solid #dfe8e2;
        }
        button {
            appearance: none;
            border: 1px solid #b9cac1;
            background: #ffffff;
            color: #13211c;
            border-radius: 6px;
            padding: 9px 12px;
            font: 650 13px/1 system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            cursor: pointer;
        }
        button:hover { background: #edf6f1; border-color: #7fb49f; }
        span {
            color: #60716a;
            font: 650 12px/1.2 ui-monospace, SFMono-Regular, Menlo, monospace;
            text-transform: uppercase;
        }
        .native-clock { margin-left: auto; }
        .lower {
            display: grid;
            grid-template-columns: minmax(0, 1.4fr) minmax(320px, .6fr);
            gap: 1px;
            background: #dfe8e2;
            border-bottom: 1px solid #dfe8e2;
        }
        @media (max-width: 900px) {
            .lower { grid-template-columns: 1fr; }
            .native-clock { margin-left: 0; width: 100%; }
        }
    );
}

- (OFTimeInterval)refreshInterval
{ return _refreshInterval; }

- (bool)isStressEnabled
{ return _stressEnabled; }

- (void)applySample: (DashboardSample *)sample
{
    [_cpuHistory addObject: [OFNumber numberWithDouble: sample.cpuPercent]];
    while (_cpuHistory.count > DashboardHistoryLimit)
        [_cpuHistory removeObjectAtIndex: 0];

    [_hero applySample: sample stressEnabled: _stressEnabled];
    [_scheduler applySample: sample];
    [_chart applySample: sample interval: _refreshInterval history: _cpuHistory];
    self.sampleLabel = [OFString stringWithFormat: @"sample %llu", (unsigned long long)sample.sampleIndex];
    if ((sample.sampleIndex % 8) == 0)
        [_activity appendEvent: [OFString stringWithFormat: @"sample %llu cpu %.0f%% mem %.1fMB",
                                                          (unsigned long long)sample.sampleIndex,
                                                          sample.cpuPercent,
                                                          sample.memoryMB]];
}

- (void)_syncControls
{
    self.stressLabel = (_stressEnabled ? @"Stop stress" : @"Start stress");
    self.refreshLabel = [OFString stringWithFormat: @"%.0f ms", _refreshInterval * 1000.0];
}

- (void)_renderTreeSoon
{
    (void)[self taskToRenderTree];
}

- (void)_startStressTaskIfNeeded
{
    if (_stressTask != nilptr and not $assert_nonnil(_stressTask).isCompleted)
        return;

    unretained DashboardRootComponent *unsafeSelf = self;
    _stressTask = [AsyncRuntime spawnNamed: @"dashboard-stress-worker" block: ^id {
        while (unsafeSelf != nilptr and unsafeSelf->_stressEnabled) {
            (void)[[AsyncRuntime offload: ^id {
                volatile double sink = 0.0;
                for (uint64_t i = 0; i < 900000; i++)
                    sink += sqrt((double)(i % 8192) + 1.0);
                return [OFNumber numberWithDouble: sink];
            }] await];
            [[AsyncRuntime sleepForTimeInterval: 0.01] await];
        }
        return AsyncUnit.unit;
    }];
}

- (void)onToggleStressClick: (id)event
{
    (void)event;
    _stressEnabled = not _stressEnabled;
    [self _syncControls];
    [_activity appendEvent: (_stressEnabled ? @"stress worker started" : @"stress worker stopped")];
    if (_stressEnabled)
        [self _startStressTaskIfNeeded];
    else if (_stressTask != nilptr)
        [$assert_nonnil(_stressTask) cancel];
    [self _renderTreeSoon];
}

- (void)onFasterClick: (id)event
{
    (void)event;
    _refreshInterval = fmax(0.08, _refreshInterval * 0.75);
    [self _syncControls];
    [_activity appendEvent: @"refresh interval decreased"];
    [self _renderTreeSoon];
}

- (void)onSlowerClick: (id)event
{
    (void)event;
    _refreshInterval = fmin(1.5, _refreshInterval * 1.25);
    [self _syncControls];
    [_activity appendEvent: @"refresh interval increased"];
    [self _renderTreeSoon];
}

- (void)onMarkClick: (id)event
{
    (void)event;
    [_activity appendEvent: [OFString stringWithFormat: @"manual mark at %@", OFDate.date]];
    [self _renderTreeSoon];
}

- (void)onClearLogClick: (id)event
{
    (void)event;
    [_activity clearEvents];
    [_activity appendEvent: @"activity log cleared"];
    [self _renderTreeSoon];
}

@end

#pragma clang assume_nonnull end
