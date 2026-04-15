#import "TestSupport.h"

#if !defined(__APPLE__)
#import <ObjFWRT/ObjFWRT.h>
#else
#import <objc/objc.h>
#endif

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncRuntimeUtilitiesTests : OTTestCase @end

@implementation AsyncRuntimeUtilitiesTests

- (void)test_pointer_basic_data_view
{
    int stackValue = 42;
    const void *rawPointer = &stackValue;
    Pointer *pointer = [Pointer from: rawPointer];
    const void *items = pointer.items;
    const void *firstItem = pointer.firstItem;
    const void *lastItem = pointer.lastItem;
    const void *indexedItem = [pointer itemAtIndex: 0];
    bool caughtOutOfRange = false;

    OTAssert((pointer.pointer == rawPointer), @"Pointer.pointer should expose the wrapped pointer value");
    OTAssert((pointer.itemSize == sizeof(void *)), @"Pointer should expose a single pointer-sized item");
    OTAssert((pointer.count == 1), @"Pointer should expose exactly one item");
    OTAssert(([AsyncRuntimeTestSupport pointerValueFromBytes: items] == (uintptr_t)rawPointer), @"Pointer.items should expose the wrapped pointer bytes");
    OTAssert(([AsyncRuntimeTestSupport pointerValueFromBytes: firstItem] == (uintptr_t)rawPointer), @"Pointer.firstItem should expose the wrapped pointer bytes");
    OTAssert(([AsyncRuntimeTestSupport pointerValueFromBytes: lastItem] == (uintptr_t)rawPointer), @"Pointer.lastItem should expose the wrapped pointer bytes");
    OTAssert(([AsyncRuntimeTestSupport pointerValueFromBytes: indexedItem] == (uintptr_t)rawPointer), @"Pointer.itemAtIndex(0) should expose the wrapped pointer bytes");

    @try {
        (void)[pointer itemAtIndex: 1];
    } @catch (OFOutOfRangeException *) {
        caughtOutOfRange = true;
    }

    OTAssert((caughtOutOfRange), @"Pointer.itemAtIndex should reject indexes outside its single item");
}

- (void)test_pointer_nullptr_roundtrip
{
    Pointer *pointer = [Pointer from: nullptr];
    auto mutable_copy = (OFMutableData *)pointer.mutableCopy;

    OTAssert((pointer.pointer == nullptr), @"Pointer should preserve nullptr values");
    OTAssert((pointer.hash == 0), @"Pointer.hash should be zero for nullptr");
    OTAssert(([pointer isEqual: [Pointer from: nullptr]]), @"Pointers wrapping nullptr should compare equal");
    OTAssert(([AsyncRuntimeTestSupport pointerValueFromBytes: $assert_nonnil(pointer.items)] == 0), @"Pointer.items should expose zero bytes for nullptr");
    OTAssert(([AsyncRuntimeTestSupport pointerValueFromBytes: $assert_nonnil(mutable_copy.items)] == 0), @"Pointer.mutableCopy should preserve nullptr bytes");
}

- (void)test_pointer_ordering_and_copying
{
    void *firstBuffer = malloc(1);
    void *secondBuffer = malloc(1);

    OTAssert((firstBuffer != nullptr), @"malloc should allocate the first pointer test buffer");
    OTAssert((secondBuffer != nullptr), @"malloc should allocate the second pointer test buffer");

    @try {
        Pointer *firstPointer = [Pointer from: firstBuffer];
        Pointer *sameFirstPointer = [Pointer from: firstBuffer];
        Pointer *secondPointer = [Pointer from: secondBuffer];
        OFComparisonResult expectedOrdering;
        OFMutableData *mutableCopy;

        if (firstBuffer < secondBuffer)
            expectedOrdering = OFOrderedAscending;
        else if (firstBuffer > secondBuffer)
            expectedOrdering = OFOrderedDescending;
        else
            expectedOrdering = OFOrderedSame;

        OTAssert(([firstPointer compare: secondPointer] == expectedOrdering), @"Pointer.compare should order values by their wrapped pointer");
        OTAssert(([firstPointer isEqual: sameFirstPointer]), @"Pointers wrapping the same address should compare equal");
        OTAssert((not [firstPointer isEqual: secondPointer]), @"Pointers wrapping different addresses should not compare equal");
        OTAssert((firstPointer.copy == firstPointer), @"Pointer.copy should return the same tagged pointer instance");
        OTAssert((firstPointer.hash == (unsigned long)firstBuffer), @"Pointer.hash should be derived from the wrapped pointer value");

        mutableCopy = (OFMutableData *)firstPointer.mutableCopy;
        OTAssert(([mutableCopy isKindOfClass: OFMutableData.class]), @"Pointer.mutableCopy should produce mutable OFData");
        OTAssert(([AsyncRuntimeTestSupport pointerValueFromBytes: $assert_nonnil(mutableCopy.items)] == (uintptr_t)firstBuffer), @"Pointer.mutableCopy should preserve the wrapped pointer bytes");
    } @finally {
        free(firstBuffer);
        free(secondBuffer);
    }
}

