# OWeb browser runtime

AsyncRT.Web's browser half is OWeb's standards-based Custom Elements runtime and a small,
strict binary patch virtual machine. Applications serve these modules without a
build step or bundle them with an ordinary ECMAScript-module bundler.

## Server document contract

The server declares the binary endpoint and each compiled component definition
in the initial document:

```html
<meta name="oweb-endpoint" content="/_oweb/frame">

<template
  data-oweb-component="my-component"
  data-oweb-observed-attributes="name tone"
>
  <button data-oweb-id="1" data-oweb-on-click="1"></button>
</template>

<script type="module" nonce="…">
  import { startOWeb } from "/oweb/oweb.mjs";
  startOWeb();
</script>
```

The Objective-C template compiler generates `data-oweb-id`,
`data-oweb-template-id`, and `data-oweb-on-*`; application markup must not
create them directly. Definition templates come from the server document. The
runtime clones their `content` into a shadow root once per mounted instance
lifetime and never accepts markup in a patch frame. A transient disconnect that
ends inside the grace period preserves the tree. A final Detach retires the
opaque instance identifier and reclones the immutable definition. The browser
claims a fresh replacement only if the element later reconnects, so permanently
disconnected elements do not retain active identifier reservations and released
dynamic capabilities cannot survive reconnection.

Clone bytecodes can only reference nested `<template data-oweb-template-id>`
capabilities from that compiled definition. A clone template has exactly one
element root. Its dynamic node identifier addresses that root for subsequent
text, attribute, property, focus, move, and remove operations.

## HTTP exchange

The first transport adapter performs same-origin binary `POST` exchanges with:

- media type `application/vnd.oweb.frame` in `Accept` and `Content-Type`;
- `credentials: "same-origin"`, no cache, and no redirects;
- canonical monotonic `X-OWeb-Sequence` request and response values;
- browser-generated `Origin`, which the native server must validate;
- a one-mebibyte streamed response cap before codec allocation;
- a configurable per-attempt response deadline, 15 seconds by default.

The server returns either one Patch frame for the same component instance or a
sequenced `204` response. Repeating Mount for the same session, instance, and
tag replaces the full reflected-attribute snapshot. Detach is final for its
opaque instance lifetime and is sent only if the element stays disconnected
beyond the short grace period. A later connection uses a fresh identifier and
an independent sequence stream. A network failure or response timeout receives
one retry with the exact same frame bytes and sequence, allowing the server's
replay cache to return the prior outcome without dispatching the action twice.
The terminal deadline is therefore at most two configured per-attempt timeout
periods.

## Observable state

Each host exposes `data-oweb-connection` with values such as `connecting`,
`connected`, `disconnecting`, `disconnected`, or `error`. It also dispatches a
composed `owebconnectionstatechange` event whose detail contains only `state`
and a stable error `code`. No response bodies, application values, selectors,
or server diagnostics are copied into that hook.

## Security invariants

- Patch lookup is by pre-indexed numeric capability, never a dynamic selector.
- Event frames contain an opaque action ID and a small allowlisted scalar field
  projection, never an Objective-C selector.
- Text, attributes, and properties remain distinct typed operations.
- Runtime-owned `data-oweb-*` attributes cannot be patched.
- Frame length, strings, operation count, batch depth, UTF-8, varints, value
  tags, attribute names, property names, and structural relationships are all
  validated before the first DOM mutation.
- Nested removals retire every descendant dynamic capability, and moves cannot
  create a structural cycle.
