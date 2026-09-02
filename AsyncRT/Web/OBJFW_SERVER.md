# ObjFW HTTP server adapter

`OWebObjFWHTTPServer` is the production transport between ObjFW's
`OFHTTPServer` and an `OWebRouter`:

```objectivec
auto router = [[OWebRouter alloc] initWithMaximumBodyBytes: 1024 * 1024];
[router get: @"/health"
       handler: ^OWebHTTPResponse *(OWebHTTPRequest *request) {
           (void)request;
           return [OWebHTTPResponse textResponse: @"ok" statusCode: 200];
       }];

auto server = [[OWebObjFWHTTPServer alloc] initWithRouter: router];
[server start];
OFLog(@"Listening on http://%@:%u", server.host, server.actualPort);
```

The convenience initializer deliberately binds `127.0.0.1` on an ephemeral
port. Use `initWithRouter:host:port:` when the host application has made an
explicit exposure decision. Port `0` remains supported and `actualPort`
reports the assigned port while running.

The adapter deliberately keeps ObjFW's server at one thread. ObjFW 1.5.7's
public multi-threaded `OFHTTPServer` mode deadlocks during `stop`: its worker
shutdown stops the caller's run loop before joining workers whose run loops
remain active. Until that upstream lifecycle is fixed, enabling its thread
pool would make clean adapter shutdown unreliable.

The adapter rejects a canonical decimal `Content-Length` larger than the
router's `maximumBodyBytes` before attempting to read the body. Every other
request body is read through a fixed-size buffer, stopping when the maximum
would be exceeded, reading at most one byte past that cap, and never allocating
for the excess. It owns response `Content-Length`, ignores application
`Transfer-Encoding`, accurately advertises ObjFW's connection-close lifecycle,
validates outgoing header names and values, suppresses bodies for `HEAD`,
`1xx`, `204`, and `304`, and translates unexpected routing or response errors
into a generic `500 Internal Server Error`. The optional `exceptionHandler` is
for host-side logging; exception text is never sent to the client.

ObjFW's public request-body stream API also does not expose a reliable per-read
or absolute read deadline. A slow partial or chunked body can therefore occupy
the adapter until the peer completes or disconnects. Deployments beyond a
trusted loopback boundary must enforce connection, header, and body deadlines
and concurrency at a trusted reverse proxy or equivalent ingress boundary.

OWeb does not create authentication, TLS, CORS, CSRF, or public-network policy
for the host application. Install those controls as router middleware or in
the enclosing service before binding beyond loopback.
