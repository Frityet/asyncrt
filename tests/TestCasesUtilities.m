#import "TestSupport.h"
#import <ObjFWRT/ObjFWRT.h>

#pragma clang assume_nonnull begin

static void signal_change_notifications(void)
{
    auto signal = [Signal withValue: nilptr];
    auto events = [OFMutableArray<OFString *> array];

    [signal subscribe: ^(OFString *value) {
        OFString *nillable maybe_value = value;
        OFString *event_value = @"<nil>";
        if (maybe_value != nilptr)
            event_value = $assert_nonnil(maybe_value);
        [events addObject: event_value];
    }];
    [signal subscribe: ^(OFString *value) {
        OFString *nillable maybe_value = value;
        OFString *event_value = @"<nil>";
        if (maybe_value != nilptr)
            event_value = $assert_nonnil(maybe_value);
        [events addObject: [OFString stringWithFormat: @"second:%@", event_value]];
    }];

    signal.value = nilptr;
    signal.value = @"alpha";
    signal.value = @"alpha";
    signal.value = @"beta";

    [AsyncRuntimeTestSupport assertCondition: (events.count == 4) message: (@"Signal should only notify subscribers when the value actually changes")];
    [AsyncRuntimeTestSupport assertCondition: ([events[0] isEqual: @"alpha"]) message: (@"Signal should publish the changed value to the first subscriber")];
    [AsyncRuntimeTestSupport assertCondition: ([events[1] isEqual: @"second:alpha"]) message: (@"Signal should notify subscribers in subscription order")];
    [AsyncRuntimeTestSupport assertCondition: ([events[2] isEqual: @"beta"]) message: (@"Signal should publish later value changes")];
    [AsyncRuntimeTestSupport assertCondition: ([events[3] isEqual: @"second:beta"]) message: (@"Signal should notify every subscriber for later changes")];
}

static void signal_equal_objects_suppress_notifications(void)
{
    auto signal = [Signal withValue: nilptr];
    block_reference size_t change_count = 0;
    auto first_value = [[OFString alloc] initWithUTF8String: "same"];
    auto second_value = [[OFString alloc] initWithUTF8String: "same"];

    [signal subscribe: ^(OFString *value) {
        (void)value;
        change_count++;
    }];

    signal.value = first_value;
    signal.value = second_value;

    [AsyncRuntimeTestSupport assertCondition: ([first_value isEqual: second_value]) message: (@"the signal equality test needs two distinct but equal values")];
    [AsyncRuntimeTestSupport assertCondition: (change_count == 1) message: (@"Signal should suppress notifications when the new value compares equal to the old value")];
}

static void computed_recomputes_each_access(void)
{
    block_reference size_t computeCount = 0;
    Computed<OFString *> *computed = [Computed withBlock: ^OFString * {
        computeCount++;
        return [OFString stringWithFormat: @"value-%zu", computeCount];
    }];

    [AsyncRuntimeTestSupport assertCondition: ([computed.value isEqual: @"value-1"]) message: (@"Computed should evaluate its block on the first access")];
    [AsyncRuntimeTestSupport assertCondition: ([computed.value isEqual: @"value-2"]) message: (@"Computed should re-evaluate its block on later accesses")];
    [AsyncRuntimeTestSupport assertCondition: (computeCount == 2) message: (@"Computed should not cache across value accesses")];
}

static void mutex_scoped_lock_unlocks_on_exception(void)
{
    auto lock = [OFMutex mutex];
    bool caughtException = false;
    bool lockWasReleased = false;

    @try {
        [lock scopedLock: ^{
            @throw [[TestRejectionException alloc] init];
        }];
    } @catch (TestRejectionException *unusedException) {
        (void)unusedException;
        caughtException = true;
    }

    [lock lock];
    @try {
        lockWasReleased = true;
    } @finally {
        [lock unlock];
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtException) message: (@"scopedLock should rethrow the block exception")];
    [AsyncRuntimeTestSupport assertCondition: (lockWasReleased) message: (@"scopedLock should always release the lock in @finally")];
}

