#import <AsyncRT/Database/AsyncDBProvider.h>

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncDBProviderRegistration : OFObject

@property(readonly, assign, nonatomic) Class<AsyncDBProvider> implementation;
@property(readonly, copy, nonatomic) OFString *name;
@property(readonly, copy, nonatomic) OFArray<OFString *> *schemes;

+ (instancetype)registrationWithImplementation: (Class<AsyncDBProvider>)implementation;
- (instancetype)initWithImplementation: (Class<AsyncDBProvider>)implementation [[designated_initailiser]];
- (bool)matchesName: (OFString *)providerName;
- (bool)supportsScheme: (OFString *)scheme;
- (id<AsyncDBConnection>)connectionWithIRI: (OFIRI *)IRI options: (AsyncDBConnectionOptions *)options;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface AsyncDBProviderRegistry () {
    OFMutableArray<AsyncDBProviderRegistration *> *_registrations;
}

- (AsyncDBProviderRegistration *)_registrationForImplementation: (Class<AsyncDBProvider>)implementation;
- (AsyncDBProviderRegistration *)_registrationNamed: (OFString *)providerName;
- (AsyncDBProviderRegistration *)_registrationForScheme: (OFString *)scheme;

@end

@implementation AsyncDBProviderRegistration

+ (instancetype)registrationWithImplementation: (Class<AsyncDBProvider>)implementation
{ return [[self alloc] initWithImplementation: implementation]; }

- (instancetype)initWithImplementation: (Class<AsyncDBProvider>)implementation
{
    self = [super init];
    _implementation = implementation;
    _name = [[implementation dbProviderName] copy];
    _schemes = [[implementation dbProviderSchemes] copy];
    return self;
}

- (bool)matchesName: (OFString *)providerName
{
    return [_name isEqual: providerName];
}

- (bool)supportsScheme: (OFString *)scheme
{
    for (OFString *providerScheme in _schemes) {
        if ([providerScheme isEqual: scheme])
            return true;
    }

    return false;
}

- (id<AsyncDBConnection>)connectionWithIRI: (OFIRI *)IRI options: (AsyncDBConnectionOptions *)options
{ return [_implementation dbConnectionWithIRI: IRI options: options]; }

@end

@implementation AsyncDBProviderRegistry

+ (instancetype)registry
{ return [[self alloc] init]; }

+ (instancetype)registryWithProviderClass: (Class<AsyncDBProvider>)providerClass
{
    auto registry = [self registry];
    [registry registerProviderClass: providerClass];
    return registry;
}

- (instancetype)init
{
    self = [super init];
    _registrations = [[OFMutableArray alloc] init];
    return self;
}

- (void)registerProviderClass: (Class<AsyncDBProvider>)providerClass
{
    if (providerClass == Nil)
        @throw [OFInvalidArgumentException exception];

    @try {
        (void)[self _registrationForImplementation: providerClass];
        return;
    } @catch (OFInvalidArgumentException *exception) {
        (void)exception;
    }

    [_registrations addObject:
        [AsyncDBProviderRegistration registrationWithImplementation: providerClass]];
}

- (OFArray<OFString *> *)providerNames
{
    auto providerNames = [OFMutableArray<OFString *> arrayWithCapacity: _registrations.count];

    for (AsyncDBProviderRegistration *registration in _registrations)
        [providerNames addObject: registration.name];

    return [providerNames copy];
}

- (AsyncDBProviderRegistration *)_registrationForImplementation: (Class<AsyncDBProvider>)implementation
{
    for (AsyncDBProviderRegistration *registration in _registrations)
        if (registration.implementation == implementation)
            return registration;

    @throw [OFInvalidArgumentException exception];
}

- (AsyncDBProviderRegistration *)_registrationNamed: (OFString *)providerName
{
    for (AsyncDBProviderRegistration *registration in _registrations)
        if ([registration matchesName: providerName])
            return registration;

    @throw [OFInvalidArgumentException exception];
}

- (AsyncDBProviderRegistration *)_registrationForScheme: (OFString *)scheme
{
    for (AsyncDBProviderRegistration *registration in _registrations)
        if ([registration supportsScheme: scheme])
            return registration;

    @throw [OFInvalidArgumentException exception];
}

- (bool)hasProviderNamed: (OFString *)providerName
{
    @try {
        (void)[self _registrationNamed: providerName];
        return true;
    } @catch (OFInvalidArgumentException *) {
        return false;
    }
}

- (bool)hasProviderForScheme: (OFString *)scheme
{
    @try {
        (void)[self _registrationForScheme: scheme];
        return true;
    } @catch (OFInvalidArgumentException *) {
        return false;
    }
}

- (id<AsyncDBConnection>)connectionWithProviderClass: (Class<AsyncDBProvider>)providerClass
                                                IRI: (OFIRI *)IRI
                                            options: (AsyncDBConnectionOptions *)options
{
    if (providerClass == Nil)
        @throw [OFInvalidArgumentException exception];

    return [providerClass dbConnectionWithIRI: IRI options: options];
}

- (id<AsyncDBConnection>)connectionWithProviderName: (OFString *)providerName
                                           IRI: (OFIRI *)IRI
                                       options: (AsyncDBConnectionOptions *)options
{
    return [[self _registrationNamed: providerName] connectionWithIRI: IRI
                                                              options: options];
}

- (id<AsyncDBConnection>)connectionWithIRI: (OFIRI *)IRI
                                  options: (AsyncDBConnectionOptions *)options
{
    return [[self _registrationForScheme: IRI.scheme] connectionWithIRI: IRI
                                                                options: options];
}

@end

#pragma clang assume_nonnull end
