#include <math.h>
#include <stdio.h>

#import "CalculatorModel.h"

#pragma clang assume_nonnull begin

@implementation CalculatorHistoryEntry {
    OFString *_expression;
    OFString *_resultText;
}

- (instancetype)initWithExpression: (OFString *)expression resultText: (OFString *)resultText
{
    self = [super init];
    _expression = [expression copy];
    _resultText = [resultText copy];
    return self;
}

@end

[[direct_members]]
@implementation CalculatorModel {
    OFString *_expression;
    OFString *_resultText;
    OFString *_statusText;
    OFMutableArray<CalculatorHistoryEntry *> *_history;
    CalculatorAngleMode _angleMode;
    double _memoryValue;
    double _lastAnswer;
    bool _hasMemoryValue;
    bool _hasLastAnswer;
    bool _hasError;
    bool _replaceExpressionOnNextInsert;
}

- (instancetype)init
{
    self = [super init];
    _expression = @"";
    _resultText = @"0";
    _statusText = @"Type an expression, use the keypad, or press rand() for a quick start.";
    _history = [OFMutableArray array];
    _angleMode = CalculatorAngleModeDegrees;
    _memoryValue = 0.0;
    _lastAnswer = 0.0;
    _hasMemoryValue = false;
    _hasLastAnswer = false;
    _hasError = false;
    _replaceExpressionOnNextInsert = false;
    return self;
}

- (OFString *)formattedValue: (double)value
{
    char buffer[64];

    if (fabs(value) < 5e-13)
        value = 0.0;

    snprintf(buffer, sizeof(buffer), "%.12g", value);
    return [OFString stringWithUTF8String: buffer];
}

- (void)setStatusText: (OFString *)statusText hasError: (bool)hasError
{
    _statusText = [statusText copy];
    _hasError = hasError;
}

- (OFString *)normalizedExpressionFromText: (OFString *)text
{
    auto normalized = [text mutableCopy];

    [normalized replaceOccurrencesOfString: @"×" withString: @"*"];
    [normalized replaceOccurrencesOfString: @"÷" withString: @"/"];
    [normalized replaceOccurrencesOfString: @"π" withString: @"pi"];
    [normalized replaceOccurrencesOfString: @"−" withString: @"-"];
    [normalized replaceOccurrencesOfString: @"^+" withString: @"^"];
    return [normalized copy];
}

- (double)evaluateCurrentExpression
{
    return [CalculatorEvaluator evaluateExpression: _expression
                                         angleMode: _angleMode
                                        lastAnswer: (_hasLastAnswer ? _lastAnswer : 0.0)];
}

- (void)refreshPreview
{
    if (_expression.length == 0) {
        _resultText = self.lastAnswerDisplayText;
        [self setStatusText: (_hasLastAnswer
                                ? @"Editing is clear. ANS is still available for the next expression."
                                : @"Type an expression, use the keypad, or press rand() for a quick start.")
                   hasError: false];
        return;
    }

    @try {
        const double previewValue = [self evaluateCurrentExpression];
        _resultText = [self formattedValue: previewValue];
        [self setStatusText: @"Live preview is valid. Press Evaluate to commit it to history." hasError: false];
        return;
    } @catch (CalculatorEvaluationException *exception) {
        _resultText = @"--";
        [self setStatusText: exception.reason hasError: true];
    }
}

- (bool)expressionEndsWithOperator
{
    if (_expression.length == 0)
        return false;

    switch ([_expression characterAtIndex: _expression.length - 1]) {
        case '+':
        case '-':
        case '*':
        case '/':
        case '^':
        case ',':
            return true;
        default:
            return false;
    }
}

- (bool)expressionEndsWithUnaryBoundary
{
    if (_expression.length == 0)
        return true;

    switch ([_expression characterAtIndex: _expression.length - 1]) {
        case '(':
        case '+':
        case '-':
        case '*':
        case '/':
        case '^':
        case ',':
            return true;
        default:
            return false;
    }
}

- (bool)expressionNeedsImplicitMultiplication
{
    if (_expression.length == 0)
        return false;

    const OFUnichar character = [_expression characterAtIndex: _expression.length - 1];
    if ((character >= '0' and character <= '9') or character == '.' or character == ')' or character == '%' or character == '!')
        return true;
    if ((character >= 'A' and character <= 'Z') or (character >= 'a' and character <= 'z'))
        return true;
    return false;
}

- (bool)tokenStartsFreshExpression: (OFString *)token
{
    if (token.length == 0)
        return false;

    const OFUnichar character = [token characterAtIndex: 0];
    return ((character >= '0' and character <= '9')
        or (character >= 'A' and character <= 'Z')
        or (character >= 'a' and character <= 'z')
        or character == '.'
        or character == '(');
}

