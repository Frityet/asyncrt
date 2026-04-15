#pragma once

#import "CalculatorEvaluator.h"

#pragma clang assume_nonnull begin

[[subclassing_restricted, direct_members]]
@interface CalculatorHistoryEntry : OFObject

@property(readonly, copy, nonatomic) OFString *expression;
@property(readonly, copy, nonatomic) OFString *resultText;

- (instancetype)initWithExpression: (OFString *)expression resultText: (OFString *)resultText;

@end

[[subclassing_restricted, direct_members]]
@interface CalculatorModel : OFObject

@property(readonly, copy, nonatomic) OFString *expression;
@property(readonly, copy, nonatomic) OFString *resultText;
@property(readonly, copy, nonatomic) OFString *statusText;
@property(readonly, copy, nonatomic) OFArray<CalculatorHistoryEntry *> *history;
@property(readonly, nonatomic) CalculatorAngleMode angleMode;
@property(readonly, nonatomic) double memoryValue;
@property(readonly, nonatomic) double lastAnswer;
@property(readonly, nonatomic) bool hasMemoryValue;
@property(readonly, nonatomic) bool hasLastAnswer;
@property(readonly, nonatomic) bool hasError;

- (void)setExpressionFromText: (OFString *nonnil)text;
- (void)appendDigits: (OFString *nonnil)digits;
- (void)appendDecimalPoint;
- (void)appendOperator: (OFString *nonnil)operatorText;
- (void)appendOpenParenthesis;
- (void)appendCloseParenthesis;
- (void)appendConstantNamed: (OFString *nonnil)constantName;
- (void)appendAnswerReference;
- (void)appendRandomFunction;
- (void)applyFunctionNamed: (OFString *nonnil)functionName;
- (void)applySquare;
- (void)applyReciprocal;
- (void)applyPercent;
- (void)applyFactorial;
- (void)toggleSign;
- (bool)evaluate;
- (void)backspace;
- (void)clearExpression;
- (void)clearAll;
- (void)toggleAngleMode;

- (void)memoryClear;
- (void)memoryRecall;
- (void)memoryStore;
- (void)memoryAdd;
- (void)memorySubtract;

- (void)loadHistoryExpressionAtIndex: (size_t)index;
- (void)loadHistoryResultAtIndex: (size_t)index;

- (OFString *)angleModeText;
- (OFString *)memoryDisplayText;
- (OFString *)lastAnswerDisplayText;

@end

#pragma clang assume_nonnull end
