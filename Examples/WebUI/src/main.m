#import <AsyncRT/Application/UI/Surface/Web/Web.h>

#pragma clang assume_nonnull begin

@namespace(AsyncWebUIExampleJSON)

+ (OFString *)stateWithCounter: (unsigned long long)counter
                       message: (OFString *)message
                        source: (OFString *)source;
+ (OFString *)echoWithPayloadJSON: (OFString *nillable)payloadJSON
                          counter: (unsigned long long)counter;
+ (OFString *)clock;

@end

@namespace_implementation(AsyncWebUIExampleJSON)

+ (OFString *)stateWithCounter: (unsigned long long)counter
                       message: (OFString *)message
                        source: (OFString *)source
{
    return @{
        @"counter": @(counter),
        @"message": message,
        @"source": source,
        @"time": OFDate.date.description
    }.JSONRepresentation;
}

+ (OFString *)echoWithPayloadJSON: (OFString *nillable)payloadJSON
                          counter: (unsigned long long)counter
{
    // return [OFString stringWithFormat: @"{\"counter\":%llu,\"payload\":%@,\"time\":%@}",
    //                                   counter,
    //                                   payloadJSON ?: @"null",
    //                                   OFDate.date.description.JSONRepresentation];
    return @{
        @"counter": @(counter),
        @"payload": payloadJSON ?: OFNull.null,
        @"time": OFDate.date.description
    }.JSONRepresentation;
}

+ (OFString *)clock
{
    return @{ @"time": OFDate.date.description }.JSONRepresentation;
}

@end

[[subclassing_restricted]]
@interface AsyncWebUIExampleApplication : AsyncWebUIApplication
@end

@implementation AsyncWebUIExampleApplication {
    unsigned long long _counter;
}

- (instancetype)init
{
    self = [super init];
    _counter = 0;
    return self;
}

- (AsyncUIWindowConfiguration *nillable)windowConfiguration
{
    auto configuration = [super windowConfiguration];
    configuration.title = @"AsyncRT WebUI Example";
    configuration.initialSize = (AsyncUISize){ .width = 980.0f, .height = 720.0f };
    configuration.isResizable = true;
    configuration.automaticallyResizesToContent = false;
    return configuration;
}

- (void)applicationDidStartWithWebView: (AsyncWebUIView *)webView
                             taskGroup: (AsyncTaskGroup *)taskGroup
{
    (void)taskGroup;

    unretained AsyncWebUIExampleApplication *application = self;
    unretained AsyncWebUIView *view = webView;

    [webView bindAction: @"app.bootstrap" toJSONHandler: ^OFString *(AsyncWebUIRequest request) {
        (void)request;
        return [AsyncWebUIExampleJSON stateWithCounter: application->_counter
                                               message: @"Native bridge ready"
                                                source: @"bootstrap"];
    }];

    [webView bindAction: @"counter.increment" toJSONHandler: ^OFString *(AsyncWebUIRequest request) {
        (void)request;
        application->_counter++;
        OFString *state = [AsyncWebUIExampleJSON stateWithCounter: application->_counter
                                                          message: @"Counter incremented"
                                                           source: @"counter.increment"];
        [view emitEvent: @"counter.changed" withJSONPayload: state];
        return state;
    }];

    [webView bindAction: @"counter.reset" toJSONHandler: ^OFString *(AsyncWebUIRequest request) {
        (void)request;
        application->_counter = 0;
        OFString *state = [AsyncWebUIExampleJSON stateWithCounter: application->_counter
                                                          message: @"Counter reset"
                                                           source: @"counter.reset"];
        [view emitEvent: @"counter.changed" withJSONPayload: state];
        return state;
    }];

    [webView bindAction: @"message.echo" toJSONHandler: ^OFString *(AsyncWebUIRequest request) {
        return [AsyncWebUIExampleJSON echoWithPayloadJSON: request.payloadJSON
                                                  counter: application->_counter];
    }];

    [webView bindAction: @"clock.now" toJSONHandler: ^OFString *(AsyncWebUIRequest request) {
        (void)request;
        OFString *clock = AsyncWebUIExampleJSON.clock;
        [view emitEvent: @"clock.updated" withJSONPayload: clock];
        return clock;
    }];
}

