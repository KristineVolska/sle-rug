module Eval

import AST;
import Resolve;
import IO;

import CST2AST;
import ParseTree;
import Syntax;

data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;


alias VEnv = map[str name, Value \value];

data Input
  = input(str question, Value \value);
  
Value defaultValue(AType typeName) {
  switch (typeName) {
    case integer():
      return vint(0);
    case boolean():
      return vbool(false);
    case string():
      return vstr("");
  }
}

VEnv initialEnv(AForm f) {
  VEnv venv = ();
	for(/AQuestion q := f.questions) {
		switch(q){
			case question(_, questId(name), AType typeName):
				venv += (name: defaultValue(typeName));
			case computedQuestion(_, questId(name), AType typeName, expr):
				venv += (name: defaultValue(typeName));
		}
	}
    return venv;
}

VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for(AQuestion q <- f.questions){
    venv = eval(q, inp, venv);
    }
  return venv; 
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  switch(q) {
	case question(_, questId(name), _): {
		if (name == inp.question) {
			return(venv + (name: inp.\value));
		} else
			return(venv);
		
	}
    case computedQuestion(_, questId(name), _, expr):{
    		return(venv + (name: eval(expr, venv)));
    	}
    		
    case ifThen(AExpr expr, list[AQuestion] questions):{
      	for(AQuestion q <- questions){
        	venv = eval(q, inp, venv);
           }
        }
    
    case ifThenElse(AExpr expr, list[AQuestion] questions, list[AQuestion] questions2):{
      if(eval(expr, venv).b)
        for(AQuestion q <- questions) venv = eval(q, inp, venv);
      else
        for(AQuestion q <- questions2) venv = eval(q, inp, venv);
        }
  }
  
  return venv; 
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(questId(x)): {
	    return venv[x];
    }
    
    case boolean(bool b): return vbool(b);
    case integer(int i): return vint(i);
    case string(str s): return vstr(s);
    
    case pos(AExpr a): 
      return vint(eval(a, venv).n);
    case neg(AExpr a): 
      return vint(-eval(a, venv).n);
    case par(AExpr a): return eval(a, venv);
    
    case not(AExpr a): return vbool(!eval(a, venv).b);
    case mul(AExpr a, AExpr b): 
      return vint(eval(a, venv).n * eval(b, venv).n);
    case div(AExpr a, AExpr b): 
      return vint(eval(a, venv).n / eval(b, venv).n);
    case add(AExpr a, AExpr b): 
      return vint(eval(a, venv).n + eval(b, venv).n);
    case sub(AExpr a, AExpr b):
      return vint(eval(a, venv).n - eval(b, venv).n);
      
    case gt(AExpr a, AExpr b):
      return vbool(eval(a, venv).n > eval(b, venv).n);
    case lt(AExpr a, AExpr b):
      return vbool(eval(a, venv).n < eval(b, venv).n);
    case geq(AExpr a, AExpr b):
      return vbool(eval(a, venv).n >= eval(b, venv).n);
    case leq(AExpr a, AExpr b):
      return vbool(eval(a, venv).n <= eval(b, venv).n);
    case equ(AExpr a, AExpr b): {
      aValue = eval(a, venv);
      switch(aValue) {
        case vbool(bool aBool): return vbool(aBool == eval(b, venv).b);
        case vint(int n): return vbool(n == eval(b, venv).n);
        case vstr(str s): return vbool(s == eval(b, venv).s);
      }
    }
    case neq(AExpr a, AExpr b):{
      aValue = eval(a, venv);
      switch(aValue) {
        case vbool(bool aBool): return vbool(aBool != eval(b, venv).b);
        case vint(int n): return vbool(n != eval(b, venv).n);
        case vstr(str s): return vbool(s != eval(b, venv).s);
      }
    }
    case and(AExpr a, AExpr b): 
      return vbool(eval(a, venv).b && eval(b, venv).b);
    case or(AExpr a, AExpr b):
      return vbool(eval(a, venv).b || eval(b, venv).b);
    
    default: throw "Unsupported expression <e>";
  }
}