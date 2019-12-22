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

start[Form] parseTest(loc filename) {
  return parse(#start[Form], filename);
}

AForm cst2astTest(loc filename) {
  return cst2ast(parseTest(filename));
}

RefGraph resolveTest(loc filename) {
  return resolve(cst2astTest(filename));
}

RefGraph allStepTest(loc filename) {
  concrete = parse(#start[Form], filename);
  abstract = cst2ast(concrete);
  refGraph = resolve(abstract);
  return refGraph;
}