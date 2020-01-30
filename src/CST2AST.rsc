module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import Boolean;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return cst2ast(f); 
}

AForm cst2ast(f:(Form)`form <Id id> { <Question* questions> }`) {
  return form("<id>", [ cst2ast(question) | Question question <- questions], src = f@\loc);
}

AQuestion cst2ast(Question q) {
  switch (q) {
    case (Question)`<Str label> <Id questId> : <Type typeName>`: return question("<label>", cst2ast(questId), cst2ast(typeName), src=q@\loc);
    case (Question)`<Str label> <Id questId> : <Type typeName> = <Expr expression>`: return computedQuestion("<label>", cst2ast(questId), cst2ast(typeName), cst2ast(expression), src=q@\loc);
	case (Question)`{ <Question* questions> }` : return block([cst2ast(question) | Question question <- questions], src = q@\loc); 
    case (Question)`if ( <Expr expression> ) { <Question* questions> }`: return ifThen(cst2ast(expression), [cst2ast(question) | Question question <- questions], src=q@\loc); 
    case (Question)`if ( <Expr expression> ) { <Question* questions1> } else { <Question* questions2> }`: return ifThenElse(cst2ast(expression), [cst2ast(question) | Question question <- questions1], [cst2ast(question) | Question question <- questions2], src=q@\loc);
    default: throw "Unhandled question: <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref(questId("<x>", src=x@\loc), src=x@\loc);
    case (Expr)`<Bool b>`: return boolean(fromString("<b>"), src=b@\loc);
    case (Expr)`<Str text>`: return string("<text>", src=text@\loc);   
    case (Expr)`<Int i>`: return integer(toInt("<i>"), src=i@\loc);
    
    case (Expr)`+ <Expr expression>`: return pos(cst2ast(expression), src=expression@\loc);
    case (Expr)`- <Expr expression>`: return neg(cst2ast(expression), src=expression@\loc);
       
    case (Expr)`( <Expr expression> )`: return par(cst2ast(expression), src=expression@\loc);
    case (Expr)`! <Expr expression>`: return not(cst2ast(expression), src=expression@\loc);
    case (Expr)`<Expr multiplicand> * <Expr multiplier>`: return mul(cst2ast(multiplicand), cst2ast(multiplier), src=e@\loc);
    case (Expr)`<Expr numerator> / <Expr denominator>`: return div(cst2ast(numerator), cst2ast(denominator), src=e@\loc);
    case (Expr)`<Expr left> + <Expr right>`: return add(cst2ast(left), cst2ast(right), src=e@\loc);
    case (Expr)`<Expr left> - <Expr right>`: return sub(cst2ast(left), cst2ast(right), src=e@\loc);
    
    case (Expr)`<Expr left> \< <Expr right>`: return lt(cst2ast(left), cst2ast(right), src=e@\loc); 
    case (Expr)`<Expr left> \<= <Expr right>`: return leq(cst2ast(left), cst2ast(right), src=e@\loc);  
    case (Expr)`<Expr left> \> <Expr right>`: return gt(cst2ast(left), cst2ast(right), src=e@\loc);
    case (Expr)`<Expr left> \>= <Expr right>`: return geq(cst2ast(left), cst2ast(right), src=e@\loc);
    case (Expr)`<Expr left> == <Expr right>`: return equ(cst2ast(left), cst2ast(right), src=e@\loc);
    case (Expr)`<Expr left> != <Expr right>`: return neq(cst2ast(left), cst2ast(right), src=e@\loc);

    case (Expr)`<Expr left> && <Expr right>`: return and(cst2ast(left), cst2ast(right), src=e@\loc);
    case (Expr)`<Expr left> || <Expr right>`: return or(cst2ast(left), cst2ast(right), src=e@\loc);
    default: throw "Unhandled expression: <e>";
  }
}

AId cst2ast(Id x) {
  return questId("<x>", src=x@\loc);
}

AType cst2ast(Type t) {
  switch(t) {
    case (Type)`boolean`: return boolean(src=t@\loc);
    case (Type)`integer`: return integer(src=t@\loc);
    case (Type)`string`: return string(src=t@\loc);
    default: throw "Unhandled type: <t>";
  }
}