static void pointer_basic_data_view(void)
{
    int stackValue = 42;
    const void *rawPointer = &stackValue;
    auto pointer = [Pointer pointer: rawPointer];
    const void *items = pointer.items;
    const void *firstItem = pointer.firstItem;
    const void *lastItem = pointer.lastItem;
    const void *indexedItem = [pointer itemAtIndex: 0];
    bool caughtOutOfRange = false;

    [AsyncRuntimeTestSupport assertCondition: (pointer.pointer == rawPointer) message: (@"Pointer.pointer should expose the wrapped pointer value")];
    [AsyncRuntimeTestSupport assertCondition: (pointer.itemSize == sizeof(void *)) message: (@"Pointer should expose a single pointer-sized item")];
    [AsyncRuntimeTestSupport assertCondition: (pointer.count == 1) message: (@"Pointer should expose exactly one item")];
    [AsyncRuntimeTestSupport assertCondition: ([AsyncRuntimeTestSupport pointerValueFromBytes: items] == (uintptr_t)rawPointer) message: (@"Pointer.items should expose the wrapped pointer bytes")];
    [AsyncRuntimeTestSupport assertCondition: ([AsyncRuntimeTestSupport pointerValueFromBytes: firstItem] == (uintptr_t)rawPointer) message: (@"Pointer.firstItem should expose the wrapped pointer bytes")];
    [AsyncRuntimeTestSupport assertCondition: ([AsyncRuntimeTestSupport pointerValueFromBytes: lastItem] == (uintptr_t)rawPointer) message: (@"Pointer.lastItem should expose the wrapped pointer bytes")];
    [AsyncRuntimeTestSupport assertCondition: ([AsyncRuntimeTestSupport pointerValueFromBytes: indexedItem] == (uintptr_t)rawPointer) message: (@"Pointer.itemAtIndex(0) should expose the wrapped pointer bytes")];

    @try {
        (void)[pointer itemAtIndex: 1];
    } @catch (OFOutOfRangeException *unusedException) {
        (void)unusedException;
        caughtOutOfRange = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtOutOfRange) message: (@"Pointer.itemAtIndex should reject indexes outside its single item")];
}

static void pointer_nullptr_roundtrip(void)
{
    auto pointer = [Pointer pointer: nullptr];
    auto mutable_copy = (OFMutableData *)pointer.mutableCopy;

    [AsyncRuntimeTestSupport assertCondition: (pointer.pointer == nullptr) message: (@"Pointer should preserve nullptr values")];
    [AsyncRuntimeTestSupport assertCondition: (pointer.hash == 0) message: (@"Pointer.hash should be zero for nullptr")];
    [AsyncRuntimeTestSupport assertCondition: ([pointer isEqual: [Pointer pointer: nullptr]]) message: (@"Pointers wrapping nullptr should compare equal")];
    [AsyncRuntimeTestSupport assertCondition: ([AsyncRuntimeTestSupport pointerValueFromBytes: $assert_nonnil(pointer.items)] == 0) message: (@"Pointer.items should expose zero bytes for nullptr")];
    [AsyncRuntimeTestSupport assertCondition: ([AsyncRuntimeTestSupport pointerValueFromBytes: $assert_nonnil(mutable_copy.items)] == 0) message: (@"Pointer.mutableCopy should preserve nullptr bytes")];
}

