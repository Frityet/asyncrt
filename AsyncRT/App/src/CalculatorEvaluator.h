#pragma once

#include "common.h"

#pragma clang assume_nonnull begin

typedef enum CalculatorAngleMode {
    CalculatorAngleModeDegrees,
    CalculatorAngleModeRadians
} CalculatorAngleMode;

[[subclassing_restricted, direct_members]]
@interface CalculatorEvaluationException : OFException

@property(readonly, copy, nonatomic) OFString *reason;

- (instancetype)initWithReason: (OFString *nonnil)reason [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

@end

@namespace(CalculatorEvaluator)

+ (double)evaluateExpression: (OFString *nonnil)expression
                  angleMode: (CalculatorAngleMode)angleMode
                 lastAnswer: (double)lastAnswer;

@end

#pragma clang assume_nonnull end
