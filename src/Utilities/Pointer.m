#include "Pointer.h"

#import <ObjFW/ObjFW.h>
#if !defined(__APPLE__)
#import <ObjFWRT/ObjFWRT.h>
#else
#import <objc/objc.h>
#endif
#import <iso646.h>

#if !defined(__APPLE__)
static int tagged_pointer_data_class = -1;
static thread_local uintptr_t tagged_pointer_item_buffer;
#endif

@implementation Pointer {
#if defined(__APPLE__)
    uintptr_t _pointerValue;
#endif
}

#if defined(__APPLE__)

- (instancetype)initWithPointer: (const void *nillable)pointer
{
    self = [super init];
    _pointerValue = (uintptr_t)pointer;
    return self;
}

+ (instancetype)from: (const void *nillable)pointer
{
    return [[self alloc] initWithPointer: pointer];
}

- (const void *nillable)pointer
{
    return (const void *)_pointerValue;
}

- (const void *nillable)items
{
    return &_pointerValue;
}

#else

+ (void)initialize
{
    if (self == Pointer.class)
        tagged_pointer_data_class = objc_registerTaggedPointerClass(self);
}

+ (instancetype)pointer: (const void *nillable)pointer
{
    if (tagged_pointer_data_class < 0)
        @throw [OFInitializationFailedException exceptionWithClass: Pointer.class];

    id tagged_pointer = objc_createTaggedPointer(tagged_pointer_data_class, ((uintptr_t)pointer) ^ 1);
    if (not tagged_pointer)
        @throw [OFInitializationFailedException exceptionWithClass: Pointer.class];

    return tagged_pointer;
}

- (const void *nillable)pointer
{ return (const void *)(object_getTaggedPointerValue(self) ^ 1); }

- (const void *nillable)items
{
    tagged_pointer_item_buffer = (uintptr_t)self.pointer;
    return &tagged_pointer_item_buffer;
}
#endif

- (size_t)itemSize
{
    return sizeof(void *);
}

- (size_t)count
{
    return 1;
}

- (const void *nillable)firstItem
{
    return self.items;
}

- (const void *nillable)lastItem
{
    return self.items;
}

- (OFString *)stringRepresentation
{
    return [OFString stringWithFormat: @"%p", self.pointer];
}


- (OFString *)stringByBase64Encoding
{
    char output[12];
    {
        const unsigned char *inputBytes = (const unsigned char *)&_pointerValue;
        size_t inputLength = sizeof(_pointerValue);

        static const char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        size_t outputIndex = 0;

        for (size_t i = 0; i < inputLength; i += 3) {
            uint32_t buffer = 0;
            size_t bytesToProcess = (i + 3 <= inputLength) ? 3 : (inputLength - i);

            for (size_t j = 0; j < bytesToProcess; j++) {
                buffer <<= 8;
                buffer |= inputBytes[i + j];
            }
            buffer <<= (3 - bytesToProcess) * 8;

            for (size_t j = 0; j < 4; j++) {
                if (j <= bytesToProcess) {
                    output[outputIndex++] = encodingTable[(buffer >> (18 - j * 6)) & 0x3F];
                } else {
                    output[outputIndex++] = '=';
                }
            }
        }
    }

    return [OFString stringWithCString: output encoding: OFStringEncodingUTF8 length: 12];
}

- (OFComparisonResult)compare: (OFData *)data
{
    if (not [data isKindOfClass: Pointer.class])
        return OFOrderedDescending;

    const void *self_pointer = self.pointer,
                *other_pointer = ((Pointer *)data).pointer;

    if (self_pointer < other_pointer)
        return OFOrderedAscending;
    else if (self_pointer > other_pointer)
        return OFOrderedDescending;
    else
        return OFOrderedSame;
}

- (const void *)itemAtIndex: (size_t)index
{
    if (index != 0)
        @throw [[OFOutOfRangeException alloc] init];

    return $assert_nonnil(self.items);
}

- (id)copy
{ return self; }

- (id)mutableCopy
{
    uintptr_t pointer_value = (uintptr_t)self.pointer;
    return [[OFMutableData alloc] initWithItems: &pointer_value count: 1 itemSize: sizeof(pointer_value)];
}

- (unsigned long)hash
{
    return (unsigned long)self.pointer;
}

- (bool)isEqual: (id)object
{
    if (object == self)
        return true;
    // if (not [object isKindOfClass: OFData.class])
    //     return false;

    if ([object isKindOfClass: Pointer.class])
        return self.pointer == ((Pointer *)object).pointer;

    return self->_pointerValue == (uintptr_t)object;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"<%@: %p; pointer = %p>", self.className, self, self.pointer];
}

@end
