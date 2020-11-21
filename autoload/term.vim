" =============================================================================
" Filename: autoload/term.vim
" Author: itchyny
" License: MIT License
" Last Change: 2020/11/21 10:43:36.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:default_flags = [
      \ '-close', '-open', '-curwin', '-hidden', '-rows=', '-cols', '-eof'
      \ ]

let s:custom_flags = [
      \ '-opener=', '-restore', '-autocd', '-reporoot',
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
      elseif s:is_custom_flags(key)
        let custom_flags[key] = val
      else
        call add(args, arg)
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

function! s:is_custom_flags(key) abort
  return !empty(filter(copy(s:custom_flags), 'v:val =~# "^-\\+" . a:key'))
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
  if get(self.custom_flags, 'reporoot', v:false)
    let git_root = s:git_root(expand('%:p:h'))
    if git_root != ''
      execute 'lcd' git_root
    endif
  endif
  execute 'terminal' self.build_term_flags() join(self.args, ' ')
endfunction

function! s:term.restore() dict abort
  for winnr in range(1, winnr('$'))
    let bufnr = winbufnr(winnr)
    if getbufvar(bufnr, '&buftype') ==# 'terminal' && self.match_reporoot(bufnr)
      execute winnr 'wincmd w'
      return
    endif
  endfor
  for bufnr in term_list()
    if self.match_reporoot(bufnr)
      execute get(self.custom_flags, 'opener', 'new')
      execute 'buffer' bufnr
      return
    endif
  endfor
  execute get(self.custom_flags, 'opener', '')
  call self.invoke()
endfunction

function! s:term.match_reporoot(bufnr) dict abort
  if !get(self.custom_flags, 'reporoot', v:false)
    return 1
  endif
  let git_root = s:git_root(expand('%:p:h'))
  let pid = job_info(term_getjob(a:bufnr)).process
  let maybe_dir = self.get_job_cwd(pid)
  return git_root !=# '' && stridx(maybe_dir, git_root) == 0
        \ && maybe_dir[len(git_root):] =~# '^$\|^[/\\]'
        \ || git_root ==# '' && maybe_dir ==# expand('%:p:h')
endfunction

function! s:term.autocd() dict abort
  let bufnr = bufnr('')
  let pid = job_info(term_getjob(bufnr)).process
  let maybe_dir = self.get_job_cwd(pid)
  if isdirectory(maybe_dir) && self.current_dir !=# maybe_dir
    let procs = self.get_procs()
    let command = ''
    let child_commands = []
    for proc in procs
      if proc.pid ==# pid
        let command = proc.command
      elseif proc.ppid ==# pid
        call add(child_commands, proc.command)
      endif
    endfor
    if empty(filter(child_commands, 'v:val !=# command'))
      let dir = fnamemodify(self.current_dir, ':~')
      call term_sendkeys(bufnr, "\<C-k>cd " . fnameescape(dir) . "\<CR>")
    endif
  endif
endfunction

function! s:term.get_job_cwd(pid) dict abort
  let out = split(system('lsof -a -p ' . a:pid . ' -d cwd'), '\n')
  if len(out) != 2
    return ''
  endif
  let i = match(out[0], 'NAME')
  if i < 0
    return ''
  endif
  return out[1][i:]
endfunction

function! s:term.get_procs() dict abort
  let out = system('ps -o ppid,pid,comm')
  let procs = []
  for line in split(out, '\n')
    let m = matchlist(line, '\v^\s*(\d+) +(\d+) +(.*)')
    if len(m) > 3
      call add(procs, { 'ppid': m[1], 'pid': m[2], 'command': m[3] })
    endif
  endfor
  return procs
endfunction

function! s:git_root(path) abort
  let path = a:path
  let prev = ''
  while path !=# prev
    if getftype(path . '/.git') !=# ''
      return path
    endif
    let prev = path
    let path = fnamemodify(path, ':h')
  endwhile
  return ''
endfunction

function! term#complete(arglead, cmdline, cursorpos) abort
  return sort(filter(copy(s:default_flags) + copy(s:custom_flags), 'stridx(v:val, a:arglead) != -1'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
