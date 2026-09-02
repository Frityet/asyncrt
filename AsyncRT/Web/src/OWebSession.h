#import <OWebHTTP.h>
#import <OWebReflection.h>
#import <OWebWireProtocol.h>

#include <stdint.h>

#pragma clang assume_nonnull begin

/** Stable failures exposed by the session and HTTP boundary. */
typedef enum OWebSessionFailure: uint8_t {
    OWebSessionFailureInvalidIdentity,
    OWebSessionFailureInvalidOrigin,
    OWebSessionFailureInvalidContentType,
    OWebSessionFailureNotAcceptable,
    OWebSessionFailureBodyTooLarge,
    OWebSessionFailureInvalidSequence,
    OWebSessionFailureSequenceConflict,
    OWebSessionFailureStaleSequence,
    OWebSessionFailureInvalidFrame,
    OWebSessionFailureUnexpectedFrame,
    OWebSessionFailureUnknownComponent,
    OWebSessionFailureInstanceConflict,
    OWebSessionFailureUnknownInstance,
    OWebSessionFailureUnknownAction,
    OWebSessionFailureInvalidTarget,
    OWebSessionFailureInvalidEventValue,
    OWebSessionFailureComponentRejectedInput,
    OWebSessionFailureCapacityExceeded,
    OWebSessionFailureInternalError
} OWebSessionFailure;

/** Conservative defaults; hosts can lower them with the designated inits. */
static const size_t OWebDefaultMaximumMountedInstances = 256;
static const size_t OWebDefaultMaximumReplayEntries = 512;
static const size_t OWebDefaultMaximumSessions = 1024;
static const OFTimeInterval OWebDefaultSessionIdleTimeToLive = 30 * 60;

[[subclassing_restricted, direct_members]]
@interface OWebSessionException : OFException

@property(nonatomic, readonly) OWebSessionFailure failure;
@property(nonatomic, readonly) unsigned short statusCode;
/** Stable, non-sensitive ASCII code suitable for an HTTP response. */
@property(nonatomic, readonly) OFString *code;

- (instancetype)init OF_UNAVAILABLE;

@end

/**
 * One authenticated page session.
 *
 * Browser instance IDs are owned only inside this object. A Mount claims an
 * ID; a final Detach releases it. HTTP sequence values are strictly increasing
 * per mounted instance because each custom element is an independent ordered
 * request stream inside the page session. The current request digest and
 * response outcome are retained in a bounded replay cache so response-loss
 * retransmission cannot redispatch a state-changing action.
 */
[[subclassing_restricted, direct_members]]
@interface OWebComponentSession : OFObject

@property(nonatomic, readonly) OWebComponentRegistry *registry;
@property(nonatomic, readonly) size_t mountedInstanceCount;
@property(nonatomic, readonly) size_t replayEntryCount;
@property(nonatomic, readonly) size_t maximumMountedInstances;
@property(nonatomic, readonly) size_t maximumReplayEntries;

- (instancetype)initWithRegistry: (OWebComponentRegistry *)registry;
/** Configures hard per-session ownership and replay-memory limits. */
- (instancetype)initWithRegistry: (OWebComponentRegistry *)registry
             maximumMountedInstances: (size_t)maximumMountedInstances
                maximumReplayEntries: (size_t)maximumReplayEntries
    OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

/**
 * Processes one already-decoded browser frame.
 *
 * Returns a typed Patch frame when the component emitted operations, or
 * `nilptr` for a successful acknowledgement with no DOM work.
 */
- (nullable OWebPatchFrame *)processFrame: (id<OWebWireFrame>)frame
                                     sequence: (uint64_t)sequence;

- (bool)ownsInstanceIdentifier: (uint64_t)instanceIdentifier;

@end

/** The host application supplies identity; OWeb does not issue credentials. */
typedef OFString *nillable (^OWebSessionIdentityProvider)(
    OWebHTTPRequest *request);

/**
 * Same-origin binary HTTP endpoint joining OWeb.Router and component sessions.
 *
 * The endpoint validates Origin, MIME type, body size and canonical sequence
 * before dispatch. It neither defines nor weakens the host's authentication
 * policy: the injected provider must return a stable opaque session identity.
 */
[[subclassing_restricted, direct_members]]
@interface OWebComponentEndpoint : OFObject

@property(nonatomic, readonly) OWebComponentRegistry *registry;
@property(nonatomic, readonly) OFString *expectedOrigin;
@property(nonatomic, readonly) size_t maximumBodyBytes;
@property(nonatomic, readonly) size_t maximumSessions;
@property(nonatomic, readonly) OFTimeInterval sessionIdleTimeToLive;
@property(nonatomic, readonly) size_t maximumMountedInstancesPerSession;
@property(nonatomic, readonly) size_t maximumReplayEntriesPerSession;
@property(nonatomic, readonly) size_t activeSessionCount;

- (instancetype)initWithRegistry: (OWebComponentRegistry *)registry
                   expectedOrigin: (OFString *)expectedOrigin
                 maximumBodyBytes: (size_t)maximumBodyBytes
         sessionIdentityProvider:
             (OWebSessionIdentityProvider)sessionIdentityProvider;
/** Configures the endpoint session cap, idle TTL, and per-session limits. */
- (instancetype)initWithRegistry: (OWebComponentRegistry *)registry
                   expectedOrigin: (OFString *)expectedOrigin
                 maximumBodyBytes: (size_t)maximumBodyBytes
                  maximumSessions: (size_t)maximumSessions
            sessionIdleTimeToLive: (OFTimeInterval)sessionIdleTimeToLive
 maximumMountedInstancesPerSession:
     (size_t)maximumMountedInstancesPerSession
    maximumReplayEntriesPerSession:
        (size_t)maximumReplayEntriesPerSession
         sessionIdentityProvider:
             (OWebSessionIdentityProvider)sessionIdentityProvider
    OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

/** Installs a binary POST endpoint at an exact router path. */
- (void)installOnRouter: (OWebRouter *)router path: (OFString *)path;

/** Public for non-router adapters and deterministic boundary tests. */
- (OWebHTTPResponse *)handleRequest: (OWebHTTPRequest *)request;

/** Explicit lifecycle hooks for host-owned authentication/session stores. */
- (nullable OWebComponentSession *)existingSessionForIdentity:
    (OFString *)identity;
- (void)removeSessionForIdentity: (OFString *)identity;

@end

#pragma clang assume_nonnull end
