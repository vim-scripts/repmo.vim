" Vim plugin -- repeat motions for which a count was given
" General: {{{1
" File:         repmo.vim
" Created:      2008 Jan 27
" Last Change:  2008 Mar 01
" Author:	Andy Wokula <anwoku@yahoo.de>
" Version:	0.3

" Question: BML schrieb: Is there a way/command to repeat the last movement,
"   like ; and , repeat the last f command? It would be nice to be able to
"   select the 'scrolling' speed by typing 5j or 8j, and then simply hold
"   down a key and what the text scroll by at your given speed. Ben
" Answer: No there isn't, but an exception is  :h 'scroll
"   Or take repmo.vim as an answer.  It overloads the keys ";" and "," to
"   repeat motions.

" Usage By Example:
"   Type "5j" and then ";" to repeat "5j" (after  :RepmoMap j k ).
"   Type "hjkl" and then ";", it still repeats "5j".
"   Type "," to do "5k" (go in reverse direction).
"   Type "4k" and then ";" to repeat "4k" (after  :RepmoMap k j ).
"
"   The following motions (and scroll commands) are mapped per default:
"	j,k, h,l, Ctrl-E,Ctrl-Y, zh,zl
"
" Compatibility:
"   Check out Visual mode.
"   Check out "f{char}" followed by ";," -- it should still work.
"   Check out Operator pending mode with ";" and ",".

" Commands:
"   :RepmoMap {motion} {reverse-motion}
"
"	Map {motion} to be repeatable with ";".  Use {reverse-motion} for
"	",".  Key notation is like in mappings.

" Options:		    type	default	    when checked
"   g:repmo_key		    (string)	";"	    frequently, e.g. when
"   g:repmo_revkey	    (string)	","	      \ doing "5j"
"   g:repmo_mapmotions	    (bool)	1	    when sourced
"
" see Customization for details

" Installation:
"   it's a plugin, simply :source it (e.g. :so %)

" Hints:
" - there is little error checking, don't do  :let repmo_key = " " or "|"
"   etc.
" - to unmap "f", "F", "t", "T", ";" and "," at once, simply type "ff" (for
"   example); the next "5j" maps them again
" - to avoid mapping "f", "F", "t" and "T" at all, use other keys than ";"
"   and "," for repeating
" - Debugging:  :debug normal 5j  doesn't work, use  5:<C-U>debug normal j
"   instead; but  5:<C-U>normal jjj  does  5j5j5j

" TODO:
" ? preserve remappings by user, e.g. :map j gj
"   currently these mappings are replaced without warning
" ? :RepmoMap: also accept only one argument
" + make ";" and "," again work with "f{char}", "F{char}", ...
" + v0.2 don't touch user's mappings for f/F/t/T
" + v0.2 check for empty g:repmo_key
" + check key notation: '\|' is ok, '|' not ok
"   no check added: we cannot check for everything
" + Bug: i_<C-O>l inserts rest of l-mapping in the text; for l and h
"   VimBuddy doesn't rotate it's nose ... ah, statusline is updated twice
"   ! v0.3 use  :normal {motion}  within the function

" }}}

" Script Init Folklore: {{{1
if exists("loaded_repmo")
    finish
endif
let loaded_repmo = 1

if v:version < 700 || &cp
    echo "Repmo: you need at least Vim 7 and 'nocp' set"
    finish
endif

" let s:sav_cpo = &cpo
" set cpo&vim
" " doesn't help, we need absent cpo-< all the time

" Customization: {{{1

" keys used to repeat motions:
if !exists("g:repmo_key")
    " " key notation is like in mappings:
    " let g:repmo_key = "<Space>"
    " let g:repmo_revkey = "<BS>"
    let g:repmo_key = ";"
    let g:repmo_revkey = ","
endif

" do map some motions per default (or not)
if !exists("g:repmo_mapmotions")
    let g:repmo_mapmotions = 1
endif

" Functions: {{{1

" Internal Variables: {{{
let s:lastkey = ""
let s:lastrevkey = ""
 "}}}

