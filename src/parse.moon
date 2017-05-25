import P, S, V,
	C, Cb, Cc, Cg, Cs, Cmt, Ct, Cf, Cp,
	locale, match, pprint from require'lulpeg'

import insert, remove from table

syncompile = require'syncompile'

locale = locale!
K = (k) -> P(k) * -(locale.alnum + P'_')
CV = (pat) -> C V pat
CK = (pat) -> C K pat
CP = (pat) -> C P pat
CtV = (pat) -> Ct V pat
opt = (pat) -> (pat)^-1
ast = (pat) -> (pat)^0

lbl_tbl = (lbl, ...) ->
	tags = {...}
	(...) -> with args = {label: lbl, ...}
		if type(args[1]) == "string" and #args[1] < 1
			remove args, 1
		else for i = 1, #args
			if t = tags[i]
				cont = args[i]
				args[t] = cont if #cont > 0
				args[i] = nil

parse = (msg, ext) ->
	vexp = V'Funcall' + V'Fun' + V'Let' + V'Expa' + (CV'Number' / lbl_tbl'number') + (V'String' / lbl_tbl'string' ) + V'Var'

	if ext
		vexp = ext + vexp

		pprint ext

	grammar = P{
		CtV'L' * V'Space' * -P(1)
		Space: ast(locale.space)
		Keywords: K'mac' + K'let' + K'in'
		L: ast(V'Space' * (V'Exp' + V'Mac'))
		Exp: vexp
		Expa: P'{' * (V'Space' * V'Exp')^1 * V'Space' * P'}'
		Name: (locale.alnum + P'_')^1 - V'Keywords'
		Var: (CV'Name' / lbl_tbl'var') + (P'$' * CV'Name' / lbl_tbl'objvar') + (P'<' * CV'Name' * P'>' / lbl_tbl'synkey')

		Number:
			P'0x' * (locale.xdigit)^1 * -(locale.alnum + P'_') +
			locale.digit^1 * opt(P'.' * locale.digit^1) * opt(S'eE' * locale.digit^1) * -(locale.alnum + P'_') +
			P'.' * locale.digit^1 * opt(S'eE' * locale.digit^1) * -(locale.alnum + P'_')

		Longstring:
			C P{
				V'open' * C(ast(P(1) - V'closeeq')) * V'close' / 2
				open: '[' * Cg(ast(P'='), 'init') * P'[' * opt(P'\n')
				close: ']' * C(ast(P'=')) * ']'
				closeeq: Cmt(V'close' * Cb'init', (_, _, a, b) -> a == b)
			}

		String:
			(((P"\"" * C(ast(P"\\" * P(1) + (1 - P"\""))) * P"\"") +
			(P"'" * C(ast(P"\\" * P(1) + (1 - P"'"))) * P"'")) / (str) -> "\"#{str}\"") +
			(V"Longstring" / (a) -> a)

		Let: K'let' * V'Space' * CV'Name' * V'Space' * P'=' * V'Space' * V'Exp' * V'Space' * K'in' * V'Space' * V'Exp' / lbl_tbl'let'
		Fun: P'\\' * opt(CV'Name') * P'.' * V'Space' * V'Exp' / lbl_tbl'fun'
		Funcall: (V'Expa' + V'Var') * (V'Space' * P'(' * V'Space' * ( V'Exp' * ast(V'Space' * P',' * V'Space' * V'Exp') + opt(V'Exp')) * V'Space' * P')')^1 / lbl_tbl'funcall'
		Mac: V'PlainMac' + V'Newsyntax'
		PlainMac: K'mac' * V'Space' * CV'Name' * V'Space' * V'Exp' / lbl_tbl'mac'

		Newsyntax:
			Cmt(K'mac' * V'Space' * CV'Name' * V'Space' *
				P'[' * V'Space' * ((CV'Name' * ast(V'Space' * P',' * V'Space' * CV'Name')) / lbl_tbl'macargs') * V'Space' * P']' *
				V'Space' * P'{|' * (V'Space' * V'Exp')^1 * V'Space' * P'<|' * V'Space' * ((V'Exp' + V'Expa') / lbl_tbl'macto') * V'Space' * P'|>' * V'Space' * P'|}' / lbl_tbl'newsyntax',
				(input, idx, matched) ->
					idx, parse (input\sub idx, #input + 1), syncompile matched
			)
	}

	tree = {grammar\match msg}
	pprint grammar

	if h = tree[1]
		#tree > 1 and tree or h
	else nil, "Failed to parse"

parse