- (void)startFreshExpressionIfNeededForToken: (OFString *)token
{
    if (_replaceExpressionOnNextInsert and [self tokenStartsFreshExpression: token])
        _expression = @"";

    _replaceExpressionOnNextInsert = false;
}

- (void)appendAtomToken: (OFString *)token
{
    [self startFreshExpressionIfNeededForToken: token];

    if ([self expressionNeedsImplicitMultiplication])
        _expression = [_expression stringByAppendingString: @"*"];

    _expression = [_expression stringByAppendingString: token];
}

- (void)recordHistoryExpression: (OFString *)expression resultText: (OFString *)resultText
{
    [_history insertObject: [[CalculatorHistoryEntry alloc] initWithExpression: expression resultText: resultText] atIndex: 0];

    if (_history.count > 14)
        [_history removeObjectAtIndex: _history.count - 1];
}

- (bool)resolveValueForMemoryOperation: (double *)value
{
    if (_expression.length > 0) {
        @try {
            *value = [self evaluateCurrentExpression];
            return true;
        } @catch (CalculatorEvaluationException *exception) {
            [self setStatusText: exception.reason hasError: true];
            return false;
        }
    }

    if (_hasLastAnswer) {
        *value = _lastAnswer;
        return true;
    }

    [self setStatusText: @"There is no evaluated result to use for memory yet." hasError: true];
    return false;
}

- (void)setExpressionFromText: (OFString *nonnil)text
{
    _expression = [self normalizedExpressionFromText: text];
    _replaceExpressionOnNextInsert = false;
    [self refreshPreview];
}

- (void)appendDigits: (OFString *nonnil)digits
{
    if (digits.length == 0)
        @throw [OFInvalidArgumentException exception];

    [self startFreshExpressionIfNeededForToken: digits];

    if ([self expressionNeedsImplicitMultiplication])
        _expression = [_expression stringByAppendingString: @"*"];

    _expression = [_expression stringByAppendingString: digits];
    [self refreshPreview];
}

- (void)appendDecimalPoint
{
    [self startFreshExpressionIfNeededForToken: @"."];

    if (_expression.length == 0 or self.expressionEndsWithUnaryBoundary) {
        _expression = [_expression stringByAppendingString: @"0."];
        [self refreshPreview];
        return;
    }

    const OFUnichar trailingCharacter = [_expression characterAtIndex: _expression.length - 1];
    for (size_t index = _expression.length; index > 0; index--) {
        OFUnichar character = [_expression characterAtIndex: index - 1];

        if (character == '.')
            return;
        if ((character < '0' or character > '9') and character != '.')
            break;
    }

    if ((trailingCharacter >= '0' and trailingCharacter <= '9') or trailingCharacter == '.') {
        _expression = [_expression stringByAppendingString: @"."];
        [self refreshPreview];
        return;
    }

    if ([self expressionNeedsImplicitMultiplication]) {
        _expression = [_expression stringByAppendingString: @"*0."];
        [self refreshPreview];
        return;
    }

    _expression = [_expression stringByAppendingString: @"."];
    [self refreshPreview];
}

- (void)appendOperator: (OFString *nonnil)operatorText
{
    if (operatorText.length != 1)
        @throw [OFInvalidArgumentException exception];

    [self startFreshExpressionIfNeededForToken: operatorText];

    if (_expression.length == 0) {
        if ([operatorText isEqual: @"-"])
            _expression = @"-";
        else if (_hasLastAnswer)
            _expression = [[self lastAnswerDisplayText] stringByAppendingString: operatorText];
        else
            _expression = [@"0" stringByAppendingString: operatorText];

        [self refreshPreview];
        return;
    }

    if ([self expressionEndsWithOperator]) {
        _expression = [_expression substringToIndex: _expression.length - 1];
        _expression = [_expression stringByAppendingString: operatorText];
        [self refreshPreview];
        return;
    }

    if ([self expressionEndsWithUnaryBoundary] and not [operatorText isEqual: @"-"])
        return;

    _expression = [_expression stringByAppendingString: operatorText];
    [self refreshPreview];
}

- (void)appendOpenParenthesis
{
    [self appendAtomToken: @"("];
    [self refreshPreview];
}

- (void)appendCloseParenthesis
{
    [self startFreshExpressionIfNeededForToken: @")"];
    _expression = [_expression stringByAppendingString: @")"];
    [self refreshPreview];
}

