let s:cpo_save = &cpo
set cpo&vim

function! viewport#error#BufferDNE(address) abort
  echohl ErrorMsg
  echomsg "[viewport]: Sorry, buffer " . a:address . " does not exist"
  echohl Normal
endfunction

function! viewport#error#BufferModified() abort
  echohl ErrorMsg
  echomsg "[viewport]: target buffer modified, use w! to overwrite"
  echohl Normal
endfunction

function! viewport#error#MarkDeleted(at, address) abort
  echohl WarningMsg
  echomsg "[viewport]: Sorry, " . a:at . " mark \"" . a:address . "\" was deleted, aborting"
  echohl Normal
endfunction

function! viewport#error#MarkNonDistinct() abort
  echohl WarningMsg
  echomsg "[viewport]: Sorry, starting mark and ending mark must be distinct"
  echohl Normal
endfunction

function! viewport#error#MarkReserved() abort
  echohl WarningMsg
  echomsg "[viewport]: Sorry, this mark is reserved for viewport"
  echohl Normal
  return
endfunction

function! viewport#error#NoModifiable() abort
  echohl ErrorMsg
  echomsg "[viewport]: Sorry, cannot make changes, 'modifiable' is off in target"
  echohl None
endfunction

let &cpo = s:cpo_save
unlet! s:cpo_save

" vim: set filetype=vim foldmethod=marker foldlevel=0 nowrap:
