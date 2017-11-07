" =============================================================================
" Filename: plugin/term.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/11/07 20:12:00.
" =============================================================================

if exists('g:loaded_term') || v:version < 800 || !has('terminal')
  finish
endif
let g:loaded_term = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* -complete=customlist,term#complete
      \ Term call term#new(<f-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
