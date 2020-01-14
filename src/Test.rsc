module Test

import Syntax;
import AST;
import CST2AST;
import Check;
import Resolve;
import Eval;
import Compile;
import Transform;
import ParseTree;
import Message;



import Set;
import List;
import IO;

start[Form] parseTest(loc filename) {
  return parse(#start[Form], filename);
}

AForm cst2astTest(loc filename) {
  return cst2ast(parseTest(filename));
}

RefGraph resolveTest(loc filename) {
  return resolve(cst2astTest(filename));
}

/*
VEnv evalTest(loc filename) {
  ast = cst2astTest(filename);
   //println(ast);
  VEnv venv = initialEnv(ast);
  println(venv);
  list[Input] input = [
    input("hasBoughtHouse", vbool(true)),
    input("hasMaintLoan", vbool(false)),
    input("hasSoldHouse", vbool(true)),
    input("sellingPrice", vint(100)),
    input("privateDebt", vint(20))
  ];
  
  for (Input inp <- input) {
    venv = eval(ast, inp, venv);
  }
  return venv;
}
*/
set[Message] allStepTest(loc filename) {
  concrete = parse(#start[Form], filename);
  abstract = cst2ast(concrete);
  TEnv tenv = collect(abstract);
  UseDef useDef = resolve(abstract).useDef;
  return check(abstract, tenv, useDef);
}