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

#pragma clang assume_nonnull begin

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
static inline OFString *describe(void *nillable ptr)
{ return [OFString stringWithFormat:@"%p", ptr]; }

[[clang::overloadable]]
static inline OFString *describe(const void *nillable ptr)
{ return [OFString stringWithFormat:@"%p", ptr]; }

[[clang::overloadable]]
static inline OFString *describe(const char *nillable str)
{ return str != NULL ? @((const char *nonnil)str) : @"<null>"; }

[[clang::overloadable]]
static inline OFString *describe(bool value)
{ return value ? @"true" : @"false"; }

[[clang::overloadable]]
static inline OFString *describe(char ch)
{ return [OFString stringWithFormat:@"%c", ch]; }

[[clang::overloadable]]
static inline OFString *describe(signed char num)
{ return [OFString stringWithFormat:@"%hhd", num]; }

[[clang::overloadable]]
static inline OFString *describe(unsigned char num)
{ return [OFString stringWithFormat:@"%hhu", num]; }

[[clang::overloadable]]
static inline OFString *describe(short num)
{ return [OFString stringWithFormat:@"%hd", num]; }

[[clang::overloadable]]
static inline OFString *describe(unsigned short num)
{ return [OFString stringWithFormat:@"%hu", num]; }

[[clang::overloadable]]
static inline OFString *describe(int num)
{ return [OFString stringWithFormat:@"%d", num]; }

[[clang::overloadable]]
static inline OFString *describe(unsigned int num)
{ return [OFString stringWithFormat:@"%u", num]; }

[[clang::overloadable]]
static inline OFString *describe(long num)
{ return [OFString stringWithFormat:@"%ld", num]; }

[[clang::overloadable]]
static inline OFString *describe(unsigned long num)
{ return [OFString stringWithFormat:@"%lu", num]; }

[[clang::overloadable]]
static inline OFString *describe(long long num)
{ return [OFString stringWithFormat:@"%lld", num]; }

[[clang::overloadable]]
static inline OFString *describe(unsigned long long num)
{ return [OFString stringWithFormat:@"%llu", num]; }

[[clang::overloadable]]
static inline OFString *describe(float flt)
{ return [OFString stringWithFormat:@"%g", (double)flt]; }

[[clang::overloadable]]
static inline OFString *describe(double dbl)
{ return [OFString stringWithFormat:@"%g",dbl]; }

[[clang::overloadable]]
static inline OFString *describe(long double dbl)
{ return [OFString stringWithFormat:@"%Lg", dbl]; }

[[clang::overloadable]]
static inline OFString *describe(id nillable obj)
{
    if (obj == nilptr)
        return @"<nil>";

    OFString *nillable description = [obj description];
    return description != nilptr ? $assert_nonnil(description) : @"<nil>";
}

static inline OFString *_AsyncRTFormatFragment(OFString *nillable fragment)
{
    if (fragment == nilptr)
        return @"<nil>";

    return $assert_nonnil(fragment);
}

static inline void _AsyncRTFormatAppendRange(OFMutableString *target,
                                             OFString *format,
                                             size_t start,
                                             size_t end)
{
    if (end <= start)
        return;

    [target appendString: [format substringWithRange: (OFRange){
        .location = start,
        .length = end - start
    }]];
}

static inline OFString *_AsyncRTFormat(OFString *nillable format,
                                       OFArray<OFString *> *arguments)
{
    if (format == nilptr)
        @throw [OFInvalidArgumentException exception];

    OFString *nonnullFormat = $assert_nonnil(format);
    OFMutableString *result = [OFMutableString string];
    size_t length = nonnullFormat.length;
    size_t literalStart = 0;
    size_t argumentIndex = 0;

    for (size_t i = 0; i < length; i++) {
        OFUnichar character = [nonnullFormat characterAtIndex: i];

        if (character == '{') {
            if (i + 1 >= length)
                @throw [OFInvalidFormatException exception];

            OFUnichar next = [nonnullFormat characterAtIndex: i + 1];

            if (next == '{') {
                _AsyncRTFormatAppendRange(result, nonnullFormat, literalStart, i);
                [result appendString: @"{"];
                i++;
                literalStart = i + 1;
                continue;
            }

            if (next != '}')
                @throw [OFInvalidFormatException exception];

            if (argumentIndex >= arguments.count)
                @throw [OFInvalidFormatException exception];

            _AsyncRTFormatAppendRange(result, nonnullFormat, literalStart, i);
            [result appendString: arguments[argumentIndex++]];
            i++;
            literalStart = i + 1;
            continue;
        }

        if (character == '}') {
            if (i + 1 >= length or [nonnullFormat characterAtIndex: i + 1] != '}')
                @throw [OFInvalidFormatException exception];

            _AsyncRTFormatAppendRange(result, nonnullFormat, literalStart, i);
            [result appendString: @"}"];
            i++;
            literalStart = i + 1;
        }
    }

    _AsyncRTFormatAppendRange(result, nonnullFormat, literalStart, length);

    if (argumentIndex != arguments.count)
        @throw [OFInvalidFormatException exception];

    return result;
}

