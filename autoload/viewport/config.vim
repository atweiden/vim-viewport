let s:cpo_save = &cpo
set cpo&vim

function! viewport#config#StartMark() abort
  return get(g:, 'viewport_start_mark', 't')
endfunction

function! viewport#config#EndMark() abort
  return get(g:, 'viewport_end_mark', 'y')
endfunction

let &cpo = s:cpo_save
unlet! s:cpo_save

" vim: set filetype=vim foldmethod=marker foldlevel=0 nowrap:
