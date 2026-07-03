#import <ObjFW/ObjFW.h>
#include <iso646.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdatomic.h>

#define nonnil _Nonnull
#define nillable _Nullable
#define nillability_unspecified _Null_unspecified
#define nullptr ((void *nillable)0)
#define nilptr ((id nillable)0)

#define block_reference __block
#define unretained __unsafe_unretained
#define unretained_cast __bridge
#define retained_cast __bridge_retained
#define method_family(name) clang::objc_method_family(name)
#define designated_initailiser clang::objc_designated_initializer
#define unavailable clang::unavailable

#define direct clang::objc_direct
#define direct_members clang::objc_direct_members
#if defined(ASYNC_RUNTIME_TEST_BUILD)
#   define subclassing_restricted clang::annotate("async_runtime_test_attribute")
#else
#   define subclassing_restricted clang::objc_subclassing_restricted
#endif
#if !defined(__cplusplus)
#   define auto __auto_type
#endif

#define atomic_t(...) _Atomic(__VA_ARGS__)

#define $raw(...) #__VA_ARGS__

@interface NilReferenceException : OFException

@property(nonatomic, readonly) OFString *expression;

- (instancetype)initWithExpression:(OFString *)expression;

@end

#define $as_nonnil(...) (__builtin_assume((__VA_ARGS__) != nilptr), (typeof(typeof(*(__VA_ARGS__)) *nonnil))(__VA_ARGS__))
#if defined(NDEBUG)
#   define $assert_nonnil(...) $as_nonnil(__VA_ARGS__)
#else
#   define $assert_nonnil(...) ({ \
        __auto_type _assert_nonnil_value = (__VA_ARGS__); \
        if (OF_UNLIKELY(not _assert_nonnil_value)) { \
            @throw [[NilReferenceException alloc] initWithExpression: @$raw(__VA_ARGS__)]; \
        } \
        (typeof(typeof(*_assert_nonnil_value) *nonnil))_assert_nonnil_value; \
    })
#endif

#define $cast(to, ...) ({\
    __auto_type _val = (__VA_ARGS__); \
    if (not [_val isKindOfClass: [to class]])\
        @throw [OFInvalidArgumentException exception];\
    (typeof(typeof(*_val) *nonnil))_val;\
})


[[clang::objc_root_class]]
@interface NamespaceClass {
    @private Class _isa;
}
+ (Class)self;
+ (Class)class;
@end

#define covariant __covariant
#define contravariant __contravariant

#define namespace(Name)\
    class Name;\
    [[subclassing_restricted, direct_members]]\
    @interface Name : NamespaceClass

#define namespace_implementation(Name) class Name;\
    [[direct_members]]\
    @implementation Name\

[[clang::overloadable]]
static inline OFString *describe(void *ptr)
{ return [OFString stringWithFormat:@"%p", ptr]; }

[[clang::overloadable]]
static inline OFString *describe(const char *str)
{ return @(str); }

[[clang::overloadable]]
static inline OFString *describe(long long num)
{ return [OFString stringWithFormat:@"%lld", num]; }

[[clang::overloadable]]
static inline OFString *describe(double dbl)
{ return [OFString stringWithFormat:@"%g",dbl]; }

[[clang::overloadable]]
static inline OFString *describe(id obj)
{ return [obj description]; }
