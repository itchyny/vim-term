" =============================================================================
" Filename: autoload/term.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/11/07 21:18:28.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:default_options = [
      \ '-close', '-open', '-curwin', '-hidden', '-rows=', '-cols', '-eof'
      \ ]

let s:custom_options = [
      \ '-opener='
      \ ]

function! term#new(...) abort
  let [term_args, other_args] = s:parse_cmdargs(a:000)
  execute get(other_args, 'opener', '')
  execute 'terminal' s:build_term_args(term_args)
endfunction

function! s:normalize_cmdarg(arg) abort
  let key = substitute(substitute(a:arg, '^-\+', '', 'g'), '=.*', '', 'g')
  return a:arg =~# '=' ? [key, substitute(a:arg, '^.*=', '', 'g')] : [key, v:true]
endfunction

function! s:is_default_option(key) abort
  return len(filter(copy(s:default_options), 'v:val =~# "^-\\+" . a:key')) > 0
endfunction

function! s:parse_cmdargs(args) abort
  let term_args = {}
  let other_args = {}
  for arg in a:args
    let [key, val] = s:normalize_cmdarg(arg)
    if s:is_default_option(key)
      let term_args[key] = val
    else
      let other_args[key] = val
    endif
  endfor
  return [term_args, other_args]
endfunction

function! s:build_term_args(args) abort
  return join(map(keys(a:args), '"++" . (a:args[v:val] == v:true ? v:val : v:val . "=" . a:args[v:val])'), ' ')
endfunction

function! term#complete(arglead, cmdline, cursorpos) abort
  return sort(filter(copy(s:default_options) + copy(s:custom_options), 'stridx(v:val, a:arglead) != -1'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
