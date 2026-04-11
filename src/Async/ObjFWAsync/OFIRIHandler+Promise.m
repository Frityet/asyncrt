#import "Async/ObjFWAsync/OFIRIHandler+Promise.h"

#pragma clang assume_nonnull begin

@interface AsyncIRIHandlerPromiseDelegate : OFObject<OFIRIHandlerDelegate>

- (instancetype)initWithBridge: (AsyncObjFWPromiseBridge *)bridge handler: (OFIRIHandler *nillable)handler IRI: (OFIRI *)IRI OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@implementation AsyncIRIHandlerPromiseDelegate {
    AsyncObjFWPromiseBridge *_bridge;
    OFIRIHandler *nillable _handler;
    OFIRI *_IRI;
}

- (instancetype)initWithBridge: (AsyncObjFWPromiseBridge *)bridge handler: (OFIRIHandler *nillable)handler IRI: (OFIRI *)IRI
{
    self = [super init];
    _bridge = bridge;
    _handler = handler;
    _IRI = [IRI copy];
    return self;
}

- (void)IRIHandler: (OFIRIHandler *)IRIHandler didOpenItemAtIRI: (OFIRI *)IRI stream: (OF_KINDOF(OFStream *) nillable)stream exception: (id nillable)exception
{
    if ((_handler != nilptr and (OFIRIHandler *nillable)IRIHandler != _handler) or not [IRI isEqual: _IRI]) {
        [_bridge rejectInvalidCompletionWithReason: @"ObjFW opened an IRI with mismatched handler metadata"];
        return;
    }

    if (exception != nilptr) {
        [_bridge reject: (OFException *)exception];
    } else if ((OFStream *nillable)stream == nilptr) {
        [_bridge rejectInvalidCompletionWithReason: @"ObjFW opened an IRI without returning a stream or exception"];
    } else {
        OFStream *resolvedStream = (OFStream *)stream;
        [_bridge resolve: resolvedStream];
    }
}

@end

static Promise<OFStream *> *PromiseOpenIRIItem(id object, OFIRIHandler *nillable handler, OFIRI *IRI, OFString *mode, AsyncScheduler *scheduler, bool classMethod)
{
    auto resolver = [[PromiseResolver<OFStream *> alloc] init];
    auto bridge = [[AsyncObjFWPromiseBridge alloc] initWithObject: object operation: @"asyncOpenItemAtIRI:mode:" scheduler: scheduler resolver: (PromiseResolver<id> *)resolver startBlock: ^(AsyncObjFWPromiseBridge *bridge) {
        auto delegate = [[AsyncIRIHandlerPromiseDelegate alloc] initWithBridge: bridge handler: handler IRI: IRI];

        if (classMethod)
            [(Class)object asyncOpenItemAtIRI: IRI mode: mode delegate: delegate];
        else
            [(OFIRIHandler *)object asyncOpenItemAtIRI: IRI mode: mode delegate: delegate];
    } cancelBlock: nilptr];

    [AsyncObjFWSupport scheduleOnScheduler: scheduler target: bridge selector: @selector(start)];
    return resolver.future;
}

@implementation OFIRIHandler (PromiseAdditions)

+ (Promise<OFStream *> *)promiseToOpenItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode onScheduler: (AsyncScheduler *)scheduler
{
    return PromiseOpenIRIItem(self, nilptr, IRI, mode, scheduler, true);
}

- (Promise<OFStream *> *)promiseToOpenItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode onScheduler: (AsyncScheduler *)scheduler
{
    return PromiseOpenIRIItem(self, self, IRI, mode, scheduler, false);
}

@end

void async_link_objfw_ofirihandler_promise_category(void) {}

#pragma clang assume_nonnull end
