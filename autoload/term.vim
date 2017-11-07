" =============================================================================
" Filename: autoload/term.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/11/08 06:09:29.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:default_flags = [
      \ '-close', '-open', '-curwin', '-hidden', '-rows=', '-cols', '-eof'
      \ ]

let s:custom_flags = [
      \ '-opener=', '-restore', '-autocd'
      \ ]

function! term#new(...) abort
  call s:new_term(a:000).exec()
endfunction

let s:term = {}

function! s:new_term(args) abort
  let [term_flags, custom_flags, args] = s:parse_cmdargs(a:args)
  return extend(copy(s:term), {
        \ 'term_flags': term_flags,
        \ 'custom_flags': custom_flags,
        \ 'args': args,
        \ 'current_dir': expand('%:p:h'),
        \ })
endfunction

function! s:parse_cmdargs(args) abort
  let term_flags = {}
  let custom_flags = {}
  let args = []
  for arg in a:args
    if arg[0] ==# '-'
      let [key, val] = s:normalize_cmdarg(arg)
      if s:is_default_flags(key)
        let term_flags[key] = val
      else
        let custom_flags[key] = val
      endif
    else
      call add(args, arg)
    endif
  endfor
  return [term_flags, custom_flags, args]
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
    call self.invoke()
  endif
  if get(self.custom_flags, 'autocd', v:false)
    call self.autocd()
  endif
endfunction

function! s:term.build_term_flags() dict abort
  let args = self.term_flags
  if get(self.custom_flags, 'opener', '') !=# ''
    let args['curwin'] = v:true
  endif
  return join(map(keys(args), '"++" . (args[v:val] == v:true ? v:val : v:val . "=" . args[v:val])'), ' ')
endfunction

function! s:term.invoke() dict abort
  execute 'terminal' self.build_term_flags() join(self.args, ' ')
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
      call self.invoke()
    else
      execute 'buffer' term_list()[0]
    endif
  endif
endfunction

function! s:term.autocd() dict abort
  let bufnr = bufnr('')
  let maybe_dir = self.get_job_cwd(term_getjob(bufnr))
  if isdirectory(maybe_dir) && self.current_dir !=# maybe_dir
    let dir = fnamemodify(self.current_dir, ':~')
    call term_sendkeys(bufnr, 'cd ' . fnameescape(dir) . "\<CR>")
  endif
endfunction

function! s:term.get_job_cwd(job) dict abort
  let job_info = job_info(a:job)
  let out = split(system('lsof -a -p ' . job_info.process . ' -d cwd'), '\n')
  if len(out) != 2
    return ''
  endif
  let i = match(out[0], 'NAME')
  if i < 0
    return ''
  endif
  return out[1][i:]
endfunction

function! term#complete(arglead, cmdline, cursorpos) abort
  return sort(filter(copy(s:default_flags) + copy(s:custom_flags), 'stridx(v:val, a:arglead) != -1'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
