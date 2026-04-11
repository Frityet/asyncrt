#include "Pointer.h"

#import <ObjFW/ObjFW.h>
#if !defined(__APPLE__)
#import <ObjFWRT/ObjFWRT.h>
#else
#import <objc/objc.h>
#endif
#import <string.h>
#import <iso646.h>

//static int tagged_pointer_data_class = -1;
//static thread_local uintptr_t tagged_pointer_item_buffer;

@implementation Pointer

#if defined(__APPLE__)

+ (instancetype)pointer: (const void *nillable)pointer
{
     return [super dataWithItems: &pointer count: 1 itemSize: sizeof(void *)];
}

- (const void *nillable)pointer
{ return (const void *)*(const void **)self.items; }

#else
static int tagged_pointer_data_class = -1;
static thread_local uintptr_t tagged_pointer_item_buffer;

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

- (size_t)itemSize
{
    return sizeof(void *);
}

- (size_t)count
{
    return 1;
}

- (const void *)items
{
    tagged_pointer_item_buffer = (uintptr_t)self.pointer;
    return &tagged_pointer_item_buffer;
}

- (const void *)firstItem
{
    const void *items = self.items;
    return items != nullptr ? items : nullptr;
}

- (const void *)lastItem
{
    const void *items = self.items;
    return items != nullptr ? items : nullptr;
}

- (OFString *)stringRepresentation
{
    return [OFString stringWithFormat: @"%p", self.pointer];
}

- (OFString *)stringByBase64Encoding
{
    char buffer[sizeof(void *) * 4 / 3 + 4] = {0};
    {
        auto pointer_bytes = (const uint8_t *)&(const uint8_t *){self.pointer};
        size_t idx = 0;
        for (size_t i = 0; i < sizeof(void *); i += 3) {
            uint32_t chunk = 0;
            size_t chunk_size = 0;
            for (size_t j = 0; j < 3 and i + j < sizeof(void *); j++) {
                chunk |= ((uint32_t)pointer_bytes[i + j]) << (16 - j * 8);
                chunk_size++;
            }
            for (size_t k = 0; k < (chunk_size + 1); k++) {
                uint8_t index = (chunk >> (18 - k * 6)) & 0x3F;
                buffer[idx++] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"[index];
            }
        }
        while (idx % 4 != 0) {
            buffer[idx++] = '=';
        }
    }
    return [OFString stringWithUTF8String: buffer];
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

    const void *items = self.items;
    if (items == nullptr)
        @throw [[OFOutOfRangeException alloc] init];

    return items;
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
    if (not [object isKindOfClass: OFData.class])
        return false;

    if ([object isKindOfClass: Pointer.class])
        return self.pointer == ((Pointer *)object).pointer;

    // TODO: maybe?
    return false;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"<%@: %p; pointer = %p>", self.className, self, self.pointer];
}
#endif

@end