static void pointer_ordering_and_copying(void)
{
    void *firstBuffer = malloc(1);
    void *secondBuffer = malloc(1);

    [AsyncRuntimeTestSupport assertCondition: (firstBuffer != nullptr) message: (@"malloc should allocate the first pointer test buffer")];
    [AsyncRuntimeTestSupport assertCondition: (secondBuffer != nullptr) message: (@"malloc should allocate the second pointer test buffer")];

    @try {
        Pointer *firstPointer = [Pointer pointer: firstBuffer];
        Pointer *sameFirstPointer = [Pointer pointer: firstBuffer];
        Pointer *secondPointer = [Pointer pointer: secondBuffer];
        OFComparisonResult expectedOrdering;
        OFMutableData *mutableCopy;

        if (firstBuffer < secondBuffer)
            expectedOrdering = OFOrderedAscending;
        else if (firstBuffer > secondBuffer)
            expectedOrdering = OFOrderedDescending;
        else
            expectedOrdering = OFOrderedSame;

        [AsyncRuntimeTestSupport assertCondition: ([firstPointer compare: secondPointer] == expectedOrdering) message: (@"Pointer.compare should order values by their wrapped pointer")];
        [AsyncRuntimeTestSupport assertCondition: ([firstPointer isEqual: sameFirstPointer]) message: (@"Pointers wrapping the same address should compare equal")];
        [AsyncRuntimeTestSupport assertCondition: (not [firstPointer isEqual: secondPointer]) message: (@"Pointers wrapping different addresses should not compare equal")];
        [AsyncRuntimeTestSupport assertCondition: (firstPointer.copy == firstPointer) message: (@"Pointer.copy should return the same tagged pointer instance")];
        [AsyncRuntimeTestSupport assertCondition: (firstPointer.hash == (unsigned long)firstBuffer) message: (@"Pointer.hash should be derived from the wrapped pointer value")];

        mutableCopy = (OFMutableData *)firstPointer.mutableCopy;
        [AsyncRuntimeTestSupport assertCondition: ([mutableCopy isKindOfClass: OFMutableData.class]) message: (@"Pointer.mutableCopy should produce mutable OFData")];
        [AsyncRuntimeTestSupport assertCondition: ([AsyncRuntimeTestSupport pointerValueFromBytes: $assert_nonnil(mutableCopy.items)] == (uintptr_t)firstBuffer) message: (@"Pointer.mutableCopy should preserve the wrapped pointer bytes")];
    } @finally {
        free(firstBuffer);
        free(secondBuffer);
    }
}

static void pointer_compare_against_plain_data(void)
{
    int stack_value = 99;
    const void *raw_pointer = &stack_value;
    auto pointer = [Pointer pointer: raw_pointer];
    auto plain_data = [[OFMutableData alloc] initWithItems: &raw_pointer count: 1 itemSize: sizeof(raw_pointer)];

    [AsyncRuntimeTestSupport assertCondition: ([pointer compare: plain_data] == OFOrderedDescending) message: (@"Pointer.compare should sort tagged pointers after non-Pointer OFData instances")];
    [AsyncRuntimeTestSupport assertCondition: (not [pointer isEqual: plain_data]) message: (@"Pointer.isEqual should not treat plain OFData with matching bytes as equal")];
}

static void pointer_string_encoding_and_description(void)
{
    int stackValue = 7;
    const void *rawPointer = &stackValue;
    Pointer *pointer = [Pointer pointer: rawPointer];
    OFString *pointerString = [OFString stringWithFormat: @"%p", rawPointer];
    OFMutableData *pointerData = (OFMutableData *)pointer.mutableCopy;
    OFString *description = pointer.description;

    [AsyncRuntimeTestSupport assertCondition: ([pointer.stringRepresentation isEqual: pointerString]) message: (@"Pointer.stringRepresentation should format the wrapped pointer")];
    [AsyncRuntimeTestSupport assertCondition: ([pointer.stringByBase64Encoding isEqual: pointerData.stringByBase64Encoding]) message: (@"Pointer.stringByBase64Encoding should match OFData base64 encoding for the pointer bytes")];
    [AsyncRuntimeTestSupport assertCondition: ([description containsString: pointer.className]) message: (@"Pointer.description should include the class name")];
    [AsyncRuntimeTestSupport assertCondition: ([description containsString: pointerString]) message: (@"Pointer.description should include the wrapped pointer string")];
}

