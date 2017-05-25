import P, S, V,
	C, Cb, Cc, Cg, Cs, Cmt, Ct, Cf, Cp,
	locale, match, util from require'lulpeg'

import insert, remove from table

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

pconvert = (syn, src) ->
	switch syn.label
		when "synkey"
			if src then src * V'Space' * P syn[1]
			else K syn[1]
		when "objvar"
			if src then src * V'Space' * (V'Exp' / lbl_tbl syn[1])
			else V'Exp' / lbl_tbl syn[1]

(syn) ->
	macname = remove syn, 1
	macargs = remove syn, 1
	macto = remove syn, #syn

	local pcomb

	while #syn > 0
		pp = remove syn

		unless pcomb
			pcomb = pconvert pp, nil
		else
			pcomb = pconvert pp, pcomb

	pcomb

