#import <AsyncRT/Common/Plugin.h>

#if not defined(__APPLE__)
#import <ObjFWRT/ObjFWRT.h>
#else
#import <objc/runtime.h>
#endif

#pragma clang assume_nonnull begin

@interface Plugin ()

+ (OFData *)_allLoadedClassPointers;
+ (Class)_moduleClassForPluginPath: (OFString *)path;
+ (bool)_class: (Class)cls implementsProtocol: (Protocol *unretained)protocol;
+ (bool)_classPointers: (OFData *)classPointers containClass: (Class)cls;
+ (OFData *)_classPointersIn: (OFData *)classPointers excluding: (OFData *)excludedClassPointers;

@end

@implementation PluginModuleUnavailableException

- (instancetype)initWithPath: (OFString *)path
{
    self = [super init];
    _path = [path copy];
    return self;
}

- (OFString *)description
{
    return [OFString stringWithFormat: @"ObjFW module loading is not available for plugin '%@'", _path];
}

@end

@implementation Plugin {
    bool _isCurrentProcess;
    OFString *_path;
    id _module;
    OFData *_loadedClassPointers;
}

+ (Class)_moduleClassForPluginPath: (OFString *)path
{
    Class moduleClass = objc_getClass("OFModule");

    if (moduleClass == nullptr)
        @throw [[PluginModuleUnavailableException alloc] initWithPath: path];

    return moduleClass;
}

+ (bool)canLoadModules
{ return objc_getClass("OFModule") != nullptr; }

+ (instancetype)currentProcessPlugin
{ return [[self alloc] initCurrentProcessPlugin]; }

+ (instancetype)pluginWithPath: (OFString *)path
{ return [[self alloc] initWithPath: path]; }

+ (OFString *)resolvedPathForPluginNamed: (OFString *)name
{
    Class moduleClass = objc_getClass("OFModule");
    SEL modulePathSelector = @selector(pathForPluginWithName:);

    if (moduleClass != nullptr and [moduleClass respondsToSelector: modulePathSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id resolvedPath = [moduleClass performSelector: modulePathSelector withObject: name];
#pragma clang diagnostic pop
        if (resolvedPath == nilptr)
            @throw [OFInvalidArgumentException exception];

        return (OFString *)resolvedPath;
    }

#if defined(__APPLE__)
    OFString *bundlePath = [name stringByAppendingPathExtension: @"bundle"];

    if ([OFFileManager.defaultManager directoryExistsAtPath: bundlePath])
        return [bundlePath stringByAppendingFormat: @"/Contents/MacOS/%@",
                                                 name.lastPathComponent];

    return [name stringByAppendingPathExtension: @"dylib"];
#else
    return [name stringByAppendingPathExtension: @"so"];
#endif
}

+ (OFData *)_allLoadedClassPointers
{
    int classCount = objc_getClassList(nullptr, 0);

    if (classCount <= 0)
        return [OFData data];

    auto classes = (Class unretained *)malloc(sizeof(Class) * (size_t)classCount);
    if (classes == nullptr)
        @throw [OFOutOfMemoryException exception];

    @try {
        int actualClassCount = objc_getClassList(classes, classCount);
        return [OFData dataWithItems: classes count: (size_t)actualClassCount itemSize: sizeof(Class)];
    } @finally {
        free(classes);
    }
}

+ (bool)_class: (Class)cls implementsProtocol: (Protocol *unretained)protocol
{
    const char *className = class_getName(cls);
    Class currentClass = (className != nullptr ? objc_getClass(className) : Nil);

    for (; currentClass != nullptr; currentClass = class_getSuperclass(currentClass)) {
        if (class_conformsToProtocol(currentClass, protocol))
            return true;
    }

    return false;
}

+ (bool)_classPointers: (OFData *)classPointers containClass: (Class)cls
{
    auto classes = (Class unretained const *)classPointers.items;

    for (size_t classIndex = 0; classIndex < classPointers.count; classIndex++) {
        Class existingClass = classes[classIndex];

        if (existingClass == cls)
            return true;
    }

    return false;
}

+ (OFData *)_classPointersIn: (OFData *)classPointers excluding: (OFData *)excludedClassPointers
{
    auto classes = (const Class unretained *)classPointers.items;
    auto result = [OFMutableData dataWithItemSize: sizeof(Class)];

    for (size_t classIndex = 0; classIndex < classPointers.count; classIndex++) {
        Class cls = classes[classIndex];

        if (not [self _classPointers: excludedClassPointers containClass: cls])
            [result addItem: &cls];
    }

    return [result copy];
}

- (instancetype)initCurrentProcessPlugin
{
    self = [super init];
    _isCurrentProcess = true;
    _path = @"<current-process>";
    _module = self;
    _loadedClassPointers = [OFData data];
    return self;
}

- (instancetype)initWithPath: (OFString *)path
{
    if (path.length == 0)
        @throw [OFInvalidArgumentException exception];

    self = [super init];
    _isCurrentProcess = false;
    _path = [path copy];
    Class moduleClass = [Plugin _moduleClassForPluginPath: _path];
    OFData *classesBeforeLoad = [Plugin _allLoadedClassPointers];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id module = [moduleClass performSelector: @selector(moduleWithPath:) withObject: _path];
#pragma clang diagnostic pop

    if (module == nilptr)
        @throw [OFInvalidArgumentException exception];

    _module = module;
    _loadedClassPointers = [Plugin _classPointersIn: [Plugin _allLoadedClassPointers]
                                          excluding: classesBeforeLoad];
    return self;
}

- (OFString *)path
{
    if (_isCurrentProcess)
        @throw [OFInvalidArgumentException exception];

    return _path;
}

- (id)module
{
    if (_isCurrentProcess)
        @throw [OFInvalidArgumentException exception];

    return _module;
}

- (bool)isCurrentProcess
{
    return _isCurrentProcess;
}

- (OFData *)classPointersThatImplementProtocol: (Protocol *unretained)protocol
{
    OFData *classPointers = (_isCurrentProcess ? [Plugin _allLoadedClassPointers] : _loadedClassPointers);
    auto classes = (Class unretained const *)classPointers.items;
    auto matchingClassPointers = [OFMutableData dataWithItemSize: sizeof(Class)];

    for (size_t classIndex = 0; classIndex < classPointers.count; classIndex++) {
        Class cls = classes[classIndex];

        if ([Plugin _class: cls implementsProtocol: protocol])
            [matchingClassPointers addItem: &cls];
    }

    return [matchingClassPointers copy];
}

@end

#pragma clang assume_nonnull end
