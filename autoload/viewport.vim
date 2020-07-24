let s:cpo_save = &cpo
set cpo&vim

function! viewport#FileExtension() abort
  return 'vp'
endfunction

let &cpo = s:cpo_save
unlet! s:cpo_save

" vim: set filetype=vim foldmethod=marker foldlevel=0 nowrap:
