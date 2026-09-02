#import <Common.h>

#pragma clang assume_nonnull begin

/** Stable error categories which never include request data in diagnostics. */
enum [[clang::enum_extensibility(closed)]] AsyncHTTPSClientErrorCode {
    AsyncHTTPSClientErrorCode_UNAVAILABLE,
    AsyncHTTPSClientErrorCode_INVALID_REQUEST,
    AsyncHTTPSClientErrorCode_CANCELLED,
    AsyncHTTPSClientErrorCode_DEADLINE_EXCEEDED,
    AsyncHTTPSClientErrorCode_HEADER_TOO_LARGE,
    AsyncHTTPSClientErrorCode_BODY_TOO_LARGE,
    AsyncHTTPSClientErrorCode_NAME_RESOLUTION_FAILED,
    AsyncHTTPSClientErrorCode_CONNECTION_FAILED,
    AsyncHTTPSClientErrorCode_TLS_FAILED,
    AsyncHTTPSClientErrorCode_TRANSFER_FAILED,
    AsyncHTTPSClientErrorCode_INTERNAL_ERROR
};

[[subclassing_restricted, direct_members]]
@interface AsyncHTTPSClientException: OFException

@property(readonly, nonatomic) enum AsyncHTTPSClientErrorCode code;

- (instancetype)initWithCode: (enum AsyncHTTPSClientErrorCode)code
    [[designated_initailiser]];
- (instancetype)init [[clang::unavailable]];

@end


/** The status, bounded headers, and bounded body returned by an HTTPS GET. */
[[subclassing_restricted, direct_members]]
@interface AsyncHTTPSResponse: OFObject

@property(readonly, nonatomic) unsigned short statusCode;
@property(readonly, nonatomic) OFData *headerData;
@property(readonly, nonatomic) OFData *body;

- (instancetype)init [[clang::unavailable]];

@end


/**
 * A synchronous, pool-friendly HTTPS GET wrapper around ObjFW's
 * @ref OFHTTPClient.
 *
 * Redirects are disabled, TLS certificate verification remains enabled, and
 * both response headers and the response body are capped. The timeout and
 * cancellation predicate are checked at least every 50 ms once ObjFW exposes
 * a connected transport stream, and while the body is being read.
 *
 * ObjFW 1.x does not expose its in-progress resolver or TCP socket to an
 * OFHTTPClient delegate. Consequently, DNS resolution and TCP connection are
 * not hard-interruptible through the public API. A timeout or cancellation in
 * that phase is remembered and returned as soon as ObjFW completes the phase;
 * the call can therefore exceed `wallTimeout`. This is deliberately surfaced
 * by @ref isPreconnectionDeadlineHard instead of claiming a hard deadline.
 */
[[subclassing_restricted, direct_members]]
@interface AsyncHTTPSClient: OFObject

/** Maximum aggregate response-header bytes accepted after ObjFW parses them. */
@property(class, readonly, nonatomic) size_t maximumResponseHeaderBytes;

/** Always false for the current OFHTTPClient-backed implementation. */
@property(class, readonly, nonatomic) bool isPreconnectionDeadlineHard;

/**
 * Performs one verified HTTPS GET.
 *
 * @param IRI An absolute HTTPS IRI without embedded user information
 * @param headers Additional request headers
 * @param wallTimeout DNS-through-body target timeout in seconds; see the class
 *                    documentation for the preconnection limitation
 * @param maximumResponseBodyBytes Maximum response-body bytes
 * @param cancellation A predicate polled before and during the transfer
 */
- (AsyncHTTPSResponse *)performGETToIRI: (OFIRI *)IRI
                                      headers: (OFDictionary<OFString *, OFString *> *)headers
                                  wallTimeout: (OFTimeInterval)wallTimeout
                     maximumResponseBodyBytes: (size_t)maximumResponseBodyBytes
                                isCancellationRequested: (bool (^)(void))cancellation;

@end


#pragma clang assume_nonnull end
