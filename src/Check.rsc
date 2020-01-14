module Check

import IO;
import AST;
import Resolve;
import Message;
import Set; 

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` )
TEnv collect(AForm f) = {
  return {<def, id.name, label, toType(t)> | /question(str label, AId id, AType t, src = loc def) <- f}
      +  {<def, id.name, label, toType(t)> | /computedQuestion(str label, AId id, AType t, AExpr _, src = loc def) <- f};
}; //TODO: test if nothing's missing 

// Convert AST type to Check type
Type toType(boolean()) = tbool();
Type toType(integer()) = tint();
Type toType(string()) = tstr();
default Type toType(AType _) = tunknown();

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
	set[Message] msgs = {};
	for (/AQuestion q := f.questions) {
		msgs += check(q, tenv, useDef);
	}
	for (/AExpr e := f) {
		msgs += check(e, tenv, useDef);
	}
	return msgs;
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
	switch (q) { // name, label, text, identifier...............?? Different names used but could mean the same
		case question(str text, AId questId, _, src = loc l): {
			return  { error("Declared question with the same name but different type", l) | size((tenv<1,3>)[questId.name]) > 1}
			+	{ warning("Duplicate labels", l) | size((tenv<2,0>)[q.text]) > 1}
			+	{ warning("Different labels for the same question", l) | size((tenv<1,2>)[questId.name]) > 1};
		}
		case computedQuestion(str text, AId questId, AType t, AExpr expr, src = loc l):{
			return { error("Declared question with the same name but different type", l) | size((tenv<1,3>)[questId.name]) > 1}
			+	{ warning("Duplicate labels", l) | size((tenv<2,0>)[q.text]) > 1}
			+	{ warning("Different labels for the same question", l) | size((tenv<1,2>)[questId.name]) > 1}
			+	{ error("The declared type computed question does not match the type of the expression", l)
  					| toType(t) != typeOf(expr, tenv, useDef) && typeOf(expr, tenv, useDef) != tunknown() }  // "tunknown()" could be removed... depends on required scenario
  			+   check(expr, tenv, useDef);
		}
        case ifThen(AExpr expr, _, src = loc l): {
			return { error("Condition is not of type boolean", l) | typeOf(expr, tenv, useDef) != tbool()};
		}
	    case ifThenElse(AExpr expr, _, _, src = loc l): {
			return { error("Condition is not of type boolean", l) | typeOf(expr, tenv, useDef) != tbool()};
		}
	}
	return {};
} 

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs),
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
    case not(AExpr expr, src = loc u):
      msgs += { error("Unary negation operand is not of type boolean", u)
                | typeOf(expr, tenv, useDef) != tbool() };
    case mul(AExpr l, AExpr r, src = loc u): {
      msgs += { error("Multiplication operands are not of type int", u) | typeOf(l, tenv, useDef) != tint() || typeOf(r, tenv, useDef) != tint() };}
    case div(AExpr l, AExpr r, src = loc u): {
      msgs += { error("Division operands are not of type int", u) | typeOf(l, tenv, useDef) != tint() || typeOf(r, tenv, useDef) != tint() };}
    case add(AExpr l, AExpr r, src = loc u): {
      msgs += { error("Addition operands are not of type int", u) | typeOf(l, tenv, useDef) != tint() || typeOf(r, tenv, useDef) != tint() };}
    case sub(AExpr l, AExpr r, src = loc u): {
      msgs += { error("Subtraction operands are not of type int", u) | typeOf(l, tenv, useDef) != tint() || typeOf(r, tenv, useDef) != tint() };}
    case gt(AExpr l, AExpr r, src = loc u): {
      msgs += { error("Comparison operands are not of type int", u) | typeOf(l, tenv, useDef) != tint() || typeOf(r, tenv, useDef) != tint() };}
    case geq(AExpr l, AExpr r, src = loc u): {
      msgs += { error("Comparison operands are not of type int", u) | typeOf(l, tenv, useDef) != tint() || typeOf(r, tenv, useDef) != tint() };}
    case lt(AExpr l, AExpr r, src = loc u): {
      msgs += { error("Comparison operands are not of type int", u) | typeOf(l, tenv, useDef) != tint() || typeOf(r, tenv, useDef) != tint() };}
    case leq(AExpr l, AExpr r, src = loc u): {
      msgs += { error("Comparison operands are not of type int", u) | typeOf(l, tenv, useDef) != tint() || typeOf(r, tenv, useDef) != tint() };}
	case equ(AExpr l, AExpr r, src = loc u):
	  msgs += { error("Equality comparison operands are not of the same type", u) | typeOf(l, tenv, useDef) != typeOf(r, tenv, useDef) };
	case neq(AExpr l, AExpr r, src = loc u):
      msgs += { error("Inequality comparison operands are not of the same type", u) | typeOf(l, tenv, useDef) != typeOf(r, tenv, useDef) };
	case and(AExpr l, AExpr r, src = loc u):
      msgs += { error("Logical AND operands are not of type bool", u) | typeOf(l, tenv, useDef) != tbool() || typeOf(r, tenv, useDef) != tbool() };
	case or(AExpr l, AExpr r, src = loc u):
      msgs += { error("Logical OR operands are not of type bool", u) | typeOf(l, tenv, useDef) != tbool() || typeOf(r, tenv, useDef) != tbool() };
  }
  return msgs; 
}

Type typeOf(string(_)) = tstr();
Type typeOf(integer(_)) = tint();
Type typeOf(boolean(_)) = tbool();

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(questId(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    case \int(int i, src = loc u): return tint();	
    case boolean(bool b, src = loc u): return tbool();
    case string(str text, src = loc u): return tstr();
    case par(AExpr expression): return typeOf(expression, tenv, useDef);
    case not(_): return tbool();
    case mul(_, _): return tint();
    case div(_, _): return tint();
    case add(_, _): return tint();
    case sub(_, _): return tint();
    case gt(_, _): return tbool();
    case gte(_, _): return tbool();
    case lt(_, _): return tbool();
    case lte(_, _): return tbool();
    case equ(_, _): return tbool();
    case neq(_, _): return tbool();
    case and(_, _): return tbool();
    case or(_, _): return tbool();
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 