static void optional_from_nillable_nil_is_none(void)
{
    Optional<OFString *> *none = [Optional none];
    Optional<OFString *> *from_nil = [Optional fromNillable: nilptr];
    OFString *fallback = [[OFString alloc] initWithUTF8String: "fallback"];
    bool caughtMissingValue = false;

    [AsyncRuntimeTestSupport assertCondition: (object_isTaggedPointer(none)) message: (@"Optional.none should be a tagged pointer")];
    [AsyncRuntimeTestSupport assertCondition: (object_isTaggedPointer(from_nil)) message: (@"Optional.fromNillable(nil) should be a tagged pointer")];
    [AsyncRuntimeTestSupport assertCondition: (not none.hasValue) message: (@"Optional.none should report no value")];
    [AsyncRuntimeTestSupport assertCondition: (not from_nil.hasValue) message: (@"Optional.fromNillable(nil) should collapse to none")];
    [AsyncRuntimeTestSupport assertCondition: ([none isEqual: from_nil]) message: (@"Optional.fromNillable(nil) should compare equal to Optional.none")];
    [AsyncRuntimeTestSupport assertCondition: (none.hash == from_nil.hash) message: (@"Optional.fromNillable(nil) should hash the same as Optional.none")];
    [AsyncRuntimeTestSupport assertCondition: ([none valueOr: fallback] == fallback) message: (@"Optional.valueOr should return the fallback for none")];
    [AsyncRuntimeTestSupport assertCondition: ([from_nil valueOr: fallback] == fallback) message: (@"Optional.fromNillable(nil) should return the fallback because it is none")];
    [AsyncRuntimeTestSupport assertCondition: ([from_nil copy] == from_nil) message: (@"Optional.copy should return the tagged pointer instance")];

    @try {
        (void)from_nil.value;
    } @catch (OFOutOfRangeException *unusedException) {
        (void)unusedException;
        caughtMissingValue = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtMissingValue) message: (@"Optional.value should reject access when no value is present")];
}

static void optional_roundtrip_equality_and_description(void)
{
    auto value = [OFMutableArray<OFString *> arrayWithObject: @"alpha"];
    auto equal_value = [OFMutableArray<OFString *> arrayWithObject: @"alpha"];
    Optional<OFMutableArray<OFString *> *> *optional = [Optional some: value];
    Optional<OFMutableArray<OFString *> *> *equal_optional = [Optional some: equal_value];
    OFString *description = optional.description;

    [AsyncRuntimeTestSupport assertCondition: (not object_isTaggedPointer(value)) message: (@"the Optional round-trip test needs a heap object payload")];
    [AsyncRuntimeTestSupport assertCondition: (not object_isTaggedPointer(optional)) message: (@"Optional.some should retain heap payloads in a heap-backed wrapper")];
    [AsyncRuntimeTestSupport assertCondition: (optional.hasValue) message: (@"Optional.some should report a stored value")];
    [AsyncRuntimeTestSupport assertCondition: (optional.value == value) message: (@"Optional.value should round-trip the wrapped object pointer")];
    [AsyncRuntimeTestSupport assertCondition: ([optional isEqual: equal_optional]) message: (@"Optional equality should defer to the wrapped values")];
    [AsyncRuntimeTestSupport assertCondition: (optional.hash == equal_optional.hash) message: (@"Optional.hash should match for equal wrapped values")];
    [AsyncRuntimeTestSupport assertCondition: ([description containsString: optional.className]) message: (@"Optional.description should include the class name")];
    [AsyncRuntimeTestSupport assertCondition: ([description containsString: @"alpha"]) message: (@"Optional.description should include the wrapped value description")];
}

static void optional_some_retains_payload_across_autorelease_pool(void)
{
    void *pool = objc_autoreleasePoolPush();
    Optional<OFMutableString *> *optional;

    @try {
        OFMutableString *payload = [OFMutableString stringWithString: @"payload"];
        optional = [Optional some: payload];
    } @finally {
        objc_autoreleasePoolPop(pool);
    }

    [AsyncRuntimeTestSupport assertCondition: optional.hasValue
                                    message: (@"Optional.some should keep values available after an autorelease pool drains")];
    [AsyncRuntimeTestSupport assertCondition: [optional.value isEqual: @"payload"]
                                    message: (@"Optional.some should retain heap payloads strongly enough to survive callback autorelease pools")];
}