- (void)test_pointer_compare_against_plain_data
{
    int stack_value = 99;
    const void *raw_pointer = &stack_value;
    Pointer *pointer = [Pointer from: raw_pointer];
    auto plain_data = [[OFMutableData alloc] initWithItems: &raw_pointer count: 1 itemSize: sizeof(raw_pointer)];

    OTAssert(([pointer compare: plain_data] == OFOrderedDescending), @"Pointer.compare should sort tagged pointers after non-Pointer OFData instances");
    OTAssert((not [pointer isEqual: plain_data]), @"Pointer.isEqual should not treat plain OFData with matching bytes as equal");
}

- (void)test_pointer_string_encoding_and_description
{
    int stackValue = 7;
    const void *rawPointer = &stackValue;
    Pointer *pointer = [Pointer from: rawPointer];
    OFString *pointerString = [OFString stringWithFormat: @"%p", rawPointer];
    OFMutableData *pointerData = (OFMutableData *)pointer.mutableCopy;
    OFString *description = pointer.description;

    OTAssert(([pointer.stringRepresentation isEqual: pointerString]), @"Pointer.stringRepresentation should format the wrapped pointer");
    OTAssert(([pointer.stringByBase64Encoding isEqual: pointerData.stringByBase64Encoding]), @"Pointer.stringByBase64Encoding should match OFData base64 encoding for the pointer bytes");
    OTAssert(([description containsString: pointer.className]), @"Pointer.description should include the class name");
    OTAssert(([description containsString: pointerString]), @"Pointer.description should include the wrapped pointer string");
}

- (void)test_optional_from_nillable_nil_is_none
{
    Optional<OFString *> *none = [Optional none];
    Optional<OFString *> *from_nil = [Optional fromNillable: nilptr];
    auto fallback = [[OFString alloc] initWithUTF8String: "fallback"];
    bool caughtMissingValue = false;

#if !defined(__APPLE__)
    OTAssert((object_isTaggedPointer(none)), @"Optional.none should be a tagged pointer");
    OTAssert((object_isTaggedPointer(from_nil)), @"Optional.fromNillable(nil) should be a tagged pointer");
#endif
    OTAssert((not none.hasValue), @"Optional.none should report no value");
    OTAssert((not from_nil.hasValue), @"Optional.fromNillable(nil) should collapse to none");
    OTAssert(([none isEqual: from_nil]), @"Optional.fromNillable(nil) should compare equal to Optional.none");
    OTAssert((none.hash == from_nil.hash), @"Optional.fromNillable(nil) should hash the same as Optional.none");
    OTAssert(([none valueOr: fallback] == fallback), @"Optional.valueOr should return the fallback for none");
    OTAssert(([from_nil valueOr: fallback] == fallback), @"Optional.fromNillable(nil) should return the fallback because it is none");
    // OTAssert(([from_nil copy] == from_nil), @"Optional.copy should return the tagged pointer instance");

    @try {
        (void)from_nil.value;
    } @catch (OFOutOfRangeException *) {
        caughtMissingValue = true;
    }

    OTAssert((caughtMissingValue), @"Optional.value should reject access when no value is present");
}

