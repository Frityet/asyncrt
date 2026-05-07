#import "DBProvider.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface DBProviderRegistration : OFObject

@property(readonly, nonatomic) Class<DBProvider> implementation;
@property(readonly, nonatomic) OFString *name;
@property(readonly, nonatomic) OFArray<OFString *> *schemes;

+ (instancetype)registrationWithImplementation: (Class<DBProvider>)implementation;
- (instancetype)initWithImplementation: (Class<DBProvider>)implementation [[designated_initailiser]];
- (bool)matchesName: (OFString *)providerName;
- (bool)supportsScheme: (OFString *)scheme;
- (id<DBConnection>)connectionWithIRI: (OFIRI *)IRI options: (DBConnectionOptions *)options;
- (instancetype)init OF_UNAVAILABLE;

@end

@interface DBProviderRegistry ()

- (OFArray<DBProviderRegistration *> *)_registrations;
- (DBProviderRegistration *)_registrationNamed: (OFString *)providerName;
- (DBProviderRegistration *)_registrationForScheme: (OFString *)scheme;

@end

@implementation DBProviderRegistration

+ (instancetype)registrationWithImplementation: (Class<DBProvider>)implementation
{ return [[self alloc] initWithImplementation: implementation]; }

- (instancetype)initWithImplementation: (Class<DBProvider>)implementation
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

- (id<DBConnection>)connectionWithIRI: (OFIRI *)IRI options: (DBConnectionOptions *)options
{ return [_implementation dbConnectionWithIRI: IRI options: options]; }

@end

@implementation DBProviderRegistry

+ (instancetype)defaultRegistry
{ return [self registryWithPlugins: @[ Plugin.currentProcessPlugin ]]; }

+ (instancetype)registryWithPlugins: (OFArray<Plugin *> *)plugins
{ return [[self alloc] initWithPlugins: plugins]; }

+ (instancetype)registryWithPluginPaths: (OFArray<OFString *> *)pluginPaths
{
    auto plugins = [OFMutableArray<Plugin *> arrayWithCapacity: pluginPaths.count + 1];

    [plugins addObject: Plugin.currentProcessPlugin];
    for (OFString *pluginPath in pluginPaths)
        [plugins addObject: [Plugin pluginWithPath: pluginPath]];

    return [self registryWithPlugins: plugins];
}

- (instancetype)initWithPlugins: (OFArray<Plugin *> *)plugins
{
    self = [super init];
    _plugins = [plugins copy];
    return self;
}

- (OFArray<DBProviderRegistration *> *)_registrations
{
    auto registrations = [OFMutableArray<DBProviderRegistration *> array];

    for (Plugin *plugin in _plugins) {
        for (Class discoveredClass in [plugin classesThatImplementProtocol: @protocol(DBProvider)]) {
            auto implementation = (Class<DBProvider>)discoveredClass;
            bool alreadyAdded = false;

            for (DBProviderRegistration *registration in registrations) {
                if (registration.implementation == implementation) {
                    alreadyAdded = true;
                    break;
                }
            }

            if (not alreadyAdded)
                [registrations addObject: [DBProviderRegistration registrationWithImplementation: implementation]];
        }
    }

    return [registrations copy];
}

- (OFArray<OFString *> *)providerNames
{
    auto providerNames = [OFMutableArray<OFString *> array];

    for (DBProviderRegistration *registration in self._registrations)
        [providerNames addObject: registration.name];

    return [providerNames copy];
}

- (DBProviderRegistration *)_registrationNamed: (OFString *)providerName
{
    for (DBProviderRegistration *registration in self._registrations)
        if ([registration matchesName: providerName])
            return registration;

    @throw [OFInvalidArgumentException exception];
}

- (DBProviderRegistration *)_registrationForScheme: (OFString *)scheme
{
    for (DBProviderRegistration *registration in self._registrations)
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

- (id<DBConnection>)connectionWithProviderName: (OFString *)providerName
                                           IRI: (OFIRI *)IRI
                                       options: (DBConnectionOptions *)options
{
    return [[self _registrationNamed: providerName] connectionWithIRI: IRI
                                                              options: options];
}

- (id<DBConnection>)connectionWithIRI: (OFIRI *)IRI
                              options: (DBConnectionOptions *)options
{
    return [[self _registrationForScheme: IRI.scheme] connectionWithIRI: IRI
                                                                options: options];
}

@end

#pragma clang assume_nonnull end
