#include <math.h>

#import "TestSupport.h"
#import "CalculatorEvaluator.h"
#import "CalculatorModel.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted]]
@interface AsyncRuntimeAppCalculatorTests : OTTestCase @end

@implementation AsyncRuntimeAppCalculatorTests

- (void)test_calculator_evaluator_scientific_ops
{
    double result = [CalculatorEvaluator evaluateExpression: @"sin(45)^2 + cos(45)^2"
                                                  angleMode: CalculatorAngleModeDegrees
                                                 lastAnswer: 0.0];
    OTAssert((fabs(result - 1.0) < 1e-9), @"calculator evaluator should preserve sin^2 + cos^2 = 1 in degree mode");

    result = [CalculatorEvaluator evaluateExpression: @"pow(2, 8) + max(3, 9) + mod(10, 4)"
                                           angleMode: CalculatorAngleModeRadians
                                          lastAnswer: 0.0];
    OTAssert((fabs(result - 267.0) < 1e-9), @"calculator evaluator should compute pow, max, and mod correctly");

    result = [CalculatorEvaluator evaluateExpression: @"sin(pi / 2)"
                                           angleMode: CalculatorAngleModeRadians
                                          lastAnswer: 0.0];
    OTAssert((fabs(result - 1.0) < 1e-9), @"calculator evaluator should not leak parser angle state between evaluations");

    result = [CalculatorEvaluator evaluateExpression: @"cbrt(27)"
                                           angleMode: CalculatorAngleModeRadians
                                          lastAnswer: 0.0];
    OTAssert((fabs(result - 3.0) < 1e-9), @"calculator evaluator should compute cbrt(x) correctly");

    result = [CalculatorEvaluator evaluateExpression: @"ans + tau / pi"
                                           angleMode: CalculatorAngleModeRadians
                                          lastAnswer: 40.0];
    OTAssert((fabs(result - 42.0) < 1e-9), @"calculator evaluator should resolve ans and tau via reflective constant lookup");

    bool caughtTanDomain = false;

    @try {
        (void)[CalculatorEvaluator evaluateExpression: @"tan(90)"
                                            angleMode: CalculatorAngleModeDegrees
                                           lastAnswer: 0.0];
    } @catch (CalculatorEvaluationException *exception) {
        caughtTanDomain = [exception.reason isEqual: @"tan(x) is undefined for angles where cos(x) = 0."];
    }

    OTAssert((caughtTanDomain), @"calculator evaluator should explain tan-domain failures");
}

- (void)test_calculator_model_memory_and_history
{
    auto model = [[CalculatorModel alloc] init];

    model.expressionFromText = @"pow(2, 10)";
    OTAssert(([model evaluate]), @"calculator model should evaluate pow(2, 10)");
    OTAssert(([model.resultText isEqual: @"1024"]), @"calculator model should format exact integer results cleanly");
    OTAssert((model.history.count == 1), @"calculator model should record committed evaluations in history");

    [model memoryStore];
    OTAssert((model.hasMemoryValue), @"calculator model should store the active value in memory");
    OTAssert(([model.memoryDisplayText isEqual: @"1024"]), @"calculator model should expose stored memory text");

    [model clearExpression];
    [model memoryRecall];
    OTAssert(([model.expression isEqual: @"1024"]), @"memory recall should place the stored value back into the expression");

    [model appendOperator: @"+"];
    [model appendDigits: @"1"];
    OTAssert(([model evaluate]), @"calculator model should evaluate a recalled-memory expression");
    OTAssert(([model.resultText isEqual: @"1025"]), @"calculator model should combine recalled memory with subsequent input");
    OTAssert((model.history.count == 2), @"calculator model should keep a rolling history of committed expressions");
}

- (void)test_calculator_model_edge_cases
{
    auto model = [[CalculatorModel alloc] init];

    OTAssert((not [model evaluate]), @"calculator model should reject evaluation when the expression is empty and there is no ANS");
    OTAssert((model.hasError), @"empty evaluation should mark the model as errored");

    [model memoryRecall];
    OTAssert((model.hasError), @"memory recall without a stored value should report an error");

    [model appendAnswerReference];
    OTAssert((model.hasError), @"ANS insertion without a prior result should report an error");

    [model appendDigits: @"9"];
    [model appendOpenParenthesis];
    OTAssert(([model.expression isEqual: @"9*("]), @"opening a parenthesis after a literal should insert implicit multiplication");

    [model clearExpression];
    [model appendDecimalPoint];
    OTAssert(([model.expression isEqual: @"0."]), @"decimal input at the start of an expression should prefix a zero");
    [model appendDecimalPoint];
    OTAssert(([model.expression isEqual: @"0."]), @"calculator model should avoid duplicate decimal points in the same numeric token");

    [model clearExpression];
    [model appendOperator: @"+"];
    OTAssert(([model.expression isEqual: @"0+"]), @"operators at the start of an expression should seed from zero when ANS is unavailable");

    [model clearExpression];
    [model applyPercent];
    OTAssert((model.hasError), @"percent requires an existing expression or ANS");
    [model applyFactorial];
    OTAssert((model.hasError), @"factorial requires an existing expression or ANS");
    [model applySquare];
    OTAssert((model.hasError), @"square requires an existing expression or ANS");
    [model applyReciprocal];
    OTAssert((model.hasError), @"reciprocal requires an existing expression or ANS");

    model.expressionFromText = @"2";
    OTAssert(([model evaluate]), @"calculator model should evaluate a simple literal to seed ANS");
    OTAssert(([model.resultText isEqual: @"2"]), @"simple evaluation should preserve the literal result");

    [model clearExpression];
    [model appendOperator: @"+"];
    OTAssert(([model.expression isEqual: @"2+"]), @"operators at the start of a fresh expression should continue from ANS when available");

    [model clearExpression];
    [model toggleSign];
    OTAssert(([model.expression isEqual: @"-(ans)"]), @"toggleSign with no expression should wrap ANS when it exists");

    [model clearExpression];
    [model applyPercent];
    OTAssert(([model.expression isEqual: @"ans%"]), @"percent should fall back to ANS when the working expression is empty");

    [model clearExpression];
    [model applyFactorial];
    OTAssert(([model.expression isEqual: @"ans!"]), @"factorial should fall back to ANS when the working expression is empty");

    [model clearExpression];
    [model memoryAdd];
    OTAssert((model.hasMemoryValue), @"memoryAdd should use ANS when there is no active expression");
    OTAssert((fabs(model.memoryValue - 2.0) < 1e-9), @"memoryAdd should add the current ANS value into memory");

    [model memorySubtract];
    OTAssert((model.hasMemoryValue), @"memorySubtract should preserve the memory slot");
    OTAssert((fabs(model.memoryValue) < 1e-9), @"memorySubtract should subtract ANS from memory");

    for (int value = 0; value < 16; value++) {
        model.expressionFromText = [OFString stringWithFormat: @"%d", value];
        OTAssert(([model evaluate]), @"history seeding evaluations should succeed");
    }

    OTAssert((model.history.count == 14), @"calculator model should cap history to the most recent 14 entries");

    [model loadHistoryExpressionAtIndex: 13];
    OTAssert(([model.expression isEqual: @"2"]), @"loading the oldest retained history expression should preserve the retained window");

    [model clearAll];
    OTAssert((not model.hasLastAnswer), @"clearAll should discard ANS");
    OTAssert((not model.hasMemoryValue), @"clearAll should discard memory");
    OTAssert((model.history.count == 14), @"clearAll should preserve history for reuse");
}

@end
#pragma clang assume_nonnull end
