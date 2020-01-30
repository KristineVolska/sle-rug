module Compile

import List;
import Map;
import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */


void compile(AForm f) {
	writeFile(f.src[extension="js"].top, form2js(f));
	writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) {
	return html(
			head(title(f.name)),
			body(
				div(
					lang::html5::DOM::id("app") +
					[question2html(q) | q <- f.questions]
				),
				script(src("https://cdn.jsdelivr.net/npm/vue/dist/vue.js")),
				script(src(f.src[extension="js"].file))
			)
		);
}

HTML5Attr inputType(AType typ) {
	switch(typ) {
		case boolean(): return \type("checkbox");
		case integer(): return \type("number");
		case string(): return \type("text");
	}
}

HTML5Node question2html(AQuestion q) {
	switch (q) {
		case question(desc, questId(name), AType typ): {
			modelAttr = "v-model" + (typ == integer() ? ".number" : "");
			attributes = [html5attr(modelAttr, name), inputType(typ)];
			return div(
				label(
					desc,
					input(attributes)
				)
			);
		}
		case computedQuestion(desc, questId(name), AType typ, expr): {
			modelAttr = "v-model" + (typ == integer() ? ".number" : "");
			attributes = [html5attr(modelAttr, name), inputType(typ)];
			attributes = push(readonly("readonly"), attributes);
			return div(
				label(
					desc,
					input(attributes)
				)
			);
		}
		case ifThen(expr, list[AQuestion] questions): {
			return fieldset(mapper(questions, question2html));
		}
		case ifThenElse(AExpr cond, AQuestion qTrue, AQuestion qFalse): {
			elTrue = question2html(qTrue);
			elFalse = question2html(qFalse);
			return div(
				div(push(html5attr("v-if", jsExpr(cond)), elTrue.kids)),
				div(push(html5attr("v-else-if", true), elFalse.kids))
			);
		}
	}
}

str map2jsMap(map[&K, &V] m) {
	return "{ <itoString(m)[1..-1]> }";
}

str map2jsFunctionMap(map[&K, &V] m) {
	return "{" + intercalate(",", ["<name>() { return <expr>; }" | <name, expr> <- toList(m)]) + "}";
}

alias InputQuestions = map[str, value];
alias ComputedQuestions = map[str, value];
alias QuestionData = tuple[InputQuestions, ComputedQuestions];

value defaultValue(boolean()) = false;
value defaultValue(integer()) = 0;
value defaultValue(string()) = "";

QuestionData collectQuestions(AForm f) {
	inputs = (
			name: defaultValue(t) | /question(_, questId(name), AType t, empty()) <- f
	);
	computed = (
			name: jsExpr(expr) | /question(_, questId(name), _, AExpr expr) <- f,
			expr != empty()
	);
	return <inputs, computed>;
}

str jsExpr(string(s)) = s;
str jsExpr(integer(i)) = "<i>";
str jsExpr(boolean(b)) = toString(b);

str jsExpr(AExpr e) {
  switch (e) {
    case ref(questId(x)): return "this.<x>";
		case par(AExpr expr): return "(<jsExpr(expr)>)";
		case pos(AExpr expr): return "<jsExpr(expr)>";
		case neg(AExpr expr): return "-<jsExpr(expr)>";
		
		case not(AExpr expr): return "!<jsExpr(expr)>";
		case mul(AExpr l, AExpr r): return "<jsExpr(l)> * <jsExpr(r)>";
		case div(AExpr l, AExpr r): return "<jsExpr(l)> / <jsExpr(r)>";
		case add(AExpr l, AExpr r): return "<jsExpr(l)> + <jsExpr(r)>";
		case sub(AExpr l, AExpr r): return "<jsExpr(l)> - <jsExpr(r)>";
		
		case gt(AExpr l, AExpr r): return "<jsExpr(l)> \> <jsExpr(r)>";
		case geq(AExpr l, AExpr r): return "<jsExpr(l)> \>= <jsExpr(r)>";
		case lt(AExpr l, AExpr r): return "<jsExpr(l)> \< <jsExpr(r)>";
		case leq(AExpr l, AExpr r): return "<jsExpr(l)> \<= <jsExpr(r)>";
		case equ(AExpr l, AExpr r): return "<jsExpr(l)> == <jsExpr(r)>";
		case neq(AExpr l, AExpr r): return "<jsExpr(l)> != <jsExpr(r)>";
		
		case and(AExpr l, AExpr r): return "<jsExpr(l)> && <jsExpr(r)>";
		case or(AExpr l, AExpr r): return "<jsExpr(l)> || <jsExpr(r)>";
		
    default: throw "Unsupported expression <e>";
  }
}

str form2js(AForm f) {
	<inputs, computed> = collectQuestions(f);
	return
	"var app = new Vue({
	'	el: \'#app\',
	'	data: <map2jsMap(inputs)>,
	'	computed: <map2jsFunctionMap(computed)>
	'})";
}
