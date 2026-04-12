#pragma once

#import "Async/AsyncScheduler.h"
#import "Async/Promise.h"
#import "Async/AsyncUnit.h"
#import "Utilities/Optional.h"

#pragma clang assume_nonnull begin

@interface PromiseObjFWOperationException : PromiseException

@property(readonly, nonatomic) id object;
@property(readonly, nonatomic) OFString *operation;

- (instancetype)initWithPromise: (Promise *)promise object: (id)object operation: (OFString *)operation designated_initaliser;
- (instancetype)initWithPromise: (Promise *)promise OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseObjFWInvalidCompletionException : PromiseObjFWOperationException

@property(readonly, nonatomic) OFString *reason;

- (instancetype)initWithPromise: (Promise *)promise object: (id)object operation: (OFString *)operation reason: (OFString *)reason designated_initaliser;
- (instancetype)initWithPromise: (Promise *)promise object: (id)object operation: (OFString *)operation OF_UNAVAILABLE;
- (instancetype)initWithPromise: (Promise *)promise OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface PromiseObjFWOperationCancelledException : PromiseObjFWOperationException

- (instancetype)initWithPromise: (Promise *)promise object: (id)object operation: (OFString *)operation designated_initaliser;
- (instancetype)initWithPromise: (Promise *)promise OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncBufferReadResult : OFObject

@property(readonly, nonatomic) const void *buffer;
@property(readonly, nonatomic) size_t length;

- (instancetype)initWithBuffer: (const void *)buffer length: (size_t)length designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncDatagramReceiveResult : AsyncBufferReadResult

@property(readonly, nonatomic) OFData *senderAddressData;
@property(readonly, nonatomic) const OFSocketAddress *sender;

- (instancetype)initWithBuffer: (const void *)buffer length: (size_t)length sender: (const OFSocketAddress *)sender designated_initaliser;
- (instancetype)initWithBuffer: (const void *)buffer length: (size_t)length OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

@end

#ifdef OF_HAVE_SCTP
@interface AsyncSCTPReceiveResult : AsyncBufferReadResult

@property(readonly, nonatomic) OFSCTPMessageInfo nillable info;

- (instancetype)initWithBuffer: (const void *)buffer length: (size_t)length info: (OFSCTPMessageInfo nillable)info designated_initaliser;
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

- (instancetype)initWithObject: (id)object operation: (OFString *)operation scheduler: (AsyncScheduler *)scheduler resolver: (PromiseResolver<id> *)resolver startBlock: (void (^)(AsyncObjFWPromiseBridge *bridge))startBlock cancelBlock: (void (^ nillable)(AsyncObjFWPromiseBridge *bridge))cancelBlock designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;
- (void)start;
- (void)cancel;
- (void)resolve: (id)value;
- (void)reject: (OFException *)exception;
- (void)rejectInvalidCompletionWithReason: (OFString *)reason;

@end

@namespace(AsyncObjFWSupport)

+ (void)scheduleOnScheduler: (AsyncScheduler *)scheduler target: (id)target selector: (SEL)selector;
+ (void)attachCancellationBridgeToPromise: (Promise *)promise cancelOnTaskCancellation: (bool)cancelOnTaskCancellation bridge: (AsyncObjFWPromiseBridge *)bridge;
+ (OFData *)copySocketAddressData: (const OFSocketAddress *)socketAddress;

@end

void async_link_objfw_promise_categories(void);

#pragma clang assume_nonnull end
