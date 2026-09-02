#import <OWebReflection.h>

#pragma clang assume_nonnull begin

/** Result of strict template compilation. */
[[subclassing_restricted, direct_members]]
@interface OWebCompiledTemplate : OFObject

@property(nonatomic, readonly) OFString *markup;
@property(nonatomic, readonly)
    OFDictionary<OFString *, OFNumber *> *elementIdentifiersByID;
@property(nonatomic, readonly)
    OFDictionary<OFString *, OFNumber *> *templateIdentifiersByID;
@property(nonatomic, readonly)
    OFDictionary<OFNumber *, OWebActionDefinition *> *actionsByIdentifier;
/** DOM tag for every static element capability, including event-only nodes. */
@property(nonatomic, readonly)
    OFDictionary<OFNumber *, OFString *> *tagNamesByElementIdentifier;
/** DOM root tag produced by each declared clone template. */
@property(nonatomic, readonly)
    OFDictionary<OFNumber *, OFString *> *rootTagNamesByTemplateIdentifier;
/** Static elements whose textContent would destroy a nested capability. */
@property(nonatomic, readonly)
    OFSet<OFNumber *> *elementIdentifiersContainingStaticCapabilities;
@property(nonatomic, readonly) uint64_t maximumStaticIdentifier;

- (instancetype)init OF_UNAVAILABLE;

@end


/**
 * Compiler for OWeb's deterministic template language.
 *
 * Layouts are an XML-well-formed HTML subset: tags are lowercase, attributes
 * are quoted, non-void elements have explicit closing tags, and void elements
 * are self-closing in source. Processing instructions, doctypes, namespaces,
 * comments, CDATA, executable elements, inline CSS, unsafe URLs, duplicate IDs,
 * and unbound event selectors are rejected. The `<template id="...">` element
 * is supported for typed clone/remove/move operations, but descendants of a
 * template may not declare IDs because a clone can occur more than once.
 */
[[subclassing_restricted, direct_members]]
@interface OWebTemplateCompiler : OFObject

+ (OWebCompiledTemplate *)compileLayout: (OFString *)layout
                         forComponentClass: (Class)componentClass;
+ (void)validateStyle: (OFString *)style;
+ (bool)isRuntimeAttributeNameSafe: (OFString *)name
                                 value: (nullable OFString *)value;

- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
