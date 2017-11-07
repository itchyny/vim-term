" =============================================================================
" Filename: autoload/term.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/11/07 20:56:23.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:default_options = [
      \ '-close', '-open', '-curwin', '-hidden', '-rows=', '-cols', '-eof'
      \ ]

function! term#new(...) abort
  let term_args = map(filter(copy(a:000), 'v:val =~# "^-\\+"'),
        \ 'substitute(v:val, "^-\\+", "++", "g")')
  let other_args = filter(copy(a:000), 'v:val !~# "^-\\+"')
  execute join(other_args, ' ')
  execute 'terminal' join(term_args, ' ')
endfunction

function! term#complete(arglead, cmdline, cursorpos) abort
  return sort(filter(copy(s:default_options), 'stridx(v:val, a:arglead) != -1'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
