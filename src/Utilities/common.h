#pragma once

#import <ObjFW/ObjFW.h>
#include <iso646.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdatomic.h>

#define nonnil _Nonnull
#define nillable _Nullable
#define nullptr ((void *nillable)0)
#define nilptr ((id nillable)0)

#define block_reference __block
#define unretained __unsafe_unretained
#define unretained_cast __bridge
#define retained_cast __bridge_retained
#define designated_initailiser clang::objc_designated_initializer

#if defined(ASYNC_RUNTIME_TEST_BUILD)
#   define direct clang::annotate("async_runtime_test_attribute")
#   define direct_members clang::annotate("async_runtime_test_attribute")
#   define subclassing_restricted clang::annotate("async_runtime_test_attribute")
#else
#   define direct clang::objc_direct
#   define direct_members clang::objc_direct_members
#   define subclassing_restricted clang::objc_subclassing_restricted
#endif
#if !defined(__cplusplus)
#   define auto __auto_type
#endif

#define atomic_t(...) _Atomic(__VA_ARGS__)

#define $as_nonnil(...) (__builtin_assume((__VA_ARGS__) != nilptr), (typeof(typeof(*(__VA_ARGS__)) *nonnil))(__VA_ARGS__))
#if defined(NDEBUG)
#   define $assert_nonnil(...) $as_nonnil(__VA_ARGS__)
#else
#   define $assert_nonnil(...) ({ \
        __auto_type _assert_nonnil_value = (__VA_ARGS__); \
        if (OF_UNLIKELY(_assert_nonnil_value == nilptr)) { \
            @throw [OFInvalidArgumentException exception]; \
        } \
        (typeof(typeof(*_assert_nonnil_value) *nonnil))_assert_nonnil_value; \
    })
#endif


[[clang::objc_root_class]]
@interface NamespaceClass {
    @private Class _isa;
}
+ (Class)self;
+ (Class)class;
@end

#define namespace(Name)\
    class Name;\
    [[subclassing_restricted, direct_members]]\
    @interface Name : NamespaceClass

#define namespace_implementation(Name) class Name;\
    @implementation Name\

#import "Utilities/OFApplication+ExecutableIRI.h"
