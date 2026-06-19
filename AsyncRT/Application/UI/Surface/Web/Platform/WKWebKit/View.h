#pragma once

#import <AsyncRT/Application/UI/Surface/Web/View.h>

#if defined(__APPLE__)

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface AsyncWKWebKitView : AsyncWebUIView
@end

#pragma clang assume_nonnull end

#endif