- (void)appendConstantNamed: (OFString *nonnil)constantName
{
    if (constantName.length == 0)
        @throw [OFInvalidArgumentException exception];

    [self appendAtomToken: constantName];
    [self refreshPreview];
}

- (void)appendAnswerReference
{
    if (not _hasLastAnswer) {
        [self setStatusText: @"There is no ANS value yet. Evaluate something first." hasError: true];
        return;
    }

    [self appendAtomToken: @"ans"];
    [self refreshPreview];
}

- (void)appendRandomFunction
{
    [self appendAtomToken: @"rand()"];
    [self refreshPreview];
}

- (void)applyFunctionNamed: (OFString *nonnil)functionName
{
    OFString *valueToken;

    if (functionName.length == 0)
        @throw [OFInvalidArgumentException exception];

    [self startFreshExpressionIfNeededForToken: functionName];

    if (_expression.length == 0) {
        _expression = [OFString stringWithFormat: @"%@(", functionName];
        [self refreshPreview];
        return;
    }

    if ([self expressionEndsWithUnaryBoundary]) {
        _expression = [_expression stringByAppendingString: [OFString stringWithFormat: @"%@(", functionName]];
        [self refreshPreview];
        return;
    }

    valueToken = [_expression copy];
    _expression = [OFString stringWithFormat: @"%@(%@)", functionName, valueToken];
    [self refreshPreview];
}

- (void)applySquare
{
    OFString *target;

    if (_expression.length > 0)
        target = _expression;
    else if (_hasLastAnswer)
        target = @"ans";
    else {
        [self setStatusText: @"Enter or evaluate a value before squaring it." hasError: true];
        return;
    }

    _expression = [OFString stringWithFormat: @"((%@)^2)", target];
    _replaceExpressionOnNextInsert = false;
    [self refreshPreview];
}

- (void)applyReciprocal
{
    OFString *target;

    if (_expression.length > 0)
        target = _expression;
    else if (_hasLastAnswer)
        target = @"ans";
    else {
        [self setStatusText: @"Enter or evaluate a value before taking its reciprocal." hasError: true];
        return;
    }

    _expression = [OFString stringWithFormat: @"(1/(%@))", target];
    _replaceExpressionOnNextInsert = false;
    [self refreshPreview];
}

- (void)applyPercent
{
    if (_expression.length == 0 and _hasLastAnswer)
        _expression = @"ans";
    else if (_expression.length == 0) {
        [self setStatusText: @"Enter or evaluate a value before applying percent." hasError: true];
        return;
    }

    _expression = [_expression stringByAppendingString: @"%"];
    _replaceExpressionOnNextInsert = false;
    [self refreshPreview];
}

- (void)applyFactorial
{
    if (_expression.length == 0 and _hasLastAnswer)
        _expression = @"ans";
    else if (_expression.length == 0) {
        [self setStatusText: @"Enter or evaluate a value before applying factorial." hasError: true];
        return;
    }

    _expression = [_expression stringByAppendingString: @"!"];
    _replaceExpressionOnNextInsert = false;
    [self refreshPreview];
}

- (void)toggleSign
{
    if (_expression.length == 0) {
        _expression = (_hasLastAnswer ? @"-(ans)" : @"-");
        _replaceExpressionOnNextInsert = false;
        [self refreshPreview];
        return;
    }

    if ([_expression hasPrefix: @"-("] and [_expression hasSuffix: @")"] and _expression.length > 3)
        _expression = [_expression substringWithRange: OFMakeRange(2, _expression.length - 3)];
    else
        _expression = [OFString stringWithFormat: @"-(%@)", _expression];

    _replaceExpressionOnNextInsert = false;
    [self refreshPreview];
}

- (bool)evaluate
{
    double value = 0.0;
    OFString *expressionText;
    OFString *resultText;

    if (_expression.length == 0) {
        if (_hasLastAnswer) {
            _expression = [self lastAnswerDisplayText];
            _replaceExpressionOnNextInsert = true;
            [self setStatusText: @"ANS is already current." hasError: false];
            return true;
        }

        [self setStatusText: @"Enter an expression before evaluating." hasError: true];
        return false;
    }

    expressionText = [_expression copy];
    @try {
        value = [self evaluateCurrentExpression];
    } @catch (CalculatorEvaluationException *exception) {
        _resultText = @"--";
        [self setStatusText: exception.reason hasError: true];
        return false;
    }

    _lastAnswer = value;
    _hasLastAnswer = true;
    resultText = [self formattedValue: value];
    _resultText = resultText;
    _expression = resultText;
    _replaceExpressionOnNextInsert = true;
    [self recordHistoryExpression: expressionText resultText: resultText];
    [self setStatusText: @"Result committed to history. Digits start a fresh expression; operators continue from ANS." hasError: false];
    return true;
}

