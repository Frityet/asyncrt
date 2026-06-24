#import "Common.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface PluginModuleUnavailableException : OFException

@property(readonly, copy, nonatomic) OFString *path;

- (instancetype)initWithPath: (OFString *)path [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

[[subclassing_restricted, direct_members]]
@interface Plugin : OFObject

@property(class, readonly, nonatomic) bool canLoadModules;
@property(readonly, copy, nonatomic) OFString *path;
@property(readonly, nonatomic) id module;
@property(readonly, nonatomic) bool isCurrentProcess;

+ (bool)canLoadModules;
+ (instancetype)currentProcessPlugin;
+ (instancetype)pluginWithPath: (OFString *)path;
+ (OFString *)resolvedPathForPluginNamed: (OFString *)name;
- (instancetype)initCurrentProcessPlugin [[designated_initailiser]];
- (instancetype)initWithPath: (OFString *)path [[designated_initailiser]];
- (OFData *)classPointersThatImplementProtocol: (Protocol *unretained)protocol;
- (instancetype)init OF_UNAVAILABLE;

@end

#pragma clang assume_nonnull end
