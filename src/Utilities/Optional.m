#include "Optional.h"

#import <ObjFW/ObjFW.h>
#import <ObjFWRT/ObjFWRT.h>
#import <iso646.h>

#pragma clang assume_nonnull begin

static int tagged_pointer_optional_class = -1;

enum : uintptr_t {
    OptionalPayload_NONE = 0x0,
};

@implementation Optional
{
    id _storedValue;
}

- (instancetype)initWithStoredValue: (id)value
{
    self = [super init];
    _storedValue = value;
    return self;
}

+ (void)initialize
{
    if (self == Optional.class)
        tagged_pointer_optional_class = objc_registerTaggedPointerClass(self);
}

+ (instancetype)none
{
    if (tagged_pointer_optional_class < 0)
        @throw [OFInitializationFailedException exceptionWithClass: Optional.class];

    id tagged_pointer = objc_createTaggedPointer(tagged_pointer_optional_class, OptionalPayload_NONE);
    if (tagged_pointer == nilptr)
        @throw [OFInitializationFailedException exceptionWithClass: Optional.class];

    return tagged_pointer;
}

+ (instancetype)some: (id)value
{
    if (value == (id)0)
        @throw [OFInvalidArgumentException exception];

    return [[self alloc] initWithStoredValue: value];
}

+ (instancetype)fromNillable: (id nillable)value
{
    if (value == nilptr)
        return self.none;
    return [self some: $assert_nonnil(value)];
}

- (bool)hasValue
{
    if (not object_isTaggedPointer(self))
        return (_storedValue != nilptr);

    return false;
}

- (id)value
{
    if (not object_isTaggedPointer(self)) {
        if (_storedValue == nilptr)
            @throw [OFOutOfRangeException exception];

        return _storedValue;
    }

    @throw [OFOutOfRangeException exception];
}

- (id)valueOr: (id)fallbackValue
{
    if (fallbackValue == (id)0)
        @throw [OFInvalidArgumentException exception];

    if (not object_isTaggedPointer(self)) {
        if (_storedValue == nilptr)
            return fallbackValue;

        return _storedValue;
    }

    return fallbackValue;
}

- (id)copy
{
    return self;
}

- (unsigned long)hash
{
    if (not object_isTaggedPointer(self)) {
        if (_storedValue == nilptr)
            return 0;

        return [_storedValue hash];
    }

    return 0;
} 

- (bool)isEqual: (id nillable)object
{
    id nillable self_value;
    id nillable other_value;

    if (object == self)
        return true;
    if (not [object isKindOfClass: Optional.class])
        return false;

    if (object_isTaggedPointer(self))
        self_value = nilptr;
    else
        self_value = _storedValue;

    if (object_isTaggedPointer(object))
        other_value = nilptr;
    else
        other_value = ((Optional *)object)->_storedValue;

    if (self_value == other_value)
        return true;
    if (self_value == nilptr or other_value == nilptr)
        return false;

    return [self_value isEqual: other_value];
}

- (OFString *)description
{
    if (not self.hasValue)
        return [OFString stringWithFormat: @"<%@: %p; value = <none>>", self.className, self];

    return [OFString stringWithFormat: @"<%@: %p; value = %@>", self.className, self, self.value];
}

@end

#pragma clang assume_nonnull end
