#import <ObjFW/ObjFW.h>
#import <AsyncRT/Common/OFApplication+ExecutableIRI.h>

#if defined(OF_MACOS)
#   include <mach-o/dyld.h>
#endif

#if defined(OF_WINDOWS)
#   include <windows.h>
#else
#   include <limits.h>
#   include <stdlib.h>
#   include <unistd.h>
#endif

#pragma clang assume_nonnull begin

@implementation CannotGetExecutablePathException
@end

@interface OFApplication(ExecutableIRIPrivate)

+ (OFIRI *)_standardizedExecutableIRIFromPath: (OFString *)path;
+ (OFString *)_executablePathFromOperatingSystem;
+ (OFString *)_executablePathFromProgramNameFallback;

#if defined(OF_MACOS)
+ (OFString *)_executablePathFromMachO;
#elif defined(OF_LINUX)
+ (OFString *)_executablePathFromProcSelfExecutable;
#elif defined(OF_WINDOWS)
+ (OFString *)_executablePathFromWindowsModule;
#endif

@end

@implementation OFApplication(ExecutableIRI)

+ (OFIRI *)executableIRI
{ return [OFIRI fileIRIWithPath: self._executablePathFromOperatingSystem isDirectory: false]; }


+ (OFIRI *)_standardizedExecutableIRIFromPath: (OFString *)path
{

#if !defined(OF_WINDOWS)
    char *resolvedPathCString = realpath([path cStringWithEncoding: OFLocale.encoding], NULL);

    if (resolvedPathCString != nullptr) {
        @try {
            OFString *resolvedPath = [OFString stringWithCString: resolvedPathCString encoding: OFLocale.encoding];
            return [OFIRI fileIRIWithPath: resolvedPath isDirectory: false];
        } @finally {
            free(resolvedPathCString);
        }
    }
#endif

    return [OFIRI fileIRIWithPath: path isDirectory: false].IRIByStandardizingPath;
}

+ (OFString *)_executablePathFromOperatingSystem
{
#if defined(OF_MACOS)
    return self._executablePathFromMachO;
#elif defined(OF_LINUX)
    return self._executablePathFromProcSelfExecutable;
#elif defined(OF_WINDOWS)
    return self._executablePathFromWindowsModule;
#else
#   error "Unsupported platform"
#endif
}

+ (OFString *)_executablePathFromProgramNameFallback
{
    @try {
        return $assert_nonnil([self _standardizedExecutableIRIFromPath: $assert_nonnil(self.programName)].fileSystemRepresentation);
    } @catch(NilReferenceException *) {
        @throw [CannotGetExecutablePathException exception];
    }
}

#if defined(OF_MACOS)
+ (OFString *)_executablePathFromMachO
{
    uint32_t pathCapacity = 0;

    if (_NSGetExecutablePath(NULL, &pathCapacity) == 0 || pathCapacity == 0)
        @throw [CannotGetExecutablePathException exception];

    char *pathBuffer = malloc(pathCapacity);
    if (pathBuffer == NULL)
        @throw [OFOutOfMemoryException exceptionWithRequestedSize: pathCapacity];

    @try {
        if (_NSGetExecutablePath(pathBuffer, &pathCapacity) != 0)
            return nil;

        OFString *path = [OFString stringWithCString: pathBuffer encoding: [OFLocale encoding]];
        return $assert_nonnil([self _standardizedExecutableIRIFromPath: path].fileSystemRepresentation);
    } @finally {
        free(pathBuffer);
    }
}
#elif defined(OF_LINUX)
+ (OFString *)_executablePathFromProcSelfExecutable
{
    size_t pathCapacity = 1024;
    char *pathBuffer = NULL;

#if defined(PATH_MAX)
    pathCapacity = PATH_MAX;
#endif

    while (true) {
        char *resizedPathBuffer = realloc(pathBuffer, pathCapacity);
        if (resizedPathBuffer == NULL) {
            free(pathBuffer);
            @throw [OFOutOfMemoryException exceptionWithRequestedSize: pathCapacity];
        }
        pathBuffer = resizedPathBuffer;

        ssize_t pathLength = readlink("/proc/self/exe", pathBuffer, pathCapacity);
        if (pathLength < 0) {
            free(pathBuffer);
            @throw [CannotGetExecutablePathException exception];
        }

        if ((size_t)pathLength < pathCapacity) {
            @try {
                OFString *path = [OFString stringWithCString: pathBuffer
                                                    encoding: [OFLocale encoding]
                                                      length: (size_t)pathLength];
                return $assert_nonnil([self _standardizedExecutableIRIFromPath: path].fileSystemRepresentation);
            } @finally {
                free(pathBuffer);
            }
        }

        if (pathCapacity > SIZE_MAX / 2) {
            free(pathBuffer);
            @throw [OFOutOfMemoryException exceptionWithRequestedSize: pathCapacity];
        }

        pathCapacity *= 2;
    }
}
#elif defined(OF_WINDOWS)
+ (OFString *)_executablePathFromWindowsModule
{
    size_t pathCapacity = MAX_PATH;
    OFChar16 *pathBuffer = NULL;

    while (true) {
        if (pathCapacity > SIZE_MAX / sizeof(OFChar16))
            @throw [OFOutOfMemoryException exceptionWithRequestedSize: pathCapacity * sizeof(OFChar16)];

        OFChar16 *resizedPathBuffer = realloc(pathBuffer, pathCapacity * sizeof(OFChar16));
        if (resizedPathBuffer == NULL) {
            free(pathBuffer);
            @throw [OFOutOfMemoryException exceptionWithRequestedSize: pathCapacity * sizeof(OFChar16)];
        }
        pathBuffer = resizedPathBuffer;

        DWORD pathLength = GetModuleFileNameW(NULL, (LPWSTR)pathBuffer, (DWORD)pathCapacity);
        if (pathLength == 0) {
            free(pathBuffer);
            @throw [CannotGetExecutablePathException exception];
        }

        if ((size_t)pathLength < pathCapacity) {
            @try {
                OFString *path = [OFString stringWithUTF16String: pathBuffer length: pathLength];
                return [self _standardizedExecutableIRIFromPath: path].fileSystemRepresentation;
            } @finally {
                free(pathBuffer);
            }
        }

        pathCapacity *= 2;
    }
}
#endif

@end

#pragma clang assume_nonnull end
