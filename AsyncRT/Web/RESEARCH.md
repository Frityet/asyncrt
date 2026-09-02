# Research notes and decisions

These notes record why OWeb uses a small typed DOM protocol rather than a
browser-side virtual DOM or a general-purpose RPC envelope.

## Server-owned UI precedents

Phoenix LiveView keeps UI state server-side, sends events from declarative
bindings, and distinguishes replacement, keyed streams, and client-owned
regions. Its documentation also calls out focus-sensitive patches,
debounce/throttle, disconnect state, and optimistic commands. OWeb adopts the
parts that fit native components:

- stable IDs are mandatory patch addresses;
- dynamic collections are keyed and clone compiler-declared templates;
- an event has an in-flight sequence and later replies cannot overwrite newer
  local state;
- reconnect and duplicate delivery are explicit lifecycle cases;
- client-owned properties such as current focus are only changed by an
  explicit opcode.

OWeb does not send replacement HTML for routine updates. The server emits typed
text, attribute, property, focus, and keyed-template operations. This makes the
browser interpreter small and makes the injection boundary reviewable.

Sources:

- <https://phoenix-live-view.hexdocs.pm/bindings.html>
- <https://phoenix-live-view.hexdocs.pm/syncing-changes.html>
- <https://phoenix-live-view.hexdocs.pm/assigns-eex.html>

## Web Components lifecycle

The HTML standard permits a custom element to connect, disconnect, and connect
again. OWeb therefore attaches a shadow tree once, while transport mount and
detach notifications are independently idempotent. Observed reflected
attributes are compiler metadata rather than an unbounded `data-*` channel.

Source: <https://html.spec.whatwg.org/multipage/custom-elements.html>

## DOM injection boundary

Trusted Types identifies string-to-DOM APIs such as `innerHTML` as powerful
injection sinks. OWeb's browser runtime does not use them. Initial templates are
part of the server-generated document, text uses `textContent`, attributes use
`setAttribute` after name validation, and dynamic structure clones a declared
`HTMLTemplateElement`. This permits a CSP with no Trusted Types policies and
`require-trusted-types-for 'script'`.

Sources:

- <https://www.w3.org/TR/trusted-types/>
- <https://www.w3.org/TR/CSP/>

## Binary format choice

CBOR is compact, standardized, and extensible, so it is the baseline for a
future generic data channel. DOM updates have a much narrower schema, however:
an opcode plus a few bounded IDs and values. OWeb uses a versioned patch/event
bytecode only if the checked-in benchmark confirms a material size or CPU win
over ObjFW JSON. The decoder still follows CBOR's useful discipline: canonical
encodings, explicit limits, deterministic rejection, and no implicit coercion.

Source: <https://www.rfc-editor.org/rfc/rfc8949.html>

## Transport choice

The bytecode is independent of transport. Binary HTTP request/response is the
first adapter because ObjFW exposes a supported HTTP server delegate and it
naturally provides event acknowledgement and backpressure. WebSocket framing
adds masking, fragmentation, ping/pong, closing, size enforcement, and
backpressure obligations; OWeb will not claim it until those RFC requirements
are implemented against a supported socket takeover API or a dedicated server.

Source: <https://www.rfc-editor.org/rfc/rfc6455.html>
