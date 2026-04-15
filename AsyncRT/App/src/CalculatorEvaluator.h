#pragma once

#include "common.h"

#pragma clang assume_nonnull begin

typedef enum CalculatorAngleMode {
    CalculatorAngleModeDegrees,
    CalculatorAngleModeRadians
} CalculatorAngleMode;

@namespace(CalculatorEvaluator)

+ (bool)evaluateExpression: (OFString *nonnil)expression
                  angleMode: (CalculatorAngleMode)angleMode
                 lastAnswer: (double)lastAnswer
                     result: (double *nonnil)result
                      error: (OFString *nillable *_Nullable)error;

@end

#pragma clang assume_nonnull end
