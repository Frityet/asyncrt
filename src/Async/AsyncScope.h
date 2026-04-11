#pragma once

#import "Async/Task.h"

#pragma clang assume_nonnull begin

@class AsyncScope;
@class AsyncScheduler;

@interface AsyncScopeException : OFException {
@private
    unretained AsyncScope *nillable _scope;
    OFArray<OFException *> *_exceptions;
}

@property(readonly, nonatomic) AsyncScope *nillable scope;
@property(readonly, nonatomic) OFArray<OFException *> *exceptions;
@property(readonly, nonatomic) OFException *primaryException;

- (instancetype)initWithScope: (AsyncScope *)scope exceptions: (OFArray<OFException *> *)exceptions OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncTimeoutException : OFException {
@private
    unretained AsyncScope *nillable _scope;
    OFDate *_deadline;
}

@property(readonly, nonatomic) AsyncScope *nillable scope;
@property(readonly, nonatomic) OFDate *deadline;

- (instancetype)initWithScope: (AsyncScope *)scope deadline: (OFDate *)deadline OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncScope : OFObject

@property(class, readonly, nonatomic) AsyncScope *nillable currentScope;
@property(readonly, nonatomic) AsyncScheduler *scheduler;
@property(readonly, nonatomic) AsyncScope *nillable parentScope;
@property(readonly, nonatomic) Task *ownerTask;
@property(readonly, nonatomic) OFString *nillable name;
@property(readonly, nonatomic) OFDate *nillable deadline;
@property(readonly, nonatomic, getter=isCancellationRequested) bool cancellationRequested;

+ (AsyncScope *nillable)currentScope;
- (Task<id> *)spawn: (id (^)(void))block;
- (Task<id> *)spawn: (id (^)(void))block name: (OFString *nillable)name;
- (id)withChildScope: (id (^)(AsyncScope *scope))block;
- (id)withChildScopeNamed: (OFString *nillable)name block: (id (^)(AsyncScope *scope))block;
- (id)withTimeout: (OFTimeInterval)timeout block: (id (^)(AsyncScope *scope))block;
- (id)withDeadline: (OFDate *)deadline block: (id (^)(AsyncScope *scope))block;
- (void)cancel;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
