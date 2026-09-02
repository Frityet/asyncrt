#import <OWebHTTP.h>

#pragma clang assume_nonnull begin

typedef void (^OWebHTTPServerExceptionHandler)(id exception);

/**
 * A concrete ObjFW transport for an OWeb router.
 *
 * The convenience initializer binds to an ephemeral port on 127.0.0.1. A
 * non-loopback host is accepted only through the designated initializer; the
 * embedding application remains responsible for authentication, TLS and
 * network policy.
 */
[[subclassing_restricted]]
@interface OWebObjFWHTTPServer : OFObject <OFHTTPServerDelegate>

@property(readonly, nonatomic) OWebRouter *router;
@property(readonly, copy, nonatomic) OFString *host;
@property(readonly, nonatomic) uint16_t configuredPort;
@property(readonly, nonatomic) uint16_t actualPort;
@property(readonly, nonatomic) bool isRunning;
@property(copy, nonatomic, nullable)
    OWebHTTPServerExceptionHandler exceptionHandler;

- (instancetype)initWithRouter: (OWebRouter *)router;
- (instancetype)initWithRouter: (OWebRouter *)router
                           host: (OFString *)host
                           port: (uint16_t)port;
- (instancetype)init OF_UNAVAILABLE;

- (void)start;
- (void)stop;

@end

#pragma clang assume_nonnull end
