#import<ObjFW/ObjFW.h>
@protocol MyProto @end

@interface MyClass : OFObject
@property(nonatomic) OFString<MyProto> *text;
@end

@implementation MyClass
@end

static void dump_prop(Class cls, const char *name)
{
    objc_property_t prop = class_getProperty(cls, name);
    if (!prop) {
        printf("property not found\n");
        return;
    }

    const char *attrs = property_getAttributes(prop);
    char *type = property_copyAttributeValue(prop, "T");

    printf("property_getAttributes: %s\n", attrs);
    printf("T attribute:            %s\n", type);

    free(type);
}

int main(void)
{
    @autoreleasepool {
        dump_prop(MyClass.class, "text");
    }
    return 0;
}