#define _ASYNC_RT_FMT_CAT_IMPL(a, b) a ## b
#define _ASYNC_RT_FMT_CAT(a, b) _ASYNC_RT_FMT_CAT_IMPL(a, b)
#define _ASYNC_RT_FMT_COLLECT_SELECT(count) _ASYNC_RT_FMT_CAT(_ASYNC_RT_FMT_COLLECT_, count)
#define _ASYNC_RT_FMT_COLLECT_ONE(target, value) \
    [(target) addObject: _AsyncRTFormatFragment(describe((value)))]

#define _ASYNC_RT_FMT_ARG_N( \
    _1, _2, _3, _4, _5, _6, _7, _8, \
    _9, _10, _11, _12, _13, _14, _15, _16, \
    _17, _18, _19, _20, _21, _22, _23, _24, \
    _25, _26, _27, _28, _29, _30, _31, _32, N, ...) N
#define _ASYNC_RT_FMT_NARG_(...) _ASYNC_RT_FMT_ARG_N(__VA_ARGS__)
#define _ASYNC_RT_FMT_NARG(...) _ASYNC_RT_FMT_NARG_( \
    __VA_ARGS__, \
    32, 31, 30, 29, 28, 27, 26, 25, \
    24, 23, 22, 21, 20, 19, 18, 17, \
    16, 15, 14, 13, 12, 11, 10, 9, \
    8, 7, 6, 5, 4, 3, 2, 1)

#define _ASYNC_RT_FMT_COLLECT_1(target, a1) \
    _ASYNC_RT_FMT_COLLECT_ONE(target, a1)
#define _ASYNC_RT_FMT_COLLECT_2(target, a1, a2) \
    _ASYNC_RT_FMT_COLLECT_1(target, a1); _ASYNC_RT_FMT_COLLECT_ONE(target, a2)
#define _ASYNC_RT_FMT_COLLECT_3(target, a1, a2, a3) \
    _ASYNC_RT_FMT_COLLECT_2(target, a1, a2); _ASYNC_RT_FMT_COLLECT_ONE(target, a3)
#define _ASYNC_RT_FMT_COLLECT_4(target, a1, a2, a3, a4) \
    _ASYNC_RT_FMT_COLLECT_3(target, a1, a2, a3); _ASYNC_RT_FMT_COLLECT_ONE(target, a4)
#define _ASYNC_RT_FMT_COLLECT_5(target, a1, a2, a3, a4, a5) \
    _ASYNC_RT_FMT_COLLECT_4(target, a1, a2, a3, a4); _ASYNC_RT_FMT_COLLECT_ONE(target, a5)
#define _ASYNC_RT_FMT_COLLECT_6(target, a1, a2, a3, a4, a5, a6) \
    _ASYNC_RT_FMT_COLLECT_5(target, a1, a2, a3, a4, a5); _ASYNC_RT_FMT_COLLECT_ONE(target, a6)
#define _ASYNC_RT_FMT_COLLECT_7(target, a1, a2, a3, a4, a5, a6, a7) \
    _ASYNC_RT_FMT_COLLECT_6(target, a1, a2, a3, a4, a5, a6); _ASYNC_RT_FMT_COLLECT_ONE(target, a7)
#define _ASYNC_RT_FMT_COLLECT_8(target, a1, a2, a3, a4, a5, a6, a7, a8) \
    _ASYNC_RT_FMT_COLLECT_7(target, a1, a2, a3, a4, a5, a6, a7); _ASYNC_RT_FMT_COLLECT_ONE(target, a8)
#define _ASYNC_RT_FMT_COLLECT_9(target, a1, a2, a3, a4, a5, a6, a7, a8, a9) \
    _ASYNC_RT_FMT_COLLECT_8(target, a1, a2, a3, a4, a5, a6, a7, a8); _ASYNC_RT_FMT_COLLECT_ONE(target, a9)
#define _ASYNC_RT_FMT_COLLECT_10(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10) \
    _ASYNC_RT_FMT_COLLECT_9(target, a1, a2, a3, a4, a5, a6, a7, a8, a9); _ASYNC_RT_FMT_COLLECT_ONE(target, a10)
#define _ASYNC_RT_FMT_COLLECT_11(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11) \
    _ASYNC_RT_FMT_COLLECT_10(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10); _ASYNC_RT_FMT_COLLECT_ONE(target, a11)
#define _ASYNC_RT_FMT_COLLECT_12(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12) \
    _ASYNC_RT_FMT_COLLECT_11(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11); _ASYNC_RT_FMT_COLLECT_ONE(target, a12)
