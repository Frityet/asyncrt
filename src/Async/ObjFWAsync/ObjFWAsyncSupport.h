#pragma once

#import "Async/AsyncScheduler.h"
#import "Async/Promise.h"
#import "Async/AsyncUnit.h"
#import "Utilities/Optional.h"

#pragma clang assume_nonnull begin

@interface PromiseObjFWOperationException : PromiseException {
@private
    id _object;
    OFString *_operation;
}

@property(readonly, nonatomic) id object;
@property(readonly, nonatomic) OFString *operation;

- (instancetype)initWithPromise: (Promise *)future object: (id)object operation: (OFString *)operation OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithPromise: (Promise *)future OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseObjFWInvalidCompletionException : PromiseObjFWOperationException {
@private
    OFString *_reason;
}

@property(readonly, nonatomic) OFString *reason;

- (instancetype)initWithPromise: (Promise *)future object: (id)object operation: (OFString *)operation reason: (OFString *)reason OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithPromise: (Promise *)future object: (id)object operation: (OFString *)operation OF_UNAVAILABLE;
- (instancetype)initWithPromise: (Promise *)future OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseObjFWOperationCancelledException : PromiseObjFWOperationException

- (instancetype)initWithPromise: (Promise *)future object: (id)object operation: (OFString *)operation OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithPromise: (Promise *)future OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncBufferReadResult : OFObject {
@private
    const void *_buffer;
    size_t _length;
}

@property(readonly, nonatomic) const void *buffer;
@property(readonly, nonatomic) size_t length;

- (instancetype)initWithBuffer: (const void *)buffer length: (size_t)length OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncDatagramReceiveResult : AsyncBufferReadResult {
@private
    OFData *_senderAddressData;
}

@property(readonly, nonatomic) OFData *senderAddressData;
@property(readonly, nonatomic) const OFSocketAddress *sender;

- (instancetype)initWithBuffer: (const void *)buffer length: (size_t)length sender: (const OFSocketAddress *)sender OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithBuffer: (const void *)buffer length: (size_t)length OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

#ifdef OF_HAVE_SCTP
@interface AsyncSCTPReceiveResult : AsyncBufferReadResult {
@private
    OFSCTPMessageInfo nillable _info;
}

@property(readonly, nonatomic) OFSCTPMessageInfo nillable info;

- (instancetype)initWithBuffer: (const void *)buffer length: (size_t)length info: (OFSCTPMessageInfo nillable)info OF_DESIGNATED_INITIALIZER;
- (instancetype)initWithBuffer: (const void *)buffer length: (size_t)length OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end
#endif

@interface AsyncObjFWPromiseBridge : OFObject

@property(readonly, nonatomic) id object;
@property(readonly, nonatomic) OFString *operation;
@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) PromiseResolver<id> *resolver;
@property(readonly, nonatomic, getter=isStarted) bool started;

- (instancetype)initWithObject: (id)object operation: (OFString *)operation scheduler: (AsyncScheduler *)scheduler resolver: (PromiseResolver<id> *)resolver startBlock: (void (^)(AsyncObjFWPromiseBridge *bridge))startBlock cancelBlock: (void (^ nillable)(AsyncObjFWPromiseBridge *bridge))cancelBlock OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;
- (void)start;
- (void)cancel;
- (void)resolve: (id)value;
- (void)reject: (OFException *)exception;
- (void)rejectInvalidCompletionWithReason: (OFString *)reason;

@end

@namespace(AsyncObjFWSupport)

+ (void)scheduleOnScheduler: (AsyncScheduler *)scheduler target: (id)target selector: (SEL)selector;
+ (void)attachCancellationBridgeToPromise: (Promise *)future cancelOnTaskCancellation: (bool)cancelOnTaskCancellation bridge: (AsyncObjFWPromiseBridge *)bridge;
+ (OFData *)copySocketAddressData: (const OFSocketAddress *)socketAddress;

@end

void async_link_objfw_promise_categories(void);

#pragma clang assume_nonnull end
