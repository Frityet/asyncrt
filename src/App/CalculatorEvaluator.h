#pragma once

#include "Utilities/common.h"

#pragma clang assume_nonnull begin

typedef enum AsyncRTCalculatorAngleMode {
    AsyncRTCalculatorAngleModeDegrees,
    AsyncRTCalculatorAngleModeRadians
} AsyncRTCalculatorAngleMode;

@namespace(AsyncRTCalculatorEvaluator)

+ (bool)evaluateExpression: (OFString *nillable)expression
                  angleMode: (AsyncRTCalculatorAngleMode)angleMode
                 lastAnswer: (double)lastAnswer
                     result: (double *)result
                      error: (OFString *nillable *_Nullable)error;

@end

#pragma clang assume_nonnull end