- (void)test_optional_roundtrip_equality_and_description
{
    auto value = [OFMutableArray<OFString *> arrayWithObject: @"alpha"];
    auto equal_value = [OFMutableArray<OFString *> arrayWithObject: @"alpha"];
    Optional<OFMutableArray<OFString *> *> *optional = [Optional some: value];
    Optional<OFMutableArray<OFString *> *> *equal_optional = [Optional some: equal_value];
    OFString *description = optional.description;

#if !defined(__APPLE__)
    OTAssert((not object_isTaggedPointer(value)), @"the Optional round-trip test needs a heap object payload");
    OTAssert((not object_isTaggedPointer(optional)), @"Optional.some should retain heap payloads in a heap-backed wrapper");
#endif
    OTAssert((optional.hasValue), @"Optional.some should report a stored value");
    OTAssert((optional.value == value), @"Optional.value should round-trip the wrapped object pointer");
    OTAssert(([optional isEqual: equal_optional]), @"Optional equality should defer to the wrapped values");
    OTAssert((optional.hash == equal_optional.hash), @"Optional.hash should match for equal wrapped values");
    OTAssert(([description containsString: optional.className]), @"Optional.description should include the class name");
    OTAssert(([description containsString: @"alpha"]), @"Optional.description should include the wrapped value description");
}

- (void)test_optional_some_retains_payload_across_autorelease_pool
{
    void *pool = objc_autoreleasePoolPush();
    Optional<OFMutableString *> *optional;

    @try {
        OFMutableString *payload = [OFMutableString stringWithString: @"payload"];
        optional = [Optional some: payload];
    } @finally {
        objc_autoreleasePoolPop(pool);
    }

    OTAssert(optional.hasValue, @"Optional.some should keep values available after an autorelease pool drains");
    OTAssert([optional.value isEqual: @"payload"], @"Optional.some should retain heap payloads strongly enough to survive callback autorelease pools");
}

- (void)test_optional_some_accepts_tagged_payloads
{
    Pointer *tagged_pointer_value = [Pointer from: nullptr];
    Optional<Pointer *> *optional = [Optional some: tagged_pointer_value];
    Optional<Pointer *> *from_nillable = [Optional fromNillable: tagged_pointer_value];
    bool caughtNilArgument = false;
#if !defined(__APPLE__)
    OTAssert((object_isTaggedPointer(tagged_pointer_value)), @"the nested tagged-pointer test needs a tagged pointer payload");
#endif
    @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"
        (void)[Optional some: nilptr];
#pragma clang diagnostic pop
    } @catch (OFInvalidArgumentException *) {
        caughtNilArgument = true;
    }

    OTAssert((caughtNilArgument), @"Optional.some should reject nil because nil maps to none instead");
    OTAssert((optional.hasValue), @"Optional.some should preserve tagged-pointer payloads");
    OTAssert((from_nillable.hasValue), @"Optional.fromNillable should preserve tagged-pointer payloads");
#if !defined(__APPLE__)
    OTAssert((not object_isTaggedPointer(optional)), @"Optional.some should fall back to a heap representation for tagged-pointer payloads it cannot inline");
    OTAssert((not object_isTaggedPointer(from_nillable)), @"Optional.fromNillable should fall back to a heap representation for tagged-pointer payloads it cannot inline");
#endif
    OTAssert((optional.value == tagged_pointer_value), @"Optional.some should round-trip tagged-pointer payload identities");
    OTAssert((from_nillable.value == tagged_pointer_value), @"Optional.fromNillable should round-trip tagged-pointer payload identities");
    OTAssert(([optional isEqual: from_nillable]), @"Optional equality should treat tagged-pointer payloads like any other payload");
    OTAssert((optional.hash == [tagged_pointer_value hash]), @"Optional hash should derive from tagged-pointer payload values");
    // OTAssert((optional.copy == optional), @"Optional.copy should preserve heap-backed optional identity for immutable payload wrappers");
}

- (void)test_application_executable_iri_resolves_to_existing_absolute_file_iri
{
    auto executableIRI = OFApplication.executableIRI;
    auto executablePath = executableIRI.fileSystemRepresentation;
    auto defaultFileManager = [OFFileManager defaultManager];

    OTAssert((executableIRI != nilptr), @"OFApplication.executableIRI should return an IRI for the running test binary");
    OTAssert([($assert_nonnil(executableIRI).scheme) isEqual: @"file"], @"OFApplication.executableIRI should return a file IRI");
    OTAssert((executablePath != nilptr), @"OFApplication.executableIRI should expose a file-system path");
    OTAssert(($assert_nonnil(executablePath).absolutePath), @"OFApplication.executableIRI should resolve to an absolute file-system path");
    OTAssert([defaultFileManager fileExistsAtPath: $assert_nonnil(executablePath)], @"OFApplication.executableIRI should point to an existing file");
    OTAssert(($assert_nonnil(executableIRI).lastPathComponent.length > 0), @"OFApplication.executableIRI should include a final path component");
}

@end
#pragma clang assume_nonnull end
