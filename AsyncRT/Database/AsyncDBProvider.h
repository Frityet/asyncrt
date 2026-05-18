#pragma once

#import <AsyncRT/Database/AsyncDBConnection.h>

#pragma clang assume_nonnull begin

@protocol AsyncDBProvider<AsyncDBConnection>

+ (OFString *)dbProviderName;
+ (OFArray<OFString *> *)dbProviderSchemes;
+ (id<AsyncDBConnection>)dbConnectionWithIRI: (OFIRI *)IRI options: (AsyncDBConnectionOptions *)options;

@end


[[subclassing_restricted, direct_members]]
@interface AsyncDBProviderRegistry : OFObject

@property(readonly, nonatomic) OFArray<OFString *> *providerNames;

+ (instancetype)registry;
+ (instancetype)registryWithProviderClass: (Class<AsyncDBProvider>)providerClass;
- (void)registerProviderClass: (Class<AsyncDBProvider>)providerClass;
- (bool)hasProviderNamed: (OFString *)providerName;
- (bool)hasProviderForScheme: (OFString *)scheme;
- (id<AsyncDBConnection>)connectionWithProviderClass: (Class<AsyncDBProvider>)providerClass
                                                IRI: (OFIRI *)IRI
                                            options: (AsyncDBConnectionOptions *)options;
- (id<AsyncDBConnection>)connectionWithProviderName: (OFString *)providerName
                                           IRI: (OFIRI *)IRI
                                       options: (AsyncDBConnectionOptions *)options;
- (id<AsyncDBConnection>)connectionWithIRI: (OFIRI *)IRI
                              options: (AsyncDBConnectionOptions *)options;

@end

#pragma clang assume_nonnull end
