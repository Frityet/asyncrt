#include <ctype.h>
#include <float.h>
#include <math.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#if defined(__APPLE__)
#   import <objc/runtime.h>
#else
#   import <ObjFWRT/ObjFWRT.h>
#endif

#import "CalculatorEvaluator.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface CalculatorParser : OFObject

- (instancetype)initWithExpression: (OFString *)expression
                         angleMode: (CalculatorAngleMode)angleMode
                        lastAnswer: (double)lastAnswer [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

- (double)angleInputForValue: (double)value;
- (double)angleOutputForValue: (double)value;
- (double)parseResult;

@end

[[subclassing_restricted, direct_members]]
@interface MathsException : OFException

@property(readonly, copy, nonatomic) OFString *reason;
@property(readonly, copy, nonatomic) OFString *function;

- (instancetype)initWithFunction: (OFString *nonnil)function reason: (OFString *nonnil)reason;

@end

@implementation CalculatorEvaluationException

- (instancetype)initWithReason: (OFString *)reason
{
    self = [super init];
    _reason = [reason copy];
    return self;
}

- (OFString *)description
{
    return _reason;
}

@end

@implementation MathsException

- (instancetype)initWithFunction: (OFString *)function reason: (OFString *)reason
{
    self = [super init];
    _reason = [reason copy];
    _function = [function copy];
    return self;
}

@end

@class CalculatorParser;

// Calculator math helpers used by function-call parsing.
[[subclassing_restricted, direct_members]]
@interface MathsFunctions : OFObject

- (instancetype)initWithParser: (CalculatorParser *nonnil)parser [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;

- (double)evaluateFunctionNamed: (OFString *nonnil)name
                  argumentCount: (size_t)argumentCount
                      arguments: (const double *nonnil)arguments;
- (OFDictionary<OFString *, OFNumber *> *)constants;

- (double)rand;
- (double)pow: (double)base exponent: (double)exponent;
- (double)min: (double)a b: (double)b;
- (double)max: (double)a b: (double)b;
- (double)mod: (double)a b: (double)b;
- (double)sin: (double)value;
- (double)cos: (double)value;
- (double)tan: (double)value;
- (double)asin: (double)value;
- (double)acos: (double)value;
- (double)atan: (double)value;
- (double)sinh: (double)value;
- (double)cosh: (double)value;
- (double)tanh: (double)value;
- (double)ln: (double)value;
- (double)log: (double)value;
- (double)exp: (double)base;
- (double)sqrt: (double)value;
- (double)abs: (double)value;
- (double)floor: (double)value;
- (double)ceil: (double)value;
- (double)round: (double)value;
- (double)cbrt: (double)value;

@end


[[direct_members]]
@implementation CalculatorParser {
    OFString *_expression;
    const char *_source;
    size_t _index;
    size_t _length;
    CalculatorAngleMode _angleMode;
    OFString *nillable _error;
    MathsFunctions *_mathsFunctions;
    @public double lastAnswer;
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
                        lastAnswer: (double)aw
{
    self = [super init];
    _expression = [expression copy];
    _source = _expression.UTF8String;
    _index = 0;
    _length = strlen(_source);
    _angleMode = angleMode;
    lastAnswer = aw;
    _mathsFunctions = [[MathsFunctions alloc] initWithParser: self];
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

    [self skipWhitespace];

    if (_index >= _length)
        return false;
    if (((_source[_index] < '0' or _source[_index] > '9') and _source[_index] != '.'))
        return false;

    const double parsed = strtod(_source + _index, &end);
    if (end == _source + _index)
        return false;

    _index = (size_t)(end - _source);
    *value = parsed;
    return true;
}

- (OFString *nillable)readIdentifier
{
    [self skipWhitespace];

    if (_index >= _length or not [CalculatorParser isIdentifierHead: _source[_index]])
        return nilptr;

    const size_t start = _index;
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

    @try {
        value = [_mathsFunctions evaluateFunctionNamed: name
                                         argumentCount: argumentCount
                                             arguments: arguments];
    } @catch (MathsException *exception) {
        self.errorMessage = exception.reason;
        return false;
    }

    if (not [self ensureFiniteValue: value])
        return false;

    *result = value;
    return true;
}

- (bool)constantNamed: (OFString *)name result: (double *)result
{
    OFNumber *constant = _mathsFunctions.constants[name];

    if (constant != nilptr) {
        *result = constant.doubleValue;
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
    if (not [self parseMultiplicativeValue: value])
        return false;

    while (true) {
        const char operatorCharacter = [self peekCharacter];
        if (operatorCharacter != '+' and operatorCharacter != '-')
            return true;

        _index++;
        double rhs = 0.0;
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
    if (not [self parsePrefixValue: value])
        return false;

    while (true) {
        const char operatorCharacter = [self peekCharacter];
        if (operatorCharacter != '*' and operatorCharacter != '/')
            return true;

        _index++;
        double rhs = 0.0;
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
    if (not [self parsePostfixValue: value])
        return false;

    if (not [self matchCharacter: '^'])
        return true;

    double exponent = 0.0;
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

    OFString *nillable identifier = [self readIdentifier];
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

- (double)parseResult
{
    if (_length == 0) {
        @throw [[CalculatorEvaluationException alloc] initWithReason: @"Enter an expression."];
    }

    double result = 0.0;

    if (not [self parseExpressionValue: &result])
        @throw [[CalculatorEvaluationException alloc] initWithReason: (_error ?: @"Expression error.")];

    [self skipWhitespace];
    if (_index != _length)
        @throw [[CalculatorEvaluationException alloc] initWithReason: @"Unexpected trailing input."];

    if (not [self ensureFiniteValue: result])
        @throw [[CalculatorEvaluationException alloc] initWithReason: (_error ?: @"Result overflowed the calculator range.")];

    return result;
}

@end

@implementation MathsFunctions {
    unretained CalculatorParser *_parser;
}

- (instancetype)initWithParser: (CalculatorParser *nonnil)parser
{
    self = [super init];
    _parser = parser;
    return self;
}

- (bool)method: (Method)method
matchesFunctionNamed: (OFString *nonnil)name
  argumentCount: (size_t)argumentCount
        selector: (SEL *)selector
{
    char *returnType = method_copyReturnType(method);
    const bool returnsDouble = (returnType != nullptr and strcmp(returnType, "d") == 0);

    free(returnType);
    if (not returnsDouble)
        return false;

    if (method_getNumberOfArguments(method) != argumentCount + 2)
        return false;

    const SEL reflectedSelector = method_getName(method);
    const char *selectorName = sel_getName(reflectedSelector);
    if (selectorName == nullptr)
        return false;

    for (unsigned int index = 0; index < argumentCount; index++) {
        char *argumentType = method_copyArgumentType(method, index + 2);
        const bool argumentMatches = (argumentType != nullptr and strcmp(argumentType, "d") == 0);

        free(argumentType);
        if (not argumentMatches)
            return false;
    }

    const char *separator = strchr(selectorName, ':');
    OFString *selectorBaseName = [OFString stringWithUTF8String: selectorName];
    if (separator != nullptr)
        selectorBaseName = [selectorBaseName substringToIndex: (size_t)(separator - selectorName)];

    if (not [selectorBaseName isEqual: name])
        return false;

    if (selector != nullptr)
        *selector = reflectedSelector;

    return true;
}

- (double)evaluateFunctionNamed: (OFString *nonnil)name
                  argumentCount: (size_t)argumentCount
                      arguments: (const double *nonnil)arguments
{
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(self.class, &methodCount);

    @try {
        for (unsigned int index = 0; index < methodCount; index++) {
            SEL selector = nullptr;

            if (not [self method: methods[index]
             matchesFunctionNamed: name
                   argumentCount: argumentCount
                         selector: &selector])
                continue;

            IMP implementation = method_getImplementation(methods[index]);

            switch (argumentCount) {
                case 0:
                    return ((double (*)(id, SEL))implementation)(self, selector);
                case 1:
                    return ((double (*)(id, SEL, double))implementation)(self, selector, arguments[0]);
                case 2:
                    return ((double (*)(id, SEL, double, double))implementation)(self, selector, arguments[0], arguments[1]);
                default:
                    @throw [[MathsException alloc] initWithFunction: name
                                                             reason: [OFString stringWithFormat: @"Unsupported number of arguments for function %@.", name]];
            }
        }

        @throw [[MathsException alloc] initWithFunction: name
                                                 reason: [OFString stringWithFormat: @"Unknown function %@.", name]];
    } @finally {
        free(methods);
    }
}

- (OFDictionary<OFString *, OFNumber *> *)constants
{
    return @{
        @"pi": @(M_PI),
        @"e": @(M_E),
        @"tau": @(M_PI * 2.0),
        @"ans": @(_parser->lastAnswer),
    };
}

- (double)rand
{ return ((double)arc4random()) / ((double)UINT32_MAX); }

- (double)pow: (double)base exponent: (double)exponent
{ return pow(base, exponent); }

- (double)min: (double)a b: (double)b
{ return fmin(a, b); }

- (double)max: (double)a b: (double)b
{
    return fmax(a, b);
}

- (double)mod: (double)a b: (double)b
{
    if (b == 0.0)
        @throw [[MathsException alloc] initWithFunction: @"mod" reason: @"mod(x, 0) is undefined."];
    return fmod(a, b);
}

- (double)sin: (double)value
{
    return sin([_parser angleInputForValue: value]);
}

- (double)cos: (double)value
{
    return cos([_parser angleInputForValue: value]);
}

- (double)tan: (double)value
{
    double angle = [_parser angleInputForValue: value];

    if (fabs(cos(angle)) < 1e-12)
        @throw [[MathsException alloc] initWithFunction: @"tan" reason: @"tan(x) is undefined for angles where cos(x) = 0."];

    return tan(angle);
}

- (double)asin: (double)value
{
    if (value < -1.0 or value > 1.0)
        @throw [[MathsException alloc] initWithFunction: @"asin" reason: @"asin(x) is only defined for -1 <= x <= 1."];
    return [_parser angleOutputForValue: asin(value)];
}

- (double)acos: (double)value
{
    if (value < -1.0 or value > 1.0)
        @throw [[MathsException alloc] initWithFunction: @"acos" reason: @"acos(x) is only defined for -1 <= x <= 1."];
    return [_parser angleOutputForValue: acos(value)];
}

- (double)atan: (double)value
{
    return [_parser angleOutputForValue: atan(value)];
}

- (double)sinh: (double)value
{
    return sinh(value);
}

- (double)cosh: (double)value
{
    return cosh(value);
}

- (double)tanh: (double)value
{
    return tanh(value);
}

- (double)ln: (double)value
{
    if (value <= 0.0)
        @throw [[MathsException alloc] initWithFunction: @"ln" reason: @"ln(x) requires x > 0."];
    return log(value);
}

- (double)log: (double)value
{
    if (value <= 0.0)
        @throw [[MathsException alloc] initWithFunction: @"log" reason: @"log(x) requires x > 0."];
    return log10(value);
}

- (double)exp: (double)value
{
    return exp(value);
}

- (double)sqrt: (double)value
{
    if (value < 0.0)
        @throw [[MathsException alloc] initWithFunction: @"sqrt" reason: @"sqrt(x) requires x >= 0."];
    return sqrt(value);
}

- (double)abs: (double)value
{
    return fabs(value);
}

- (double)floor: (double)value
{
    return floor(value);
}

- (double)ceil: (double)value
{
    return ceil(value);
}

- (double)round: (double)value
{
    return round(value);
}

- (double)cbrt: (double)value
{
    return cbrt(value);
}

@end

@namespace_implementation(CalculatorEvaluator)

+ (double)evaluateExpression: (OFString *nonnil)expression
                  angleMode: (CalculatorAngleMode)angleMode
                 lastAnswer: (double)lastAnswer
{
    auto parser = [[CalculatorParser alloc] initWithExpression: expression
                                                     angleMode: angleMode
                                                    lastAnswer: lastAnswer];
    return [parser parseResult];
}

@end

#pragma clang assume_nonnull end