- (OFString *nillable)initialHTML
{
    return [OFString stringWithUTF8String: $raw(
        <!doctype html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>AsyncRT WebUI Example</title>
            <style>
                :root{
                    color-scheme:light dark;
                    font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;
                    background:rgb(238,242,247);
                    color:rgb(21,25,31);
                }
                *{box-sizing:border-box}
                html,body{height:100%}
                body{
                    margin:0;
                    min-height:100vh;
                    overflow-x:hidden;
                    background:
                        radial-gradient(circle at 18% 12%,rgba(14,116,144,.18),transparent 31%),
                        radial-gradient(circle at 86% 18%,rgba(63,98,18,.12),transparent 27%),
                        linear-gradient(180deg,rgb(247,249,252),rgb(229,235,242));
                }
                main{
                    width:100%;
                    max-width:980px;
                    margin:0 auto;
                    padding:20px;
                    display:grid;
                    gap:14px;
                    grid-template-columns:minmax(0,1.05fr) minmax(260px,.95fr);
                }
                header{
                    grid-column:1/-1;
                    display:flex;
                    align-items:flex-end;
                    justify-content:space-between;
                    gap:16px;
                    padding:0 0 14px;
                    border-bottom:1px solid rgb(199,211,223);
                }
                h1{margin:0;font-size:26px;line-height:1.12;font-weight:760;letter-spacing:0;color:rgb(17,24,32)}
                h2{margin:0 0 12px;font-size:15px;font-weight:720;letter-spacing:0;color:rgb(35,49,66)}
                p{margin:0;color:rgb(83,97,112);line-height:1.45}
                button{
                    appearance:none;
                    border:1px solid rgb(75,98,122);
                    background:rgb(16,42,67);
                    color:white;
                    border-radius:7px;
                    padding:9px 13px;
                    font-weight:720;
                    font-size:14px;
                    cursor:pointer;
                }
                button:hover{background:rgb(24,61,93)}
                button.secondary{background:white;color:rgb(16,42,67);border-color:rgb(151,170,188)}
                button.secondary:hover{background:rgb(242,246,250)}
                button:disabled{opacity:.55;cursor:default}
                label{display:block;font-size:13px;font-weight:720;color:rgb(52,73,94);margin-bottom:8px}
                input{
                    width:100%;
                    border:1px solid rgb(185,198,211);
                    border-radius:7px;
                    padding:11px 12px;
                    font-size:15px;
                    background:white;
                    color:rgb(21,25,31);
                }
                dl{display:grid;grid-template-columns:100px 1fr;gap:8px 12px;margin:0}
                dt{font-size:12px;text-transform:uppercase;color:rgb(104,119,137);font-weight:800}
                dd{margin:0;color:rgb(31,45,61);overflow-wrap:anywhere}
                pre{
                    margin:0;
                    min-height:150px;
                    max-height:220px;
                    overflow:auto;
                    background:rgb(16,24,32);
                    color:rgb(215,231,247);
                    border-radius:7px;
                    padding:12px;
                    font-size:12px;
                    line-height:1.42;
                }
                .badge{
                    font-size:12px;
                    font-weight:760;
                    color:rgb(15,81,50);
                    background:rgb(209,231,221);
                    border:1px solid rgb(163,207,187);
                    padding:6px 10px;
                    border-radius:999px;
                    white-space:nowrap;
                }
                .panel{
                    min-width:0;
                    background:rgba(255,255,255,.92);
                    border:1px solid rgb(215,222,230);
                    border-radius:8px;
                    padding:16px;
                    box-shadow:0 10px 30px rgba(30,42,55,.08);
                    backdrop-filter:saturate(1.1) blur(8px);
                }
                .hero-panel{
                    background:
                        linear-gradient(135deg,rgba(16,42,67,.98),rgba(14,116,144,.88));
                    color:white;
                    border-color:rgba(255,255,255,.18);
                }
                .hero-panel h2,.hero-panel p{color:white}
                .hero-panel button.secondary{background:rgba(255,255,255,.95)}
                .metric{
                    font-size:58px;
                    line-height:.95;
                    font-weight:820;
                    letter-spacing:0;
                    color:rgb(255,255,255);
                    margin:12px 0;
                }
                .actions{display:flex;flex-wrap:wrap;gap:9px;margin-top:14px}
                .caption{font-size:13px;color:rgb(82,98,116)}
                .hero-panel .caption{color:rgba(255,255,255,.78)}
                @media(max-width:780px){
                    main{grid-template-columns:1fr;padding:16px}
                    header{align-items:flex-start;flex-direction:column}
                    .metric{font-size:48px}
                }
            </style>
        </head>
        <body>
            <main>
                <header>
                    <div>
                        <h1>AsyncRT WebUI Example</h1>
                        <p>Native Objective-C actions drive this WKWebKit interface.</p>
                    </div>
                    <div class="badge" id="bridge-status">Starting</div>
                </header>

                <section class="panel hero-panel">
                    <h2>Counter</h2>
                    <p id="native-message" class="caption">Waiting for native bootstrap.</p>
                    <div class="metric" id="counter">0</div>
                    <div class="actions">
                        <button id="increment">Increment</button>
                        <button class="secondary" id="reset">Reset</button>
                        <button class="secondary" id="clock">Native Time</button>
                    </div>
                </section>

                <section class="panel">
                    <h2>Native State</h2>
                    <dl>
                        <dt>Source</dt><dd id="source">-</dd>
                        <dt>Time</dt><dd id="time">-</dd>
                        <dt>Last event</dt><dd id="event">-</dd>
                    </dl>
                </section>

                <section class="panel">
                    <h2>Echo Payload</h2>
                    <label for="message">Message</label>
                    <input id="message" value="Hello from the web surface">
                    <div class="actions"><button id="echo">Send to Objective-C</button></div>
                </section>

                <section class="panel">
                    <h2>Bridge Log</h2>
                    <pre id="log"></pre>
                </section>
            </main>

            <script>
                const $ = id => document.getElementById(id);
                const setText = (id,value) => { $(id).textContent = value; };
                const log = (label,value) => {
                    $("log").textContent =
                        new Date().toLocaleTimeString() + " " + label + ": " +
                        JSON.stringify(value) + "\n" + $("log").textContent;
                };
                const setBusy = busy => document.querySelectorAll("button").forEach(button => {
                    button.disabled = busy;
                });
                const applyState = state => {
                    if (!state) return;
                    if (state.counter !== undefined) setText("counter", state.counter);
                    if (state.message !== undefined) setText("native-message", state.message);
                    if (state.source !== undefined) setText("source", state.source);
                    if (state.time !== undefined) setText("time", state.time);
                };
                async function callNative(action,payload) {
                    setBusy(true);
                    try {
                        const result = await window.AsyncRT.invoke(action,payload);
                        log(action,result);
                        return result;
                    } finally {
                        setBusy(false);
                    }
                }
                window.addEventListener("counter.changed", event => {
                    setText("event","counter.changed");
                    applyState(event.detail);
                });
                window.addEventListener("clock.updated", event => {
                    setText("event","clock.updated");
                    setText("time",event.detail.time);
                    log("clock.updated",event.detail);
                });
                $("increment").addEventListener("click", async () => {
                    applyState(await callNative("counter.increment"));
                });
                $("reset").addEventListener("click", async () => {
                    applyState(await callNative("counter.reset"));
                });
                $("clock").addEventListener("click", async () => {
                    setText("time",(await callNative("clock.now")).time);
                });
                $("echo").addEventListener("click", async () => {
                    const result = await callNative("message.echo",{text:$("message").value});
                    setText("native-message","Objective-C received: " + result.payload.text);
                    setText("source","message.echo");
                    setText("time",result.time);
                });
                (async () => {
                    if (!window.AsyncRT) {
                        setText("bridge-status","Bridge unavailable");
                        return;
                    }
                    setText("bridge-status","Bridge ready");
                    applyState(await callNative("app.bootstrap"));
                })();
            </script>
        </body>
        </html>
    )];
}

@end

AsyncWebUI_APPLICATION_MAIN(AsyncWebUIExampleApplication)

#pragma clang assume_nonnull end
