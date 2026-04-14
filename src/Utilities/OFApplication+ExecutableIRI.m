#import <ObjFW/ObjFW.h>
#import "Utilities/OFApplication+ExecutableIRI.h"

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

@interface OFApplication(ExecutableIRIPrivate)

+ (OFIRI *_Nullable)_executableIRIFromPath: (OFString *_Nullable)path;
+ (OFIRI *_Nullable)_standardizedExecutableIRIFromPath: (OFString *_Nullable)path;
+ (OFString *_Nullable)_executablePathFromOperatingSystem;
+ (OFString *_Nullable)_executablePathFromProgramNameFallback;

#if defined(OF_MACOS)
+ (OFString *_Nullable)_executablePathFromMachO;
#elif defined(OF_LINUX)
+ (OFString *_Nullable)_executablePathFromProcSelfExecutable;
#elif defined(OF_WINDOWS)
+ (OFString *_Nullable)_executablePathFromWindowsModule;
#endif

@end

@implementation OFApplication(ExecutableIRI)

+ (OFIRI *_Nullable)executableIRI
{
    OFIRI *executableIRI = [self _executableIRIFromPath: [self _executablePathFromOperatingSystem]];
    if (executableIRI != nil)
        return executableIRI;

    return [self _executableIRIFromPath: [self _executablePathFromProgramNameFallback]];
}

+ (OFIRI *_Nullable)_executableIRIFromPath: (OFString *_Nullable)path
{
    if (path == nil)
        return nil;

    OFString *nonNullPath = (OFString *)path;
    return [OFIRI fileIRIWithPath: nonNullPath isDirectory: false];
}

+ (OFIRI *_Nullable)_standardizedExecutableIRIFromPath: (OFString *_Nullable)path
{
    if (path == nil || path.length == 0)
        return nil;

    OFString *nonNullPath = (OFString *)path;

#if !defined(OF_WINDOWS)
    OFStringEncoding pathEncoding = [OFLocale encoding];
    char *resolvedPathCString = realpath([nonNullPath cStringWithEncoding: pathEncoding], NULL);

    if (resolvedPathCString != NULL) {
        @try {
            OFString *resolvedPath = [OFString stringWithCString: resolvedPathCString encoding: pathEncoding];
            return [self _executableIRIFromPath: resolvedPath];
        } @finally {
            free(resolvedPathCString);
        }
    }
#endif

    return [self _executableIRIFromPath: nonNullPath].IRIByStandardizingPath;
}

+ (OFString *_Nullable)_executablePathFromOperatingSystem
{
#if defined(OF_MACOS)
    return [self _executablePathFromMachO];
#elif defined(OF_LINUX)
    return [self _executablePathFromProcSelfExecutable];
#elif defined(OF_WINDOWS)
    return [self _executablePathFromWindowsModule];
#else
    return nil;
#endif
}

+ (OFString *_Nullable)_executablePathFromProgramNameFallback
{
    return [self _standardizedExecutableIRIFromPath: self.programName].fileSystemRepresentation;
}

#if defined(OF_MACOS)
+ (OFString *_Nullable)_executablePathFromMachO
{
    uint32_t pathCapacity = 0;

    if (_NSGetExecutablePath(NULL, &pathCapacity) == 0 || pathCapacity == 0)
        return nil;

    char *pathBuffer = malloc(pathCapacity);
    if (pathBuffer == NULL)
        @throw [OFOutOfMemoryException exceptionWithRequestedSize: pathCapacity];

    @try {
        if (_NSGetExecutablePath(pathBuffer, &pathCapacity) != 0)
            return nil;

        OFString *path = [OFString stringWithCString: pathBuffer encoding: [OFLocale encoding]];
        return [self _standardizedExecutableIRIFromPath: path].fileSystemRepresentation;
    } @finally {
        free(pathBuffer);
    }
}
#elif defined(OF_LINUX)
+ (OFString *_Nullable)_executablePathFromProcSelfExecutable
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
            return nil;
        }

        if ((size_t)pathLength < pathCapacity) {
            @try {
                OFString *path = [OFString stringWithCString: pathBuffer
                                                    encoding: [OFLocale encoding]
                                                      length: (size_t)pathLength];
                return [self _standardizedExecutableIRIFromPath: path].fileSystemRepresentation;
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
+ (OFString *_Nullable)_executablePathFromWindowsModule
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
            return nil;
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
