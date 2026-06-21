#pragma once

#import <AsyncRT/Application/UI/Surface/Web/View.h>

#if defined(__linux__)

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncWebKitGTKView : AsyncWebUIView
@end

#pragma clang assume_nonnull end

#endif