#define _ASYNC_RT_FMT_COLLECT_13(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13) \
    _ASYNC_RT_FMT_COLLECT_12(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12); _ASYNC_RT_FMT_COLLECT_ONE(target, a13)
#define _ASYNC_RT_FMT_COLLECT_14(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14) \
    _ASYNC_RT_FMT_COLLECT_13(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13); _ASYNC_RT_FMT_COLLECT_ONE(target, a14)
#define _ASYNC_RT_FMT_COLLECT_15(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15) \
    _ASYNC_RT_FMT_COLLECT_14(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14); _ASYNC_RT_FMT_COLLECT_ONE(target, a15)
#define _ASYNC_RT_FMT_COLLECT_16(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16) \
    _ASYNC_RT_FMT_COLLECT_15(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15); _ASYNC_RT_FMT_COLLECT_ONE(target, a16)
#define _ASYNC_RT_FMT_COLLECT_17(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17) \
    _ASYNC_RT_FMT_COLLECT_16(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16); _ASYNC_RT_FMT_COLLECT_ONE(target, a17)
#define _ASYNC_RT_FMT_COLLECT_18(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18) \
    _ASYNC_RT_FMT_COLLECT_17(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17); _ASYNC_RT_FMT_COLLECT_ONE(target, a18)
#define _ASYNC_RT_FMT_COLLECT_19(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19) \
    _ASYNC_RT_FMT_COLLECT_18(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18); _ASYNC_RT_FMT_COLLECT_ONE(target, a19)
#define _ASYNC_RT_FMT_COLLECT_20(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20) \
    _ASYNC_RT_FMT_COLLECT_19(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19); _ASYNC_RT_FMT_COLLECT_ONE(target, a20)
#define _ASYNC_RT_FMT_COLLECT_21(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21) \
    _ASYNC_RT_FMT_COLLECT_20(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20); _ASYNC_RT_FMT_COLLECT_ONE(target, a21)
#define _ASYNC_RT_FMT_COLLECT_22(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22) \
    _ASYNC_RT_FMT_COLLECT_21(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21); _ASYNC_RT_FMT_COLLECT_ONE(target, a22)
#define _ASYNC_RT_FMT_COLLECT_23(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23) \
    _ASYNC_RT_FMT_COLLECT_22(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22); _ASYNC_RT_FMT_COLLECT_ONE(target, a23)
#define _ASYNC_RT_FMT_COLLECT_24(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24) \
    _ASYNC_RT_FMT_COLLECT_23(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23); _ASYNC_RT_FMT_COLLECT_ONE(target, a24)
#define _ASYNC_RT_FMT_COLLECT_25(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25) \
    _ASYNC_RT_FMT_COLLECT_24(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24); _ASYNC_RT_FMT_COLLECT_ONE(target, a25)
#define _ASYNC_RT_FMT_COLLECT_26(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26) \
    _ASYNC_RT_FMT_COLLECT_25(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25); _ASYNC_RT_FMT_COLLECT_ONE(target, a26)
#define _ASYNC_RT_FMT_COLLECT_27(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27) \
    _ASYNC_RT_FMT_COLLECT_26(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26); _ASYNC_RT_FMT_COLLECT_ONE(target, a27)
#define _ASYNC_RT_FMT_COLLECT_28(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28) \
    _ASYNC_RT_FMT_COLLECT_27(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27); _ASYNC_RT_FMT_COLLECT_ONE(target, a28)
#define _ASYNC_RT_FMT_COLLECT_29(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29) \
    _ASYNC_RT_FMT_COLLECT_28(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28); _ASYNC_RT_FMT_COLLECT_ONE(target, a29)
#define _ASYNC_RT_FMT_COLLECT_30(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30) \
    _ASYNC_RT_FMT_COLLECT_29(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29); _ASYNC_RT_FMT_COLLECT_ONE(target, a30)
#define _ASYNC_RT_FMT_COLLECT_31(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31) \
    _ASYNC_RT_FMT_COLLECT_30(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30); _ASYNC_RT_FMT_COLLECT_ONE(target, a31)
#define _ASYNC_RT_FMT_COLLECT_32(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31, a32) \
    _ASYNC_RT_FMT_COLLECT_31(target, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30, a31); _ASYNC_RT_FMT_COLLECT_ONE(target, a32)

#define $fmt(format, ...) ({ \
    OFMutableArray<OFString *> *_async_rt_fmt_arguments = [OFMutableArray array]; \
    __VA_OPT__(_ASYNC_RT_FMT_COLLECT_SELECT(_ASYNC_RT_FMT_NARG(__VA_ARGS__))(_async_rt_fmt_arguments, __VA_ARGS__);) \
    _AsyncRTFormat((format), _async_rt_fmt_arguments); \
})

#pragma clang assume_nonnull end
