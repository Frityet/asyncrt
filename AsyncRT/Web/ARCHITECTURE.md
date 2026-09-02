# AsyncRT.Web architecture

AsyncRT.Web integrates OWeb as a server-owned component framework for
AsyncRT/ObjFW applications. Objective-C classes define a strict HTML-subset
template, reflected attributes, styles, and event methods. Standards-based
custom elements attach the template in a shadow root. Interaction is carried
in bounded binary frames; the browser never evaluates server-supplied
JavaScript and the patch virtual machine has no `innerHTML` operation.

## Trust boundary

- Templates are compiled once into inert markup plus a selector-to-action map.
- Only methods declared by the component and validated as `void action:(OWebEvent *)`
  can become browser actions.
- Browser event frames contain opaque instance/action identifiers and an
  allowlisted field map. Every action is bound to the static element capability
  that declared it, so a client cannot pair a valid action with another target.
  The server does not accept selector names from the browser.
- Patches address IDs declared in the compiled template. Text and attributes
  stay distinct; text is never parsed as markup.
- Frames, strings, fields, and operation counts are capped before allocation.
- A per-page session serializes events for each component instance. Components
  are not shared across users.

## Lifecycle

1. The registry reflects and validates a component class.
2. The document renders its compiled template and immutable definition.
3. A browser custom element attaches a shadow root exactly once. Reconnection
   inside the disconnect grace period preserves its mounted tree. A final
   Detach ends that instance lifetime; any later connection rotates the opaque
   instance identifier and reclones the immutable definition so stale dynamic
   capabilities cannot cross lifetimes.
4. `onAttach` runs server-side and emits an initial patch batch through
   `OWebElement` proxies.
5. Browser events carry an action ID, not an Objective-C selector. The server
   resolves it through the compiled definition, invokes the validated method,
   then returns a patch batch.

## Transport

The protocol is transport-neutral. The first server adapter uses binary HTTP
request/response, which fits ObjFW's public HTTP server API and works through
ordinary proxies. A future WebSocket adapter can reuse the same frames without
changing component code. OWeb does not claim WebSocket support until an adapter
has passed framing, masking, backpressure, and close-handshake tests.

The HTTP client serializes each component's frames. If `fetch` loses a response,
it retries the exact byte sequence once with the same sequence number; the
session replays the cached response and never dispatches an action twice.

## Template subset

Component layout is XML-well-formed HTML: quoted attributes, explicit closing
tags, and self-closing void elements. This makes validation deterministic and
keeps the authoring macro compile-time-simple. The browser still receives
ordinary HTML inside a `<template>`.
