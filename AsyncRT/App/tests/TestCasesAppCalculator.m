#include <math.h>

#import "TestSupport.h"
#import "CalculatorEvaluator.h"
#import "CalculatorModel.h"

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

static void calculator_model_edge_cases(void)
{
    auto model = [CalculatorModel model];

    [AsyncRuntimeTestSupport assertCondition: (not [model evaluate])
                                     message: @"calculator model should reject evaluation when the expression is empty and there is no ANS"];
    [AsyncRuntimeTestSupport assertCondition: (model.hasError)
                                     message: @"empty evaluation should mark the model as errored"];

    [model memoryRecall];
    [AsyncRuntimeTestSupport assertCondition: (model.hasError)
                                     message: @"memory recall without a stored value should report an error"];

    [model appendAnswerReference];
    [AsyncRuntimeTestSupport assertCondition: (model.hasError)
                                     message: @"ANS insertion without a prior result should report an error"];

    [model appendDigits: @"9"];
    [model appendOpenParenthesis];
    [AsyncRuntimeTestSupport assertCondition: ([model.expression isEqual: @"9*("])
                                     message: @"opening a parenthesis after a literal should insert implicit multiplication"];

    [model clearExpression];
    [model appendDecimalPoint];
    [AsyncRuntimeTestSupport assertCondition: ([model.expression isEqual: @"0."])
                                     message: @"decimal input at the start of an expression should prefix a zero"];
    [model appendDecimalPoint];
    [AsyncRuntimeTestSupport assertCondition: ([model.expression isEqual: @"0."])
                                     message: @"calculator model should avoid duplicate decimal points in the same numeric token"];

    [model clearExpression];
    [model appendOperator: @"+"];
    [AsyncRuntimeTestSupport assertCondition: ([model.expression isEqual: @"0+"])
                                     message: @"operators at the start of an expression should seed from zero when ANS is unavailable"];

    [model clearExpression];
    [model applyPercent];
    [AsyncRuntimeTestSupport assertCondition: (model.hasError)
                                     message: @"percent requires an existing expression or ANS"];
    [model applyFactorial];
    [AsyncRuntimeTestSupport assertCondition: (model.hasError)
                                     message: @"factorial requires an existing expression or ANS"];
    [model applySquare];
    [AsyncRuntimeTestSupport assertCondition: (model.hasError)
                                     message: @"square requires an existing expression or ANS"];
    [model applyReciprocal];
    [AsyncRuntimeTestSupport assertCondition: (model.hasError)
                                     message: @"reciprocal requires an existing expression or ANS"];

    model.expressionFromText = @"2";
    [AsyncRuntimeTestSupport assertCondition: ([model evaluate])
                                     message: @"calculator model should evaluate a simple literal to seed ANS"];
    [AsyncRuntimeTestSupport assertCondition: ([model.resultText isEqual: @"2"])
                                     message: @"simple evaluation should preserve the literal result"];

    [model clearExpression];
    [model appendOperator: @"+"];
    [AsyncRuntimeTestSupport assertCondition: ([model.expression isEqual: @"2+"])
                                     message: @"operators at the start of a fresh expression should continue from ANS when available"];

    [model clearExpression];
    [model toggleSign];
    [AsyncRuntimeTestSupport assertCondition: ([model.expression isEqual: @"-(ans)"])
                                     message: @"toggleSign with no expression should wrap ANS when it exists"];

    [model clearExpression];
    [model applyPercent];
    [AsyncRuntimeTestSupport assertCondition: ([model.expression isEqual: @"ans%"])
                                     message: @"percent should fall back to ANS when the working expression is empty"];

    [model clearExpression];
    [model applyFactorial];
    [AsyncRuntimeTestSupport assertCondition: ([model.expression isEqual: @"ans!"])
                                     message: @"factorial should fall back to ANS when the working expression is empty"];

    [model clearExpression];
    [model memoryAdd];
    [AsyncRuntimeTestSupport assertCondition: (model.hasMemoryValue)
                                     message: @"memoryAdd should use ANS when there is no active expression"];
    [AsyncRuntimeTestSupport assertCondition: (fabs(model.memoryValue - 2.0) < 1e-9)
                                     message: @"memoryAdd should add the current ANS value into memory"];

    [model memorySubtract];
    [AsyncRuntimeTestSupport assertCondition: (model.hasMemoryValue)
                                     message: @"memorySubtract should preserve the memory slot"];
    [AsyncRuntimeTestSupport assertCondition: (fabs(model.memoryValue) < 1e-9)
                                     message: @"memorySubtract should subtract ANS from memory"];

    for (int value = 0; value < 16; value++) {
        model.expressionFromText = [OFString stringWithFormat: @"%d", value];
        [AsyncRuntimeTestSupport assertCondition: ([model evaluate])
                                         message: @"history seeding evaluations should succeed"];
    }

    [AsyncRuntimeTestSupport assertCondition: (model.history.count == 14)
                                     message: @"calculator model should cap history to the most recent 14 entries"];

    [model loadHistoryExpressionAtIndex: 13];
    [AsyncRuntimeTestSupport assertCondition: ([model.expression isEqual: @"2"])
                                     message: @"loading the oldest retained history expression should preserve the retained window"];

    [model clearAll];
    [AsyncRuntimeTestSupport assertCondition: (not model.hasLastAnswer)
                                     message: @"clearAll should discard ANS"];
    [AsyncRuntimeTestSupport assertCondition: (not model.hasMemoryValue)
                                     message: @"clearAll should discard memory"];
    [AsyncRuntimeTestSupport assertCondition: (model.history.count == 14)
                                     message: @"clearAll should preserve history for reuse"];
}

ASYNC_RUNTIME_SYNC_TEST(calculator_model_edge_cases)

#pragma clang assume_nonnull end
