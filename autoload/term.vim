" =============================================================================
" Filename: autoload/term.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/11/07 21:28:19.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:default_flags = [
      \ '-close', '-open', '-curwin', '-hidden', '-rows=', '-cols', '-eof'
      \ ]

let s:custom_flags = [
      \ '-opener='
      \ ]

function! term#new(...) abort
  let [term_flags, custom_flags] = s:parse_cmdargs(a:000)
  execute get(custom_flags, 'opener', '')
  execute 'terminal' s:build_term_flags(term_flags)
endfunction

function! s:normalize_cmdarg(arg) abort
  let key = substitute(substitute(a:arg, '^-\+', '', 'g'), '=.*', '', 'g')
  return a:arg =~# '=' ? [key, substitute(a:arg, '^.*=', '', 'g')] : [key, v:true]
endfunction

function! s:is_default_flags(key) abort
  return len(filter(copy(s:default_flags), 'v:val =~# "^-\\+" . a:key')) > 0
endfunction

function! s:parse_cmdargs(args) abort
  let term_flags = {}
  let custom_flags = {}
  for arg in a:args
    let [key, val] = s:normalize_cmdarg(arg)
    if s:is_default_flags(key)
      let term_flags[key] = val
    else
      let custom_flags[key] = val
    endif
  endfor
  return [term_flags, custom_flags]
endfunction

function! s:build_term_flags(args) abort
  return join(map(keys(a:args), '"++" . (a:args[v:val] == v:true ? v:val : v:val . "=" . a:args[v:val])'), ' ')
endfunction

function! term#complete(arglead, cmdline, cursorpos) abort
  return sort(filter(copy(s:default_flags) + copy(s:custom_flags), 'stridx(v:val, a:arglead) != -1'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
