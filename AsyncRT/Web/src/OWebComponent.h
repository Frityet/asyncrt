#import <Common.h>

#include <stdint.h>

#pragma clang assume_nonnull begin

@class OWebComponentDefinition;
@class OWebPatchOperation;

/**
 * Immutable, allowlisted browser event data delivered to a reflected action.
 *
 * Selector names never come from the browser. The component definition first
 * resolves an opaque action identifier, then constructs this value from a
 * decoded and bounded event frame.
 */
[[subclassing_restricted, direct_members]]
@interface OWebEvent : OFObject

@property(nonatomic, readonly) OFString *type;
@property(nonatomic, readonly) uint64_t targetIdentifier;
@property(nonatomic, readonly) OFDictionary<OFString *, id> *fields;

- (instancetype)initWithType: (OFString *)type
             targetIdentifier: (uint64_t)targetIdentifier
                        fields: (OFDictionary<OFString *, id> *)fields
    OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

@class OWebComponent;

/**
 * Server-side capability for one element declared by a compiled template.
 *
 * It can emit typed patches, but it cannot inject markup. Structural list
 * changes may only clone a compiler-declared `<template id="...">`.
 */
[[subclassing_restricted, direct_members]]
@interface OWebElement : OFObject

@property(nonatomic, readonly) OFString *logicalIdentifier;
@property(nonatomic, readonly) uint64_t identifier;
@property(nonatomic, copy) OFString *textContent;

- (void)setAttribute: (OFString *)name value: (OFString *)value;
- (void)removeAttribute: (OFString *)name;
- (void)focus;

/**
 * Appends a fresh keyed clone of a compiler-declared template.
 *
 * Keys are unique within this parent. The returned proxy addresses the cloned
 * node and can be moved, removed, or patched without accepting arbitrary HTML.
 */
- (OWebElement *)appendTemplateWithID: (OFString *)templateID
                                  key: (OFString *)key;
- (void)removeChild: (OWebElement *)child;
- (void)moveChild: (OWebElement *)child
       beforeChild: (nullable OWebElement *)beforeChild;

- (instancetype)init OF_UNAVAILABLE;

@end

typedef void (^OWebPatchSink)(OWebPatchOperation *patch);

/** Base class for reflected, server-owned Web Components. */
@interface OWebComponent : OFObject

@property(nonatomic, readonly) OWebComponentDefinition *definition;

/** Optional component-scoped CSS. It is validated before embedding. */
+ (OFString *)style;

/** XML-well-formed HTML subset produced with `$html(...)`. */
+ (OFString *)layout;

/**
 * Browser custom-element name. The default is reflected from the class name,
 * for example `MyComponent` becomes `my-component`.
 */
+ (OFString *)elementName;

/** Called after reflected attributes and element proxies are ready. */
- (void)onAttach;

/** Resolves a statically declared element ID or throws for an unknown ID. */
- (OWebElement *)elementByID: (OFString *)logicalIdentifier;

/**
 * Atomically drains patches accumulated since the previous drain.
 *
 * A server may additionally install a sink while constructing the component;
 * patches remain drainable so lifecycle code never needs access to ivars.
 */
- (OFArray<OWebPatchOperation *> *)drainPatches;

/** Resolves and invokes a compiler-validated action. */
- (void)dispatchActionIdentifier: (uint64_t)actionIdentifier
                           event: (OWebEvent *)event;

@end

/** Keeps the concise authoring spelling from the public example. */
@compatibility_alias Component OWebComponent;

#define OWEB_STRINGIFY_LAYOUT_(...) #__VA_ARGS__
#define OWEB_OBJC_STRING_(literal) @literal
#define OWEB_OBJC_STRING(literal) OWEB_OBJC_STRING_(literal)

/** Stringifies an XML-well-formed HTML token sequence into an ObjFW string. */
#define $html(...) OWEB_OBJC_STRING(OWEB_STRINGIFY_LAYOUT_(__VA_ARGS__))

/** Stringifies component-scoped CSS, which is still validated at registry time. */
#define $css(...) OWEB_OBJC_STRING(OWEB_STRINGIFY_LAYOUT_(__VA_ARGS__))

#pragma clang assume_nonnull end
