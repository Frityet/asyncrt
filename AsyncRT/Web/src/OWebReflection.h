#import <OWebComponent.h>

#include <stdint.h>

#pragma clang assume_nonnull begin

typedef enum OWebReflectedPropertyType: uint8_t {
    OWebReflectedPropertyTypeString,
    OWebReflectedPropertyTypeBool,
    OWebReflectedPropertyTypeSignedInteger,
    OWebReflectedPropertyTypeUnsignedInteger,
    OWebReflectedPropertyTypeFloat,
    OWebReflectedPropertyTypeDouble
} OWebReflectedPropertyType;

[[subclassing_restricted, direct_members]]
@interface OWebDefinitionException : OFException

@property(nonatomic, readonly) OFString *reason;

- (instancetype)initWithReason: (OFString *)reason OF_DESIGNATED_INITIALIZER;
- (instancetype)init OF_UNAVAILABLE;

@end

/** Reflected metadata for one safe component attribute/property binding. */
[[subclassing_restricted, direct_members]]
@interface OWebReflectedProperty : OFObject

@property(nonatomic, readonly) OFString *name;
@property(nonatomic, readonly) OFString *attributeName;
@property(nonatomic, readonly) OWebReflectedPropertyType type;
@property(nonatomic, readonly) bool isReadonly;
@property(nonatomic, readonly) bool isHydratable;

- (instancetype)init OF_UNAVAILABLE;

@end

/** A server-only mapping from an opaque action ID to a validated selector. */
[[subclassing_restricted, direct_members]]
@interface OWebActionDefinition : OFObject

@property(nonatomic, readonly) uint64_t identifier;
/** Static element capability that declared this action. */
@property(nonatomic, readonly) uint64_t targetIdentifier;
@property(nonatomic, readonly) OFString *eventName;
@property(nonatomic, readonly) OFString *selectorName;

- (instancetype)init OF_UNAVAILABLE;

@end

/** Immutable reflected and compiled definition of one component class. */
[[subclassing_restricted, direct_members]]
@interface OWebComponentDefinition : OFObject

@property(nonatomic, readonly) Class componentClass;
@property(nonatomic, readonly) OFString *elementName;
@property(nonatomic, readonly) OFString *style;
@property(nonatomic, readonly) OFString *compiledLayout;
@property(nonatomic, readonly)
    OFDictionary<OFString *, OWebReflectedProperty *> *propertiesByAttribute;
@property(nonatomic, readonly)
    OFDictionary<OFNumber *, OWebActionDefinition *> *actionsByIdentifier;
@property(nonatomic, readonly)
    OFDictionary<OFString *, OFNumber *> *elementIdentifiersByID;
@property(nonatomic, readonly)
    OFDictionary<OFString *, OFNumber *> *templateIdentifiersByID;
/** DOM tag for every static element capability, including event-only nodes. */
@property(nonatomic, readonly)
    OFDictionary<OFNumber *, OFString *> *tagNamesByElementIdentifier;
/** DOM root tag produced by each declared clone template. */
@property(nonatomic, readonly)
    OFDictionary<OFNumber *, OFString *> *rootTagNamesByTemplateIdentifier;
/** Static elements whose textContent would destroy a nested capability. */
@property(nonatomic, readonly)
    OFSet<OFNumber *> *elementIdentifiersContainingStaticCapabilities;
/** Highest numeric ID reserved by the compiled static template. */
@property(nonatomic, readonly) uint64_t maximumStaticIdentifier;

- (OWebComponent *)instantiateWithAttributes:
    (OFDictionary<OFString *, OFString *> *)attributes;
- (OWebComponent *)instantiateWithAttributes:
    (OFDictionary<OFString *, OFString *> *)attributes
                                patchSink: (nullable OWebPatchSink)patchSink;

- (instancetype)init OF_UNAVAILABLE;

@end

/** Thread-safe reflected definition registry. */
[[subclassing_restricted, direct_members]]
@interface OWebComponentRegistry : OFObject

@property(class, nonatomic, readonly) OWebComponentRegistry *sharedRegistry;
@property(nonatomic, readonly) OFArray<OWebComponentDefinition *> *definitions;

- (OWebComponentDefinition *)registerComponentClass: (Class)componentClass;
- (OWebComponentDefinition *)definitionForComponentClass: (Class)componentClass;
- (nullable OWebComponentDefinition *)definitionForElementName:
    (OFString *)elementName;

/** Discovers all loaded OWebComponent subclasses through the ObjC runtime. */
- (OFArray<OWebComponentDefinition *> *)discoverLoadedComponentClasses;

@end

#pragma clang assume_nonnull end
