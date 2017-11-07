" =============================================================================
" Filename: autoload/term.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/11/07 20:18:33.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! term#new(...) abort
  let term_args = filter(copy(a:000), 'v:val[:1] ==# "++"')
  let other_args = filter(copy(a:000), 'v:val[:1] !=# "++"')
  execute join(other_args, ' ')
  execute 'terminal' join(term_args, ' ')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
