#include <math.h>

#import "TestSupport.h"
#import "App/CalculatorEvaluator.h"
#import "App/CalculatorModel.h"

#pragma clang assume_nonnull begin

static void calculator_evaluator_scientific_ops(void)
{
    double result = 0.0;
    OFString *nillable error = nilptr;

    [AsyncRuntimeTestSupport assertCondition: ([CalculatorEvaluator evaluateExpression: @"sin(45)^2 + cos(45)^2"
                                                                                     angleMode: CalculatorAngleModeDegrees
                                                                                    lastAnswer: 0.0
                                                                                        result: &result
                                                                                         error: &error])
                                     message: (error ?: @"calculator evaluator should accept a trig identity")];
    [AsyncRuntimeTestSupport assertCondition: (fabs(result - 1.0) < 1e-9)
                                     message: @"calculator evaluator should preserve sin^2 + cos^2 = 1 in degree mode"];

    [AsyncRuntimeTestSupport assertCondition: ([CalculatorEvaluator evaluateExpression: @"pow(2, 8) + max(3, 9) + mod(10, 4)"
                                                                                     angleMode: CalculatorAngleModeRadians
                                                                                    lastAnswer: 0.0
                                                                                        result: &result
                                                                                         error: &error])
                                     message: (error ?: @"calculator evaluator should support two-argument helper functions")];
    [AsyncRuntimeTestSupport assertCondition: (fabs(result - 267.0) < 1e-9)
                                     message: @"calculator evaluator should compute pow, max, and mod correctly"];
}

ASYNC_RUNTIME_SYNC_TEST(calculator_evaluator_scientific_ops)

static void calculator_model_memory_and_history(void)
{
    auto model = [CalculatorModel model];

    model.expressionFromText = @"pow(2, 10)";
    [AsyncRuntimeTestSupport assertCondition: ([model evaluate])
                                     message: @"calculator model should evaluate pow(2, 10)"];
    [AsyncRuntimeTestSupport assertCondition: ([model.resultText isEqual: @"1024"])
                                     message: @"calculator model should format exact integer results cleanly"];
    [AsyncRuntimeTestSupport assertCondition: (model.history.count == 1)
                                     message: @"calculator model should record committed evaluations in history"];

    [model memoryStore];
    [AsyncRuntimeTestSupport assertCondition: (model.hasMemoryValue)
                                     message: @"calculator model should store the active value in memory"];
    [AsyncRuntimeTestSupport assertCondition: ([model.memoryDisplayText isEqual: @"1024"])
                                     message: @"calculator model should expose stored memory text"];

    [model clearExpression];
    [model memoryRecall];
    [AsyncRuntimeTestSupport assertCondition: ([model.expression isEqual: @"1024"])
                                     message: @"memory recall should place the stored value back into the expression"];

    [model appendOperator: @"+"];
    [model appendDigits: @"1"];
    [AsyncRuntimeTestSupport assertCondition: ([model evaluate])
                                     message: @"calculator model should evaluate a recalled-memory expression"];
    [AsyncRuntimeTestSupport assertCondition: ([model.resultText isEqual: @"1025"])
                                     message: @"calculator model should combine recalled memory with subsequent input"];
    [AsyncRuntimeTestSupport assertCondition: (model.history.count == 2)
                                     message: @"calculator model should keep a rolling history of committed expressions"];
}

ASYNC_RUNTIME_SYNC_TEST(calculator_model_memory_and_history)

#pragma clang assume_nonnull end
