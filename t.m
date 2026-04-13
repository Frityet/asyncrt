#import <ObjFW/ObjFW.h>

@interface Person : OFObject

@property(readonly) OFString *name;
@property(readonly) OFString *greeting;

- (instancetype)initWithName: (OFString *)name greeting: (OFString *)greeting;

- (void)greetPerson: (Person *)otherPerson;

@end

@implementation Person

- (instancetype)initWithName: (OFString *)name greeting: (OFString *)greeting
{
    self = [super init];
    _name = name;
    _greeting = greeting;
    return self;
}

- (void)greetPerson: (Person *)otherPerson
{
    [OFStdOut writeFormat: @"%@ says %@, %@!", self.name, self.greeting, otherPerson.name];
}
@end

int main()
{
    Person *alice = [[Person alloc] initWithName: @"Alice" greeting: @"Hello"];
    Person *bob = [[Person alloc] initWithName: @"Bob" greeting: @"Hi"];
    [alice greetPerson: bob];
    [bob greetPerson: alice];
}
