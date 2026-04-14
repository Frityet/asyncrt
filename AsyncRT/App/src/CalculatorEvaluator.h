#pragma once

#include "common.h"

#pragma clang assume_nonnull begin

typedef enum CalculatorAngleMode {
    CalculatorAngleModeDegrees,
    CalculatorAngleModeRadians
} CalculatorAngleMode;

@namespace(CalculatorEvaluator)

+ (bool)evaluateExpression: (OFString *nillable)expression
                  angleMode: (CalculatorAngleMode)angleMode
                 lastAnswer: (double)lastAnswer
                     result: (double *)result
                      error: (OFString *nillable *_Nullable)error;

@end

#pragma clang assume_nonnull end
