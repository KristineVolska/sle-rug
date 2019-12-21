module Syntax

extend lang::std::Layout;
extend lang::std::Id;

start syntax Form 
  = "form" Id formName "{" Statement* formElements"}";

syntax Statement 
  = question: Question question
  | ifCondition: IfPart ifPart ElsePart? elsePart
  ;
  
syntax Conditional = conditional: Expr condition "{" Statement+ body "}" ;

syntax IfPart = "if" Conditional ifPart;

syntax ElsePart = elsePart: "else" "{" Statement+ body "}";

start syntax Question 
  = question: QuestionText questionText Id id ":" Type answerDataType
  | question: QuestionText questionText Id id ":" Type answerDataType "=" Expr calculatedField
  ;

syntax Expr
  = id: Id name \ "true" \ "false" //iznem ara ari citus keywordus! (keyword Reserved)
  | \int: Int number
  | boolean: Bool truthValue
  | string: Str text
  | bracket "(" Expr expression ")"
  | pos: "+" Expr pos
  | neg: "-" Expr neg
  | not: "!" Expr not
  > left (
      mul: Expr multiplicand "*" Expr multiplier
    | div: Expr numerator "/" Expr denominator
  )
  > left (
      add: Expr leftAddend "+" Expr rightAddend
    | sub: Expr minuend "-" Expr subtrahend
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

lexical QuestionText = questionText: Str questionText ;
lexical Str = "\"" TextChar* "\"";
lexical TextChar = [\\] << [\"] | ![\"];
lexical Int 
  = [0-9]+ !>> [0-9] ;

lexical Bool = 
  "true" | "false";


syntax Type = booleanType: "boolean"
  | integerType: "integer"
  | stringType: "string"
  ;