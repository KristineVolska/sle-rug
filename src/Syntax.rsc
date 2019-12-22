module Syntax

extend lang::std::Layout;
extend lang::std::Id;

start syntax Form 
  = "form" Id formName "{" Question* formElements"}"
  ; 

syntax Question
  =  Str Id ":" Type
  | Str Id ":" Type "=" Expr
  | block: "{" Question* "}"
  | ifthen: "if (" Expr ") {" Question* "}"
  | ifthenelse: "if (" Expr ") {" Question* "}" "else" "{" Question* "}"
  ;

syntax Expr
  = id: Id name \ "true" \ "false"
  | \int: Int
  | boolean: Bool value
  | string: Str text
  | bracket "(" Expr ")"
  | pos: "+" Expr
  | neg: "-" Expr
  | not: "!" Expr
  > left (
      mul: Expr multiplicand "*" Expr multiplier
    | div: Expr numerator "/" Expr denominator
  )
  > left (
      add: Expr left "+" Expr right
    | sub: Expr left "-" Expr right
  )
  > non-assoc (
      lt: Expr left "\<" Expr right
    | leq: Expr left "\<=" Expr right
    | gt: Expr left "\>" Expr right
    | geq: Expr left "\>=" Expr right
    | equ: Expr left "==" Expr right
    | neq: Expr left "!=" Expr right
  )
  > left and: Expr left "&&" Expr right
  > left or: Expr left "||" Expr right
  ;

lexical Str = "\"" TextChar* "\"";
lexical TextChar = [\\] << [\"] | ![\"];
lexical Int = [0-9]+ !>> [0-9];
lexical Bool = "true" | "false";

syntax Type = booleanType: "boolean"
  | integerType: "integer"
  | stringType: "string"
  ;