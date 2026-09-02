#include <Common.h>

#if defined(__APPLE__)
# import <mach-o/dyld.h>
# import <mach-o/getsect.h>
# import <objc/runtime.h>
#endif

#if defined(__APPLE__)
/*
 * The lazy-constant-string race exists in current ObjFW main, whose HTTP API
 * also changed status codes from `short` to `unsigned short`. ObjFW 1.5.x has
 * a different constant-string image layout and must not be scanned by the
 * compatibility path below. Derive the distinction from the public headers
 * so one AsyncRT source tree remains compatible with both releases.
 */
constexpr bool AsyncRTObjFWNeedsConstantStringCompatibility = _Generic(
    ((OFHTTPResponse *)nilptr).statusCode,
    unsigned short: true,
    default: false);

/*
 * ObjFW 1.5 lazily converts each OFConstantString literal into its private
 * OFConstantUTF8String representation. With the Apple runtime profile used by
 * AsyncRT, two threads can dispatch an OFConstantString forwarding method at
 * the same time: one converts the object while the other is about to send the
 * private finishInitialization selector. The second send then reaches the
 * already-converted class, where completing initialization is necessarily a
 * no-op, but ObjFW does not implement that selector there. The synchronized
 * empty body also waits for the converting thread to publish all initialized
 * storage before the original forwarding method continues.
 *
 * Install only that missing no-op dynamically. This avoids a fork or public
 * dependency on ObjFW's private class while leaving runtimes without that
 * implementation detail untouched.
 */
[[subclassing_restricted]]
@interface AsyncRTObjFWConstantStringCompatibility: OFObject

+ (void)asyncRT_initializeConstantStringsInImage:
    (const struct mach_header *)header [[direct]];
- (void)asyncRT_finishConstantStringInitialization;

@end

@implementation AsyncRTObjFWConstantStringCompatibility

+ (void)load
{
    if (!AsyncRTObjFWNeedsConstantStringCompatibility)
        return;

    auto constantUTF8StringClass = objc_lookUpClass(
        "OFConstantUTF8String");
    auto selector = @selector(finishInitialization);
    if (constantUTF8StringClass == nullptr ||
        class_getInstanceMethod(constantUTF8StringClass, selector) != nullptr)
        return;

    auto compatibilityMethod = class_getInstanceMethod(self,
        @selector(asyncRT_finishConstantStringInitialization));
    if (compatibilityMethod == nullptr)
        return;
    auto nonnullCompatibilityMethod = $assert_nonnil(compatibilityMethod);

    (void)class_addMethod(constantUTF8StringClass, selector,
        method_getImplementation(nonnullCompatibilityMethod),
        method_getTypeEncoding(nonnullCompatibilityMethod));
}

+ (void)asyncRT_initializeConstantStringsInImage:
    (const struct mach_header *)header
{
#if defined(__LP64__)
    auto constantStringClass = objc_lookUpClass("OFConstantString");
    if (constantStringClass == nullptr)
        return;

    size_t instanceSize = class_getInstanceSize(constantStringClass);
    if (instanceSize == 0)
        return;

    unsigned long sectionSize = 0;
    uint8_t *section = getsectiondata(
        (const struct mach_header_64 *)header, "__DATA",
        "__objc_stringobj", &sectionSize);
    if (section == nullptr || sectionSize % instanceSize != 0)
        return;

    for (size_t offset = 0; offset < sectionSize; offset += instanceSize) {
        id literal = (__bridge id)(void *)(section + offset);
        if (object_getClass(literal) == constantStringClass)
            (void)[(OFString *)literal UTF8String];
    }
#endif
}

- (void)asyncRT_finishConstantStringInitialization
{
    @synchronized (self) {
    }
}

@end

/*
 * dyld invokes this ABI callback synchronously for every existing image when
 * it is registered, and for future dlopen/plugin images before their
 * initializers run. This keeps image-local literals out of the lazy conversion
 * race before any code in that image can create worker threads.
 */
static void
AsyncRTInitializeObjFWConstantStringsInImage(
    const struct mach_header *header, intptr_t VMAddressSlide)
{
    (void)VMAddressSlide;
    [AsyncRTObjFWConstantStringCompatibility
        asyncRT_initializeConstantStringsInImage: header];
}

/*
 * Run after Objective-C +load processing, but before application code can
 * create worker threads. A constructor and dyld callback are the required
 * linker/runtime hooks; the implementation itself remains an Objective-C
 * class method.
 */
__attribute__((constructor))
static void
AsyncRTRegisterObjFWConstantStringImageInitializer(void)
{
    if (!AsyncRTObjFWNeedsConstantStringCompatibility)
        return;

    _dyld_register_func_for_add_image(
        AsyncRTInitializeObjFWConstantStringsInImage);
}
#endif

@implementation NamespaceClass

+ (Class)self { return self; }
+ (Class)class { return self; }

@end

@implementation NilReferenceException

- (instancetype)initWithExpression: (OFString *)expression
{
    self = [super init];
    _expression = expression;
    return self;
}

-(OFString *)description
{
    return [OFString stringWithFormat: @"Nil reference for expression: %@", _expression];
}

@end

@implementation CastFailureException

- (instancetype)initWithCastFrom:(Class)from to:(Class)to
{
    self = [super init];
    _from = from;
    _to = to;
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"Cast failure from %@ to %@", _from, _to];
}

@end
