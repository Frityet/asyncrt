#pragma once

#import "DBConnection.h"
#import "Plugin.h"

#pragma clang assume_nonnull begin

@protocol DBProvider<DBConnection>

+ (OFString *)dbProviderName;
+ (OFArray<OFString *> *)dbProviderSchemes;
+ (id<DBConnection>)dbConnectionWithIRI: (OFIRI *)IRI options: (DBConnectionOptions *)options;

@end


[[subclassing_restricted, direct_members]]
@interface DBProviderRegistry : OFObject

@property(class, readonly, nonatomic) DBProviderRegistry *defaultRegistry;
@property(readonly, nonatomic) OFArray<Plugin *> *plugins;
@property(readonly, nonatomic) OFArray<OFString *> *providerNames;

+ (instancetype)defaultRegistry;
+ (instancetype)registryWithPlugins: (OFArray<Plugin *> *)plugins;
+ (instancetype)registryWithPluginPaths: (OFArray<OFString *> *)pluginPaths;
- (instancetype)initWithPlugins: (OFArray<Plugin *> *)plugins [[designated_initailiser]];
- (bool)hasProviderNamed: (OFString *)providerName;
- (bool)hasProviderForScheme: (OFString *)scheme;
- (id<DBConnection>)connectionWithProviderName: (OFString *)providerName
                                           IRI: (OFIRI *)IRI
                                       options: (DBConnectionOptions *)options;
- (id<DBConnection>)connectionWithIRI: (OFIRI *)IRI
                              options: (DBConnectionOptions *)options;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
