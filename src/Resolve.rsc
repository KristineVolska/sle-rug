module Resolve

import Set;
import List;
import IO;
import AST;
 import util::Math;
 
/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

Use uses(AForm f) {
  Use uses = {};
  visit(f) {
    case ref(AId id): uses += {<id.src, id.name>};
  }
  return uses;
}

Def defs(AForm f) {
  Def defs = {};
  visit(f) {
    case question(str text, AId id, AType typ): defs += {<id.name, id.src>};
    case computedQuestion(str text, AId id, AType \type, AExpr expr): defs += {<id.name, id.src>};
  }
  return defs;
}