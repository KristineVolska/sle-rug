module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = question(str text, AId questId, AType typeName)
  | computedQuestion(str text, AId questId, AType typeName, AExpr expression)
  | block(list[AQuestion] questions)
  | ifThen(AExpr expression, list[AQuestion] questions)
  | ifThenElse(AExpr expression, list[AQuestion] questions1, list[AQuestion] questions2)
  ;

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | \int(int i)
  | boolean(bool b)
  | string(str text)
  
  | pos(AExpr posValue)
  | neg(AExpr negValue)
  | par(AExpr expression)
  
  | not(AExpr notValue)
  | mul(AExpr multiplicand, AExpr multiplier)
  | div(AExpr numerator, AExpr denominator)
  | add(AExpr left, AExpr right)
  | sub(AExpr left, AExpr right)
  
  | lt(AExpr left, AExpr right)
  | leq(AExpr left, AExpr right)
  | gt(AExpr left, AExpr right)
  | geq(AExpr left, AExpr rigt)
  | equ(AExpr left, AExpr right)
  | neq(AExpr left, AExpr right)
  
  | and(AExpr left, AExpr right)
  | or(AExpr left, AExpr right)
  ;

data AId(loc src = |tmp:///|)
  = questId(str name);

data AType(loc src = |tmp:///|)
  = boolean()
  | integer()
  | string();