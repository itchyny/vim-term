" =============================================================================
" Filename: autoload/term.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/11/07 21:50:46.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:default_flags = [
      \ '-close', '-open', '-curwin', '-hidden', '-rows=', '-cols', '-eof'
      \ ]

let s:custom_flags = [
      \ '-opener=', '-restore'
      \ ]

function! term#new(...) abort
  call s:new_term(a:000).exec()
endfunction

let s:term = {}

function! s:new_term(args) abort
  let [term_flags, custom_flags] = s:parse_cmdargs(a:args)
  return extend(copy(s:term), { 'term_flags': term_flags, 'custom_flags': custom_flags })
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

function! s:normalize_cmdarg(arg) abort
  let key = substitute(substitute(a:arg, '^-\+', '', 'g'), '=.*', '', 'g')
  return a:arg =~# '=' ? [key, substitute(a:arg, '^.*=', '', 'g')] : [key, v:true]
endfunction

function! s:is_default_flags(key) abort
  return !empty(filter(copy(s:default_flags), 'v:val =~# "^-\\+" . a:key'))
endfunction

function! s:term.exec() dict abort
  if get(self.custom_flags, 'restore', v:false)
    call self.restore()
  else
    execute get(self.custom_flags, 'opener', '')
    execute 'terminal' self.build_term_flags()
  endif
endfunction

function! s:term.build_term_flags() dict abort
  let args = self.term_flags
  if get(self.custom_flags, 'opener', '') !=# ''
    let args['curwin'] = v:true
  endif
  return join(map(keys(args), '"++" . (args[v:val] == v:true ? v:val : v:val . "=" . args[v:val])'), ' ')
endfunction

function! s:term.restore() dict abort
  for nr in range(1, winnr('$'))
    if getbufvar(winbufnr(nr), '&buftype') ==# 'terminal'
      execute nr 'wincmd w'
      break
    endif
  endfor
  if &buftype !=# 'terminal'
    execute get(self.custom_flags, 'opener', '')
    if empty(term_list())
      execute 'terminal' self.build_term_flags()
    else
      execute 'buffer' term_list()[0]
    endif
  endif
endfunction

function! term#complete(arglead, cmdline, cursorpos) abort
  return sort(filter(copy(s:default_flags) + copy(s:custom_flags), 'stridx(v:val, a:arglead) != -1'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
