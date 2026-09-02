#import <OWebTemplate.h>

#if defined(__APPLE__)
# import <objc/runtime.h>
#else
# import <ObjFWRT/ObjFWRT.h>
#endif

#pragma clang assume_nonnull begin

@interface OWebReflectedProperty (OWebInternal)

+ (OFArray<OWebReflectedProperty *> *)propertiesForComponentClass:
    (Class)componentClass;
- (void)hydrateComponent: (OWebComponent *)component
                 fromValue: (OFString *)value;

@end


@interface OWebActionDefinition (OWebInternal)

- (instancetype)initWithIdentifier: (uint64_t)identifier
                   targetIdentifier: (uint64_t)targetIdentifier
                          eventName: (OFString *)eventName
                        selectorName: (OFString *)selectorName;
- (void)invokeOnComponent: (OWebComponent *)component event: (OWebEvent *)event;

@end


@interface OWebComponentDefinition (OWebInternal)

- (instancetype)initWithComponentClass: (Class)componentClass
                             elementName: (OFString *)elementName
                                   style: (OFString *)style
                        compiledTemplate: (OWebCompiledTemplate *)compiledTemplate
                              properties:
    (OFArray<OWebReflectedProperty *> *)properties;
- (void)hydrateComponent: (OWebComponent *)component
            withAttributes: (OFDictionary<OFString *, OFString *> *)attributes;
- (void)dispatchActionIdentifier: (uint64_t)actionIdentifier
                     onComponent: (OWebComponent *)component
                           event: (OWebEvent *)event;

@end


@interface OWebComponent (OWebInternal)

- (instancetype)initWithDefinition: (OWebComponentDefinition *)definition
                          patchSink: (nullable OWebPatchSink)patchSink;
- (void)emitPatch: (OWebPatchOperation *)patch;
- (uint64_t)allocateDynamicNodeIdentifier;
- (OFNumber *)templateIdentifierForID: (OFString *)templateID;

@end

#pragma clang assume_nonnull end