static void optional_some_accepts_tagged_payloads(void)
{
    Pointer *tagged_pointer_value = [Pointer pointer: nullptr];
    Optional<Pointer *> *optional = [Optional some: tagged_pointer_value];
    Optional<Pointer *> *from_nillable = [Optional fromNillable: tagged_pointer_value];
    bool caughtNilArgument = false;

    [AsyncRuntimeTestSupport assertCondition: (object_isTaggedPointer(tagged_pointer_value)) message: (@"the nested tagged-pointer test needs a tagged pointer payload")];

    @try {
        (void)[Optional some: nilptr];
    } @catch (OFInvalidArgumentException *unusedException) {
        (void)unusedException;
        caughtNilArgument = true;
    }

    [AsyncRuntimeTestSupport assertCondition: (caughtNilArgument) message: (@"Optional.some should reject nil because nil maps to none instead")];
    [AsyncRuntimeTestSupport assertCondition: (optional.hasValue) message: (@"Optional.some should preserve tagged-pointer payloads")];
    [AsyncRuntimeTestSupport assertCondition: (from_nillable.hasValue) message: (@"Optional.fromNillable should preserve tagged-pointer payloads")];
    [AsyncRuntimeTestSupport assertCondition: (not object_isTaggedPointer(optional)) message: (@"Optional.some should fall back to a heap representation for tagged-pointer payloads it cannot inline")];
    [AsyncRuntimeTestSupport assertCondition: (not object_isTaggedPointer(from_nillable)) message: (@"Optional.fromNillable should fall back to a heap representation for tagged-pointer payloads it cannot inline")];
    [AsyncRuntimeTestSupport assertCondition: (optional.value == tagged_pointer_value) message: (@"Optional.some should round-trip tagged-pointer payload identities")];
    [AsyncRuntimeTestSupport assertCondition: (from_nillable.value == tagged_pointer_value) message: (@"Optional.fromNillable should round-trip tagged-pointer payload identities")];
    [AsyncRuntimeTestSupport assertCondition: ([optional isEqual: from_nillable]) message: (@"Optional equality should treat tagged-pointer payloads like any other payload")];
    [AsyncRuntimeTestSupport assertCondition: (optional.hash == [tagged_pointer_value hash]) message: (@"Optional hash should derive from tagged-pointer payload values")];
    [AsyncRuntimeTestSupport assertCondition: (optional.copy == optional) message: (@"Optional.copy should preserve heap-backed optional identity for immutable payload wrappers")];
}

ASYNC_RUNTIME_SYNC_TEST(signal_change_notifications)
ASYNC_RUNTIME_SYNC_TEST(signal_equal_objects_suppress_notifications)
ASYNC_RUNTIME_SYNC_TEST(computed_recomputes_each_access)
ASYNC_RUNTIME_SYNC_TEST(mutex_scoped_lock_unlocks_on_exception)
ASYNC_RUNTIME_SYNC_TEST(pointer_basic_data_view)
ASYNC_RUNTIME_SYNC_TEST(pointer_nullptr_roundtrip)
ASYNC_RUNTIME_SYNC_TEST(pointer_ordering_and_copying)
ASYNC_RUNTIME_SYNC_TEST(pointer_compare_against_plain_data)
ASYNC_RUNTIME_SYNC_TEST(pointer_string_encoding_and_description)
ASYNC_RUNTIME_SYNC_TEST(optional_from_nillable_nil_is_none)
ASYNC_RUNTIME_SYNC_TEST(optional_roundtrip_equality_and_description)
ASYNC_RUNTIME_SYNC_TEST(optional_some_retains_payload_across_autorelease_pool)
ASYNC_RUNTIME_SYNC_TEST(optional_some_accepts_tagged_payloads)

#pragma clang assume_nonnull end
