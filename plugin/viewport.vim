" ViewPort - View buffer of selected part of a target buffer
" -----------------------------------------------------------------------------
" Maintainer: Jorengarenar, © 2019
" Original Author: Marcin Szamotulski, © 2012
" License: Vim-License, see :help license

" Init: {{{1
if exists("g:loaded_ViewPort")
    finish
endif

if !exists("g:viewport_split_vertical")
    let g:viewport_split_vertical = 0
endif

if !exists("g:viewport_start_mark")
    let g:viewport_start_mark = "t"
endif

if !exists("g:viewport_end_mark")
    let g:viewport_end_mark = "y"
endif

if g:viewport_start_mark == g:viewport_end_mark
    echohl WarningMsg
    echomsg "[ViewPort]: starting mark and ending mark have to be distinct"
    echohl Normal
endif

function! viewport#cannot_mark() abort
    echohl WarningMsg
    echomsg "[ViewPort]: You cannot use this mark - it's reserved for ViewPoint"
    echohl Normal
    return
endfunction

execute "map m".g:viewport_start_mark." :call viewport#cannot_mark()<CR>"
execute "map m".g:viewport_end_mark." :call viewport#cannot_mark()<CR>"

" Hidden: {{{1
function! s:Read() abort " {{{2
    let s_view = winsaveview()
    let c_pos = getpos(".")
    let c_bufnr = bufnr("%")
    let hid = &hid
    set hid
    let address = b:viewport_address
    execute "keepalt b ".b:viewport_address[0]
    let s_pos = getpos(address[1])
    let e_pos = getpos(address[2])
    if s_pos == [0, 0, 0, 0]
        execute "keepalt b ".c_bufnr
        let &hid = hid
        " XXX: I could make this work with :echomsg.
        echoerr "[ViewPort]: the begin mark \"".address[1]."\" was deleted, aborting."
        return
    elseif e_pos == [0, 0, 0, 0]
        execute "keepalt b ".c_bufnr
        let &hid = hid
        echoerr "[ViewPort]: the end mark \"".address[2]."\" was deleted, aborting."
        return
    elseif s_pos[1] > e_pos[1]
        let address[1:2] = [ address[2], address[1] ]
        let [ s_pos, e_pos ] = [ e_pos, s_pos ]
    endif
    let lines = getbufline(address[0], s_pos[1], e_pos[1])
    execute "keepalt b ".c_bufnr
    let &hid = hid
    %d_
    call append(1, lines)
    0d_
    let c_line = min([c_pos[1], len(lines)])
    call cursor(c_line, 0)
    call winrestview(s_view)
    let b:viewport_lines = lines
    setlocal nomod
endf

function! s:Write() abort" {{{2

    silent preserve

    let lines = getbufline("%", 0, "$")
    let address = b:viewport_address
    let vp_lines = b:viewport_lines
    let winnr = bufwinnr(b:viewport_address[0])
    let winview = winsaveview()
    if winnr != -1
        let c_winnr = winnr()
        execute winnr."wincmd w"
    else
        let c_bufnr = bufnr("%")
        let hid = &hid
        set hid
        try
            execute "buffer ".address[0]
        catch /E86:/
            echohl ErrorMsg
            echomsg "[ViewPort]: buffer ".address[0]." does not exists"
            echohl Normal
            return
        endtry
    endif
    let s_pos = getpos(address[1])
    let e_pos = getpos(address[2])
    if s_pos == [0, 0, 0, 0]
        echohl WarningMsg
        echomsg "[ViewPort]: the begin mark \"".address[1]."\" was deleted, aborting."
        echohl Normal
        return
    elseif e_pos == [0, 0, 0, 0]
        echohl WarningMsg
        echomsg "[ViewPort]: the end mark \"".address[2]."\" was deleted, aborting."
        echohl Normal
        return
    endif
    let s_line = s_pos[1]
    let e_line = e_pos[1]
    let c_lines = getline(s_line, e_line)
    let test = v:cmdbang || c_lines == vp_lines
    let ma = &l:ma
    if (test) && (ma)
        execute "silent! ".s_line.",".e_line."delete _"
        call append(s_line-1, lines)
        call setpos(address[1],[0, s_line, 0, 0])
        call setpos(address[2],[0, s_line+len(lines)-1, 0, 0])
    elseif !(ma)
        echohl ErrorMsg
        echom "[ViewPort]: Cannot make changes, 'modifiable' is off in the target"
        echohl None
    endif
    if exists("c_winnr")
        execute c_winnr."wincmd w"
        unlet c_winnr
    elseif exists("c_bufnr")
        execute "buffer ".c_bufnr
        let &hid = hid
        unlet c_bufnr
    endif
    call winrestview(winview)
    if !(ma)|return|endif
    if !(test)
        echohl ErrorMsg
        echom "[ViewPort]: target buffer modified, use w! to overwrite"
        echohl Normal
    else
        setlocal nomod
        let b:viewport_lines = lines
    endif
endf

" Autocmd {{{2
augroup Part_WriteCmd
    au!
    au BufWriteCmd viewport://* :call <SID>Write()
augroup END
" Public Interface: {{{1
function! ViewPort(cmd) abort range " {{{2
    let s_mark = "'".g:viewport_start_mark
    let e_mark = "'".g:viewport_end_mark

    if s_mark == e_mark
        echohl WarningMsg
        echomsg "[ViewPort]: starting mark and ending mark have to be distinct"
        echohl Normal
        return
    endif

    let lines = getbufline("%", a:firstline, a:lastline)
    call setpos(s_mark, [0, a:firstline, 0, 0])
    call setpos(e_mark, [0, a:lastline, 0, 0])
    let bufnr = bufnr("%")
    let ft = &filetype

    if !empty(ft)
        execute a:cmd.' +setlocal\ ft='.ft.'\ buftype=acwrite viewport://'.fnameescape(expand('%:p').' '.s_mark.'-'.e_mark)
    else
        execute a:cmd.' +setlocal\ buftype=acwrite viewport://'.fnameescape(expand('%:p').' '.s_mark.'-'.e_mark)
    endif

    setlocal ma
    let &l:statusline = ''
    %d_
    let b:viewport_address = [bufnr, s_mark, e_mark]
    call append(1,lines)
    0d_
    " Reset undo:
    let ul = &ul
    set ul=-1
    execute "normal a \<bs>\<esc>"
    let &ul=ul
    unlet ul
    set nomodified
    command! -buffer Update :call <SID>Read()

    let b:viewport_lines = lines
endf

" Commands, mappings and other {{{2

command! -range -nargs=* ViewPort :<line1>,<line2>call ViewPort(<f-args>)

if g:viewport_split_vertical
    command! -range -nargs=* ViewPortSplit :<line1>,<line2>call ViewPort("vsplit")
else
    command! -range -nargs=* ViewPortSplit :<line1>,<line2>call ViewPort("split")
endif

vnoremap <Plug>VPsplit :ViewPortSplit<CR>

vmap <leader>nr <Plug>VPsplit

" END {{{1
let g:loaded_ViewPort = 1

" vim: ts=4 sts=4 fdm=marker foldenable:
