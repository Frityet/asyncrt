#include <Optional.h>

#import <ObjFW/ObjFW.h>
#if !defined(__APPLE__)
#import <ObjFWRT/ObjFWRT.h>
#else
#import <objc/objc.h>
#endif

#pragma clang assume_nonnull begin

#if !defined(__APPLE__)
static int tagged_pointer_optional_class = -1;

enum : uintptr_t {
    OptionalPayload_NONE = 0x0,
};
#endif

@implementation Optional {
    id _storedValue;
}

- (instancetype)initWithStoredValue: (id nillable)value
{
    self = [super init];
    _storedValue = value;
    return self;
}

#if !defined(__APPLE__)
+ (void)initialize
{
    if (self == Optional.class)
        tagged_pointer_optional_class = objc_registerTaggedPointerClass(self);
}
#endif

+ (instancetype)none
{
    //if (tagged_pointer_optional_class < 0)
    //    @throw [OFInitializationFailedException exceptionWithClass: Optional.class];
#if !defined(__APPLE__)
    id tagged_pointer = objc_createTaggedPointer(tagged_pointer_optional_class, OptionalPayload_NONE);
    if (tagged_pointer == nilptr)
        @throw [OFInitializationFailedException exceptionWithClass: Optional.class];
    return tagged_pointer;
#else
    return [[self alloc] initWithStoredValue: nilptr];
#endif
}

+ (instancetype)some: (id)value
{
    if (not value)
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
#if !defined(__APPLE__)
    if (not object_isTaggedPointer(self))
        return (_storedValue != nilptr);

    return false;
#else
    return _storedValue != nilptr;
#endif
}

- (id)value
{
#if !defined(__APPLE__)
    if (not object_isTaggedPointer(self)) {
        if (_storedValue == nilptr)
            @throw [OFOutOfRangeException exception];
        else
            return _storedValue;
    }

    @throw [OFOutOfRangeException exception];
#else
    if (_storedValue == nilptr)
        @throw [OFOutOfRangeException exception];
    else
        return _storedValue;
#endif
}

- (id)valueOr: (id)fallbackValue
{
    if (not fallbackValue)
        @throw [OFInvalidArgumentException exception];
#if !defined(__APPLE__)
    if (not object_isTaggedPointer(self)) {
        if (_storedValue == nilptr)
            return fallbackValue;
        else
            return _storedValue;
    }

    return fallbackValue;
#else
    if (_storedValue == nilptr)
        return fallbackValue;
    else
        return _storedValue;
#endif
}

- (unsigned long)hash
{
#if !defined(__APPLE__)
    if (not object_isTaggedPointer(self)) {
        if (_storedValue == nilptr)
            return 0;

        return [_storedValue hash];
    }

    return 0;
#else
    if (_storedValue == nilptr)
        return 0;
    else
        return [_storedValue hash];
#endif
} 

- (bool)isEqual: (id nillable)object
{
    id nillable self_value;
    id nillable other_value;

    if (object == self)
        return true;

#if !defined(__APPLE__)
    if (object_isTaggedPointer(self))
        self_value = nilptr;
    else
        self_value = _storedValue;
#else
    self_value = _storedValue;
#endif

    if (self_value != nilptr) {
        if (self_value == object)
            return true;
        if (object != nilptr and [self_value isEqual: object])
            return true;
    }

    if (not [object isKindOfClass: Optional.class])
        return false;

#if !defined(__APPLE__)
    if (object_isTaggedPointer(object))
        other_value = nilptr;
    else
        other_value = ((Optional *)object)->_storedValue;
#else
    other_value = ((Optional *)object)->_storedValue;
#endif

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