- (void)backspace
{
    if (_replaceExpressionOnNextInsert) {
        _replaceExpressionOnNextInsert = false;
        _expression = @"";
        [self refreshPreview];
        return;
    }

    if (_expression.length == 0)
        return;

    _expression = [_expression substringToIndex: _expression.length - 1];
    [self refreshPreview];
}

- (void)clearExpression
{
    _expression = @"";
    _replaceExpressionOnNextInsert = false;
    _resultText = [self lastAnswerDisplayText];
    [self setStatusText: (_hasLastAnswer
        ? @"Expression cleared. ANS and history are preserved."
        : @"Expression cleared.")
                 hasError: false];
}

- (void)clearAll
{
    _expression = @"";
    _resultText = @"0";
    _statusText = @"Cleared expression, ANS, and memory. History is preserved for reuse.";
    _memoryValue = 0.0;
    _lastAnswer = 0.0;
    _hasMemoryValue = false;
    _hasLastAnswer = false;
    _hasError = false;
    _replaceExpressionOnNextInsert = false;
}

- (void)toggleAngleMode
{
    _angleMode = (_angleMode == CalculatorAngleModeDegrees
        ? CalculatorAngleModeRadians
        : CalculatorAngleModeDegrees);

    if (_expression.length > 0)
        [self refreshPreview];
    else
        [self setStatusText: [OFString stringWithFormat: @"Angle mode is now %@.", self.angleModeText] hasError: false];
}

- (void)memoryClear
{
    if (not _hasMemoryValue) {
        [self setStatusText: @"Memory is already empty." hasError: false];
        return;
    }

    _memoryValue = 0.0;
    _hasMemoryValue = false;
    [self setStatusText: @"Memory cleared." hasError: false];
}

- (void)memoryRecall
{
    if (not _hasMemoryValue) {
        [self setStatusText: @"Memory is empty." hasError: true];
        return;
    }

    if (_replaceExpressionOnNextInsert)
        _expression = @"";

    if ([self expressionNeedsImplicitMultiplication])
        _expression = [_expression stringByAppendingString: @"*"];

    _expression = [_expression stringByAppendingString: [self memoryDisplayText]];
    _replaceExpressionOnNextInsert = false;
    [self refreshPreview];
}

- (void)memoryStore
{
    double value = 0.0;

    if (not [self resolveValueForMemoryOperation: &value])
        return;

    _memoryValue = value;
    _hasMemoryValue = true;
    [self setStatusText: [OFString stringWithFormat: @"Stored %@ in memory.", [self formattedValue: value]] hasError: false];
}

- (void)memoryAdd
{
    double value = 0.0;

    if (not [self resolveValueForMemoryOperation: &value])
        return;

    _memoryValue += value;
    _hasMemoryValue = true;
    [self setStatusText: [OFString stringWithFormat: @"Added %@ to memory.", [self formattedValue: value]] hasError: false];
}

- (void)memorySubtract
{
    double value = 0.0;

    if (not [self resolveValueForMemoryOperation: &value])
        return;

    _memoryValue -= value;
    _hasMemoryValue = true;
    [self setStatusText: [OFString stringWithFormat: @"Subtracted %@ from memory.", [self formattedValue: value]] hasError: false];
}

- (void)loadHistoryExpressionAtIndex: (size_t)index
{
    CalculatorHistoryEntry *entry;

    if (index >= _history.count)
        return;

    entry = [_history objectAtIndex: index];
    _expression = [entry.expression copy];
    _replaceExpressionOnNextInsert = false;
    [self refreshPreview];
}

- (void)loadHistoryResultAtIndex: (size_t)index
{
    CalculatorHistoryEntry *entry;

    if (index >= _history.count)
        return;

    entry = [_history objectAtIndex: index];
    _expression = [entry.resultText copy];
    _resultText = [entry.resultText copy];
    _replaceExpressionOnNextInsert = false;
    [self setStatusText: @"Loaded a historical result back into the working expression." hasError: false];
}

- (OFString *)angleModeText
{
    return (_angleMode == CalculatorAngleModeDegrees ? @"DEG" : @"RAD");
}

- (OFString *)memoryDisplayText
{
    if (not _hasMemoryValue)
        return @"0";

    return [self formattedValue: _memoryValue];
}

- (OFString *)lastAnswerDisplayText
{
    if (not _hasLastAnswer)
        return @"0";

    return [self formattedValue: _lastAnswer];
}

@end

#pragma clang assume_nonnull end
