# OWeb component sessions

`OWebComponentEndpoint` is the binary HTTP bridge between the router, the wire
codec, and reflected server-owned components. The application installs it on
an exact POST path and supplies the authenticated page identity:

```objectivec
auto endpoint = [[OWebComponentEndpoint alloc]
    initWithRegistry: OWebComponentRegistry.sharedRegistry
    expectedOrigin: @"https://app.example"
    maximumBodyBytes: OWebWireMaximumFrameBytes
    sessionIdentityProvider: ^OFString *(OWebHTTPRequest *request) {
        return [applicationSessions identityForRequest: request];
    }];
[endpoint installOnRouter: router path: @"/_oweb/frame"];
```

The identity block is the only authentication integration point. OWeb neither
issues credentials nor treats a browser-provided instance ID as an identity.
When a host session ends, call `removeSessionForIdentity:`.

## Boundary contract

- `Origin` must exactly equal the configured same-origin value.
- `Content-Type` and `Accept` must be `application/vnd.oweb.frame`.
- Request bodies are nonempty and capped by both the configured limit and the
  protocol's one-mebibyte limit.
- `X-OWeb-Sequence` is canonical positive decimal. It strictly increases for
  each mounted instance stream, except that one byte-identical retransmission
  of the current request receives its cached outcome without redispatch.
- Successful responses echo the sequence and contain either one typed Patch
  frame or a `204` acknowledgement. Responses are `no-store`.

Failures have stable ASCII bodies such as `invalid-origin`,
`sequence-conflict`, `capacity-exceeded`, `invalid-target`, or
`internal-error`. They never expose Objective-C selectors, component
exceptions, raw markup, event values, or authentication details. Generic
component or endpoint exceptions become a sanitized `500 internal-error`; an
affected component instance is evicted before it can process another frame.

## Ownership and lifecycle

The first Mount claims an instance ID inside one session. The same ID remains
independent in a different authenticated session. Repeating Mount with the same
tag and identical full attribute snapshot is a no-op. A changed full snapshot
constructs a fresh reflected component, removes old dynamic template roots,
and returns the new `onAttach` patches atomically. Reusing the ID with another
tag is a conflict. Detach releases the component and all of its server state.

A changed Mount does **not** currently replace or reclone the browser's whole
static shadow tree. It resets server-owned component state, removes dynamic
template roots, and applies the fresh component's declared patches to the
existing static tree. Applications that need a full static-tree reset must
detach/remount the custom element at the browser lifecycle level.

Before action dispatch, the session independently validates the opaque action
capability and requires its target to be the exact static element capability
that declared it. It then builds an allowlisted value-only `OWebEvent`; selector
names never cross the wire.
The template compiler records each static capability's tag, each clone
template's root tag, and which static elements contain nested element or
template capabilities. Against a copied state, the session mirrors the browser
preflight rules that prevent `SetText` from destroying static or dynamic
capabilities and require `CloneTemplate` / `MoveNode` parents to be real,
non-void containers. Dynamic parentage and clone-root tags are tracked in the
same transaction. The copied state is committed only after every operation
passes these checks and the entire patch frame preflight-encodes successfully.
The browser still independently validates the live DOM before applying a frame;
the server model covers compiled OWeb capabilities and OWeb-created dynamic
roots, rather than claiming to model unrelated out-of-band DOM mutation.

For the current sequence number, the session retains a SHA-256 fingerprint of
the canonical bounded frame and its complete response outcome, including a
no-patch `204` or stable failure. An exact retransmission receives that cached
outcome; the same sequence with a different frame is rejected. This makes the
browser's single response-loss retry safe for state-changing actions. Both the
mounted-instance table and replay cache have explicit per-session limits.
Replay entries for currently mounted instances are never evicted by unrelated
invalid traffic. When the replay cache is completely occupied by mounted
instances, an outcome for a new unowned identifier is deliberately not cached
rather than weakening response-loss recovery for live components.

The endpoint also has an explicit authenticated-session limit and idle TTL.
The convenience initializer defaults to 1,024 sessions, a 30-minute idle TTL,
256 mounted instances per session, and 512 replay entries per session. Hosts
with tighter budgets can use the designated initializer to lower every bound;
ending authentication still calls `removeSessionForIdentity:` immediately.