" Internal Mappings: "{{{
nn <sid>repmo( :<c-u>call<sid>MapRepeatMotion(0,
vn <sid>repmo( :<c-u>call<sid>MapRepeatMotion(1,

nn <silent> <sid>lastkey :<c-u>call<sid>MapRepMo(0)<cr>
vn <silent> <sid>lastkey :<c-u>call<sid>MapRepMo(1)<cr>

let s:SNR = matchstr(maparg("<sid>lastkey", "n"), '<SNR>\d\+_')
 "}}}

func! s:MapMotion(...) "{{{
    " Args: {motion} {rev-motion}
    " map the {motion} key; {motion}+{rev-motion} on RHS
    if a:0 != 2
	echoerr "Repmo: two arguments needed:  :RepmoMap" join(a:000, " ")
	return
    endif
    " really 4 extra arguments?  nmap {motion}, vmap {motion}, nmap
    " {rev-motion}, vmap {rev-motion}
    let lhs = "<script><silent> ". a:1
    let rhs = "<sid>repmo('".s:EscLt(a:1."','".a:2)."')<cr>"
    exec "nn" lhs rhs
    exec "xn" lhs rhs
endfunc "}}}
func! s:EscLt(key) "{{{
    return substitute(a:key, "<", "<lt>", "g")
endfunc "}}}

func! <sid>MapRepeatMotion(vmode, key, revkey) "{{{
    " map ";" and ","
    " remap the motion a:key to something simpler than this function
    if a:vmode
	normal! gv
    endif
    exec "normal!" (v:count ?v:count :""). s:KeyExp(a:key)

    if s:lastkey != "" && s:lastkey != a:key
	" restore "full" mapping
	call s:MapMotion(s:lastkey, s:lastrevkey)
    endif

    if v:count > 0
	" map ";" and ","
	let hasrepmo = 0
	if exists("g:repmo_key") && g:repmo_key != ''
	    exec "no" g:repmo_key v:count.a:key
	    exec "sunmap" g:repmo_key
	    let hasrepmo = 1
	endif
	if exists("g:repmo_revkey") && g:repmo_revkey != ''
	    exec "no" g:repmo_revkey v:count.a:revkey
	    exec "sunmap" g:repmo_revkey
	    let hasrepmo = 1
	endif
	if hasrepmo
	    call s:TransRepeatMaps()
	endif
    endif

    " map to leightweight func
    let lhs = "<script> ". a:key
    let rhs = "<sid>lastkey"
    exec "nn" lhs rhs
    exec "xn" lhs rhs

    let s:lastkey = a:key
    let s:lastkeynorm = s:KeyExp(a:key)
    let s:lastrevkey = a:revkey

endfunc "}}}
func! <sid>MapRepMo(vmode) "{{{
    " lightweight version of <sid>MapRepeatMotion()
    if v:count==0
	if a:vmode
	    normal! gv
	endif
	exec "normal!" s:lastkeynorm
	return
    endif
    call <sid>MapRepeatMotion(a:vmode, s:lastkey, s:lastrevkey)
endfunc "}}}

func! s:TransRepeatMaps() "{{{
    " trans is for transparent
    " check if repeating keys (e.g. ";" and ",") are overloaded, remap the
    " original commands (here: "f", "F", "t", "T")
    let cmdtype = ""
    let repmounmap = ""
    if g:repmo_key == ';' || g:repmo_revkey == ';'
	let repmounmap .= "<bar>unmap ;"
	let cmdtype = "zap"
    endif
    if g:repmo_key == ',' || g:repmo_revkey == ','
	let repmounmap .= "<bar>unmap ,"
	let cmdtype = "zap"
    endif
    " if repmounmap == ""
    "     return
    " endif
    if cmdtype == "zap"
	let cmdunmap = ""
	for zapcmd in ["f", "F", "t", "T"]
	    if !(maparg(zapcmd) == "" || maparg(zapcmd, "n") =~ s:SNR)
		continue
	    endif
	    exec "nn <script><silent>" zapcmd ":<c-u><sid>cmdunmap<cr>". zapcmd
	    exec "xn <script><silent>" zapcmd ":<c-u><sid>cmdunmap<cr>gv". zapcmd
	    " f commands ignore the count here (no prob)
	    let cmdunmap .= "<bar>unmap ". zapcmd
	endfor
	exec "cno <sid>cmdunmap" repmounmap[5:]. cmdunmap
	" cno <sid>cmdunmap
    endif
endfunc "}}}

func! s:KeyExp(key) "{{{
    " key - "<C-R>", "<CR>", ...
    " not suited for composed keys
    if a:key[0] == "<"
	exe 'return "\'.a:key.'"'
    else
	return a:key
    endif
endfunc "}}}

" Commands: {{{1
" map motions to be repeatable:
com! -nargs=* RepmoMap call s:MapMotion(<f-args>)

" Motion Mappings: {{{1
if g:repmo_mapmotions
    RepmoMap j k
    RepmoMap k j

    RepmoMap h l
    RepmoMap l h

    RepmoMap <C-E> <C-Y>
    RepmoMap <C-Y> <C-E>

    RepmoMap zh zl
    RepmoMap zl zh
endif

" Modeline: {{{1

" let &cpo = s:sav_cpo
" unlet s:sav_cpo

" Feeling:
"   The script might look a bit bloated for such a little thing, but this is
"   due the work done to make the actual mappings lightweight.  For example,
"   if you type "jjjjj", then only the first "j" will call the big function
"   MapRepeatMotion(), the others call MapRepMo().  ";" and "," are always
"   mapped directly to what they are going to repeat.

" vim:set fdm=marker ts=8:
