# AsyncRT.Web

AsyncRT.Web brings OWeb's reflected Objective-C components to the browser as a
first-class AsyncRT target, using ObjFW, standards-based Web Components, and a
compact bounded binary patch/event protocol.

```objective-c
@interface MyComponent : Component

@property(readonly, nonatomic) OFString *name;

@end

@implementation MyComponent

+ (OFString *)style
{
    return $css(:host { display: block; });
}

+ (OFString *)layout
{
    return $html(
        <div>
            <h1 id="name"></h1>
            <button onclick="onButtonClick:">Click me!</button>
        </div>
    );
}

- (void)onAttach
{
    [self elementByID: @"name"].textContent = self.name;
}

- (void)onButtonClick: (OWebEvent *)event
{
}

@end
```

The layout macro stringifies an XML-well-formed HTML subset. OWeb validates the
template, reflects attributes and event signatures, replaces handler names with
inert action IDs, and registers a browser custom element such as
`<my-component name="Rei"></my-component>`.

The framework is under active construction. See `ARCHITECTURE.md` for its
security and lifecycle contract. The browser modules install together under
`share/asyncrt/web/browser` and can also be bundled directly from this target's
`src` directory.
