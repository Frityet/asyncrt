#include <ctype.h>
#include <float.h>
#include <math.h>
#include <stdint.h>
#include <stdlib.h>

#import "CalculatorEvaluator.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface CalculatorParser : OFObject

- (instancetype)initWithExpression: (OFString *)expression
                         angleMode: (CalculatorAngleMode)angleMode
                        lastAnswer: (double)lastAnswer [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

- (bool)parseResult: (double *)result error: (OFString *nillable *)error;

@end

[[direct_members]]
@implementation CalculatorParser {
    OFString *_expression;
    const char *_source;
    size_t _index;
    size_t _length;
    CalculatorAngleMode _angleMode;
    double _lastAnswer;
    OFString *nillable _error;
}

+ (bool)isIdentifierHead: (char)character
{
    return (character == '_' or (character >= 'A' and character <= 'Z') or (character >= 'a' and character <= 'z'));
}

+ (bool)isIdentifierTail: (char)character
{
    return [CalculatorParser isIdentifierHead: character] or (character >= '0' and character <= '9');
}

- (instancetype)initWithExpression: (OFString *)expression
                         angleMode: (CalculatorAngleMode)angleMode
                        lastAnswer: (double)lastAnswer
{
    self = [super init];
    _expression = [expression copy];
    _source = _expression.UTF8String;
    _index = 0;
    _length = strlen(_source);
    _angleMode = angleMode;
    _lastAnswer = lastAnswer;
    return self;
}

- (void)setErrorMessage: (OFString *)message
{
    if (_error == nilptr)
        _error = [message copy];
}

- (void)skipWhitespace
{
    while (_index < _length and isspace((unsigned char)_source[_index]) != 0)
        _index++;
}

- (char)peekCharacter
{
    [self skipWhitespace];

    if (_index >= _length)
        return '\0';
    return _source[_index];
}

- (bool)matchCharacter: (char)character
{
    [self skipWhitespace];

    if (_index >= _length or _source[_index] != character)
        return false;

    _index++;
    return true;
}

- (bool)readNumber: (double *)value
{
    char *end = nullptr;
    double parsed;

    [self skipWhitespace];

    if (_index >= _length)
        return false;
    if (((_source[_index] < '0' or _source[_index] > '9') and _source[_index] != '.'))
        return false;

    parsed = strtod(_source + _index, &end);
    if (end == _source + _index)
        return false;

    _index = (size_t)(end - _source);
    *value = parsed;
    return true;
}

- (OFString *nillable)readIdentifier
{
    size_t start;

    [self skipWhitespace];

    if (_index >= _length or not [CalculatorParser isIdentifierHead: _source[_index]])
        return nilptr;

    start = _index;
    _index++;

    while (_index < _length and [CalculatorParser isIdentifierTail: _source[_index]])
        _index++;

    return [[_expression substringWithRange: OFMakeRange(start, _index - start)] lowercaseString];
}

- (bool)ensureFiniteValue: (double)value
{
    if (isfinite(value))
        return true;

    self.errorMessage = @"Result overflowed the calculator range.";
    return false;
}

- (double)angleInputForValue: (double)value
{
    if (_angleMode == CalculatorAngleModeDegrees)
        return value * (M_PI / 180.0);
    return value;
}

- (double)angleOutputForValue: (double)value
{
    if (_angleMode == CalculatorAngleModeDegrees)
        return value * (180.0 / M_PI);
    return value;
}

- (bool)factorialOfValue: (double)value result: (double *)result
{
    double rounded = round(value);
    double accumulator = 1.0;

    if (value < 0.0 or fabs(value - rounded) > 1e-9) {
        self.errorMessage = @"Factorial is only defined for whole numbers >= 0.";
        return false;
    }

    if (rounded > 170.0) {
        self.errorMessage = @"Factorial is too large to represent.";
        return false;
    }

    for (size_t index = 2; index <= (size_t)rounded; index++)
        accumulator *= (double)index;

    if (not [self ensureFiniteValue: accumulator])
        return false;

    *result = accumulator;
    return true;
}

- (bool)applyFunctionNamed: (OFString *)name
              argumentCount: (size_t)argumentCount
                  arguments: (const double *)arguments
                     result: (double *)result
{
    double value = 0.0;

    if ([name isEqual: @"rand"]) {
        if (argumentCount != 0) {
            self.errorMessage = @"rand() does not take arguments.";
            return false;
        }

        *result = ((double)arc4random()) / ((double)UINT32_MAX);
        return true;
    }

    if ([name isEqual: @"pow"] or [name isEqual: @"min"] or [name isEqual: @"max"] or [name isEqual: @"mod"]) {
        if (argumentCount != 2) {
            self.errorMessage = [OFString stringWithFormat: @"%@ expects two arguments.", name];
            return false;
        }

        if ([name isEqual: @"pow"])
            value = pow(arguments[0], arguments[1]);
        else if ([name isEqual: @"min"])
            value = fmin(arguments[0], arguments[1]);
        else if ([name isEqual: @"max"])
            value = fmax(arguments[0], arguments[1]);
        else {
            if (arguments[1] == 0.0) {
                self.errorMessage = @"mod(x, 0) is undefined.";
                return false;
            }
            value = fmod(arguments[0], arguments[1]);
        }

        if (not [self ensureFiniteValue: value])
            return false;

        *result = value;
        return true;
    }

    if (argumentCount != 1) {
        self.errorMessage = [OFString stringWithFormat: @"%@ expects one argument.", name];
        return false;
    }

    if ([name isEqual: @"sin"])
        value = sin([self angleInputForValue: arguments[0]]);
    else if ([name isEqual: @"cos"])
        value = cos([self angleInputForValue: arguments[0]]);
    else if ([name isEqual: @"tan"])
        value = tan([self angleInputForValue: arguments[0]]);
    else if ([name isEqual: @"asin"])
        value = [self angleOutputForValue: asin(arguments[0])];
    else if ([name isEqual: @"acos"])
        value = [self angleOutputForValue: acos(arguments[0])];
    else if ([name isEqual: @"atan"])
        value = [self angleOutputForValue: atan(arguments[0])];
    else if ([name isEqual: @"sinh"])
        value = sinh(arguments[0]);
    else if ([name isEqual: @"cosh"])
        value = cosh(arguments[0]);
    else if ([name isEqual: @"tanh"])
        value = tanh(arguments[0]);
    else if ([name isEqual: @"ln"]) {
        if (arguments[0] <= 0.0) {
            self.errorMessage = @"ln(x) requires x > 0.";
            return false;
        }
        value = log(arguments[0]);
    } else if ([name isEqual: @"log"]) {
        if (arguments[0] <= 0.0) {
            self.errorMessage = @"log(x) requires x > 0.";
            return false;
        }
        value = log10(arguments[0]);
    } else if ([name isEqual: @"exp"])
        value = exp(arguments[0]);
    else if ([name isEqual: @"sqrt"]) {
        if (arguments[0] < 0.0) {
            self.errorMessage = @"sqrt(x) requires x >= 0.";
            return false;
        }
        value = sqrt(arguments[0]);
    } else if ([name isEqual: @"abs"])
        value = fabs(arguments[0]);
    else if ([name isEqual: @"floor"])
        value = floor(arguments[0]);
    else if ([name isEqual: @"ceil"])
        value = ceil(arguments[0]);
    else if ([name isEqual: @"round"])
        value = round(arguments[0]);
    else if ([name isEqual: @"cbrt"])
        value = cbrt(arguments[0]);
    else {
        self.errorMessage = [OFString stringWithFormat: @"Unknown function %@.", name];
        return false;
    }

    if (not [self ensureFiniteValue: value])
        return false;

    *result = value;
    return true;
}

- (bool)constantNamed: (OFString *)name result: (double *)result
{
    if ([name isEqual: @"pi"]) {
        *result = M_PI;
        return true;
    }
    if ([name isEqual: @"e"]) {
        *result = M_E;
        return true;
    }
    if ([name isEqual: @"tau"]) {
        *result = M_PI * 2.0;
        return true;
    }
    if ([name isEqual: @"ans"]) {
        *result = _lastAnswer;
        return true;
    }

    self.errorMessage = [OFString stringWithFormat: @"Unknown symbol %@.", name];
    return false;
}

- (bool)parseExpressionValue: (double *)value
{
    return [self parseAdditiveValue: value];
}

- (bool)parseAdditiveValue: (double *)value
{
    double rhs;
    char operatorCharacter;

    if (not [self parseMultiplicativeValue: value])
        return false;

    while (true) {
        operatorCharacter = [self peekCharacter];
        if (operatorCharacter != '+' and operatorCharacter != '-')
            return true;

        _index++;
        if (not [self parseMultiplicativeValue: &rhs])
            return false;

        if (operatorCharacter == '+')
            *value += rhs;
        else
            *value -= rhs;

        if (not [self ensureFiniteValue: *value])
            return false;
    }
}

- (bool)parseMultiplicativeValue: (double *)value
{
    double rhs;
    char operatorCharacter;

    if (not [self parsePrefixValue: value])
        return false;

    while (true) {
        operatorCharacter = [self peekCharacter];
        if (operatorCharacter != '*' and operatorCharacter != '/')
            return true;

        _index++;
        if (not [self parsePrefixValue: &rhs])
            return false;

        if (operatorCharacter == '*')
            *value *= rhs;
        else {
            if (rhs == 0.0) {
                self.errorMessage = @"Division by zero is undefined.";
                return false;
            }
            *value /= rhs;
        }

        if (not [self ensureFiniteValue: *value])
            return false;
    }
}

- (bool)parsePrefixValue: (double *)value
{
    if ([self matchCharacter: '+'])
        return [self parsePrefixValue: value];

    if ([self matchCharacter: '-']) {
        if (not [self parsePrefixValue: value])
            return false;

        *value = -*value;
        return true;
    }

    return [self parsePowerValue: value];
}

- (bool)parsePowerValue: (double *)value
{
    double exponent;

    if (not [self parsePostfixValue: value])
        return false;

    if (not [self matchCharacter: '^'])
        return true;

    if (not [self parsePrefixValue: &exponent])
        return false;

    *value = pow(*value, exponent);
    return [self ensureFiniteValue: *value];
}

- (bool)parsePostfixValue: (double *)value
{
    if (not [self parsePrimaryValue: value])
        return false;

    while (true) {
        if ([self matchCharacter: '%']) {
            *value /= 100.0;
            continue;
        }

        if ([self matchCharacter: '!']) {
            if (not [self factorialOfValue: *value result: value])
                return false;
            continue;
        }

        return true;
    }
}

- (bool)parsePrimaryValue: (double *)value
{
    OFString *nillable identifier;
    double arguments[2] = {0.0, 0.0};
    size_t argumentCount = 0;

    if ([self matchCharacter: '(']) {
        if (not [self parseExpressionValue: value])
            return false;
        if (not [self matchCharacter: ')']) {
            self.errorMessage = @"Missing closing ')'.";
            return false;
        }
        return true;
    }

    if ([self readNumber: value])
        return [self ensureFiniteValue: *value];

    identifier = [self readIdentifier];
    if (identifier == nilptr) {
        self.errorMessage = @"Expected a number, symbol, or opening '('.";
        return false;
    }

    if (not [self matchCharacter: '('])
        return [self constantNamed: $assert_nonnil(identifier) result: value];

    if (not [self matchCharacter: ')']) {
        while (true) {
            if (argumentCount >= 2) {
                self.errorMessage = @"This calculator supports up to two function arguments.";
                return false;
            }

            if (not [self parseExpressionValue: &arguments[argumentCount]])
                return false;

            argumentCount++;
            if (not [self matchCharacter: ','])
                break;
        }

        if (not [self matchCharacter: ')']) {
            self.errorMessage = @"Missing closing ')' after function arguments.";
            return false;
        }
    }

    return [self applyFunctionNamed: $assert_nonnil(identifier)
                      argumentCount: argumentCount
                          arguments: arguments
                             result: value];
}

- (bool)parseResult: (double *)result error: (OFString *nillable *)error
{
    if (_length == 0) {
        if (error != nullptr)
            *error = @"Enter an expression.";
        return false;
    }

    if (not [self parseExpressionValue: result]) {
        if (error != nullptr)
            *error = (_error ?: @"Expression error.");
        return false;
    }

    [self skipWhitespace];
    if (_index != _length) {
        if (error != nullptr)
            *error = @"Unexpected trailing input.";
        return false;
    }

    if (not [self ensureFiniteValue: *result]) {
        if (error != nullptr)
            *error = (_error ?: @"Result overflowed the calculator range.");
        return false;
    }

    if (error != nullptr)
        *error = nilptr;
    return true;
}

@end

@namespace_implementation(CalculatorEvaluator)

+ (bool)evaluateExpression: (OFString *nonnil)expression
                 angleMode: (CalculatorAngleMode)angleMode
                lastAnswer: (double)lastAnswer
                    result: (double *nonnil)result
                     error: (OFString *nillable *)error
{
    CalculatorParser *parser;

    parser = [[CalculatorParser alloc] initWithExpression: expression
                                                       angleMode: angleMode
                                                      lastAnswer: lastAnswer];
    return [parser parseResult: result error: error];
}

@end

#pragma clang assume_nonnull end
