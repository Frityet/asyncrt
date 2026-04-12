#import "Async/ObjFWAsync/OFIRIHandler+Promise.h"

#pragma clang assume_nonnull begin

@interface AsyncIRIHandlerPromiseDelegate : OFObject<OFIRIHandlerDelegate>

- (instancetype)initWithBridge: (AsyncObjFWPromiseBridge *)bridge handler: (OFIRIHandler *nillable)handler IRI: (OFIRI *)IRI designated_initaliser;
- (instancetype)init OF_UNAVAILABLE;

@end

@implementation AsyncIRIHandlerPromiseDelegate {
    AsyncObjFWPromiseBridge *_bridge;
    OFIRIHandler *nillable _handler;
    OFIRI *_iri;
}

- (instancetype)initWithBridge: (AsyncObjFWPromiseBridge *)bridge handler: (OFIRIHandler *nillable)handler IRI: (OFIRI *)IRI
{
    self = [super init];
    _bridge = bridge;
    _handler = handler;
    _iri = [IRI copy];
    return self;
}

- (void)IRIHandler: (OFIRIHandler *)IRIHandler didOpenItemAtIRI: (OFIRI *)IRI stream: (__kindof OFStream *nillable)stream exception: (id nillable)exception
{
    if ((_handler != nilptr and IRIHandler != (id)_handler) or not [IRI isEqual: _iri]) {
        [_bridge rejectInvalidCompletionWithReason: @"ObjFW opened an IRI with mismatched handler metadata"];
        return;
    }

    if (exception != nilptr) {
        [_bridge reject: $as_nonnil((OFException *)exception)];
    } else if (stream == nilptr) {
        [_bridge rejectInvalidCompletionWithReason: @"ObjFW opened an IRI without returning a stream or exception"];
    } else {
        [_bridge resolve: $as_nonnil(stream)];
    }
}

@end

@implementation OFIRIHandler (PromiseAdditions)

+ (Promise<OFStream *> *)_promiseOpenItemWithObject: (id)object
                                            handler: (OFIRIHandler *nillable)handler
                                                IRI: (OFIRI *)IRI
                                               mode: (OFString *)mode
                                        onScheduler: (AsyncScheduler *)scheduler
                                        classMethod: (bool)classMethod
{
    auto resolver = [[PromiseResolver<OFStream *> alloc] init];
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: object operation: @"asyncOpenItemAtIRI:mode:" scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        auto delegate = [[AsyncIRIHandlerPromiseDelegate alloc] initWithBridge: bridge handler: handler IRI: IRI];
        [object asyncOpenItemAtIRI: IRI mode: mode delegate: delegate];
    } cancelBlock: nilptr];

    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.promise;
}

+ (Promise<OFStream *> *)promiseToOpenItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode onScheduler: (AsyncScheduler *)scheduler
{
    return [self _promiseOpenItemWithObject: self handler: nilptr IRI: IRI mode: mode onScheduler: scheduler classMethod: true];
}

- (Promise<OFStream *> *)promiseToOpenItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode onScheduler: (AsyncScheduler *)scheduler
{
    return [self.class _promiseOpenItemWithObject: self handler: self IRI: IRI mode: mode onScheduler: scheduler classMethod: false];
}

@end

void async_link_objfw_ofirihandler_promise_category(void) {}

#pragma clang assume_nonnull end
