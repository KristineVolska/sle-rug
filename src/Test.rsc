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


VEnv evalTest(loc filename) {
  ast = cst2astTest(filename);
  VEnv venv = initialEnv(ast);
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
  ast = flatten(ast);
  compile(ast);  
  return venv;
  
}

set[Message] allStepTillCheckTest(loc filename) {
  concrete = parse(#start[Form], filename);
  abstract = cst2ast(concrete);
  TEnv tenv = collect(abstract);
  UseDef useDef = resolve(abstract).useDef;
  return check(abstract, tenv, useDef);
}

void runExamples(bool applyFlatten){
  examples_folder = |project://QL/examples|;
  entries = listEntries(examples_folder);
  errorList = [];
  for(e <- entries, /.*\.myql/ := e){
    src_file = find(e, [examples_folder]);
    parseTree = parse(#start[Form], src_file);
	ast = cst2ast(parseTree);
	refGraph = resolve(ast);
	tEnv = collect(ast);
	errorMsgs = check(ast, tEnv, refGraph.useDef);
	if(msg <- errorMsgs, error(_,_) := msg){
	    println("\nDid not compile <e> due to errors: <errorMsgs>\n");
	} else {
	    if(applyFlatten) ast = flatten(ast);
	    compile(ast);
	    println("Compiled <e>");
    } 
  }
 }