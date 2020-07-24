if exists("g:loaded_viewport")
  finish
endif

" configure mark used to denote start of narrowed region (defaults to t)
let g:viewport_start_mark = viewport#config#StartMark()

" configure mark used to denote end of narrowed region (defaults to y)
let g:viewport_end_mark = viewport#config#EndMark()

" ensure configured marks are distinct
if g:viewport_start_mark == g:viewport_end_mark
  viewport#error#MarkNonDistinct()
endif

" reserve configured marks for viewport
execute "map m" . g:viewport_start_mark . " :call viewport#error#MarkReserved()<CR>"
execute "map m" . g:viewport_end_mark . " :call viewport#error#MarkReserved()<CR>"

function! s:Read() abort
  let s_view = winsaveview()
  let c_pos = getpos(".")
  let c_bufnr = bufnr("%")
  let hid = &hidden
  set hidden
  let address = b:viewport_address
  execute "keepalt b " . b:viewport_address[0]
  let s_pos = getpos(address[1])
  let e_pos = getpos(address[2])
  if s_pos == [0, 0, 0, 0]
    execute "keepalt b " . c_bufnr
    let &hidden = hid
    viewport#error#MarkDeleted("begin", address[1])
    return
  elseif e_pos == [0, 0, 0, 0]
    execute "keepalt b " . c_bufnr
    let &hidden = hid
    viewport#error#MarkDeleted("end", address[2])
    return
  elseif s_pos[1] > e_pos[1]
    let address[1:2] = [address[2], address[1]]
    let [s_pos, e_pos] = [e_pos, s_pos]
  endif
  let lines = getbufline(address[0], s_pos[1], e_pos[1])
  execute "keepalt b " . c_bufnr
  let &hidden = hid
  %d_
  call append(1, lines)
  0d_
  let c_line = min([c_pos[1], len(lines)])
  call cursor(c_line, 0)
  call winrestview(s_view)
  let b:viewport_lines = lines
  setlocal nomodified
endf

function! s:Write() abort
  silent preserve
  let lines = getbufline("%", 0, "$")
  let address = b:viewport_address
  let vp_lines = b:viewport_lines
  let winnr = bufwinnr(b:viewport_address[0])
  let winview = winsaveview()
  if winnr != -1
    let c_winnr = winnr()
    execute winnr . "wincmd w"
  else
    let c_bufnr = bufnr("%")
    let hid = &hidden
    set hidden
    try
      execute "buffer " . address[0]
    catch /E86:/
      viewport#error#BufferDNE(address[0])
      return
    endtry
  endif
  let s_pos = getpos(address[1])
  let e_pos = getpos(address[2])
  if s_pos == [0, 0, 0, 0]
    viewport#error#MarkDeleted("begin", address[1])
    return
  elseif e_pos == [0, 0, 0, 0]
    viewport#error#MarkDeleted("end", address[2])
    return
  endif
  let s_line = s_pos[1]
  let e_line = e_pos[1]
  let c_lines = getline(s_line, e_line)
  let test = v:cmdbang || c_lines == vp_lines
  let ma = &l:modifiable
  if (test) && (ma)
    execute "silent! " . s_line . "," . e_line . "delete _"
    call append(s_line - 1, lines)
    call setpos(address[1], [0, s_line, 0, 0])
    call setpos(address[2], [0, s_line + len(lines) - 1, 0, 0])
  elseif !(ma)
    viewport#error#NoModifiable()
  endif
  if exists("c_winnr")
    execute c_winnr . "wincmd w"
    unlet c_winnr
  elseif exists("c_bufnr")
    execute "buffer " . c_bufnr
    let &hidden = hid
    unlet c_bufnr
  endif
  call winrestview(winview)
  if !(ma)
    return
  endif
  if !(test)
    viewport#error#BufferModified()
  else
    setlocal nomodified
    let b:viewport_lines = lines
  endif
endf

" autocmd
augroup partwritecmd
  autocmd!
  autocmd BufWriteCmd viewport://* :call <SID>Write()
augroup END

" public interface
function! ViewPort(cmd) abort range
  let s_mark = "'" . g:viewport_start_mark
  let e_mark = "'" . g:viewport_end_mark

  if s_mark == e_mark
    viewport#error#MarkNonDistinct()
  endif

  let lines = getbufline("%", a:firstline, a:lastline)
  call setpos(s_mark, [0, a:firstline, 0, 0])
  call setpos(e_mark, [0, a:lastline, 0, 0])
  let bufnr = bufnr("%")
  let ft = &filetype

  if !empty(ft)
    silent execute a:cmd . ' +setlocal\ filetype=' . ft . '\ buftype=acwrite viewport://' . fnameescape(expand('%') . 'ʹ')
  else
    silent execute a:cmd . ' +setlocal\ buftype=acwrite viewport://' . fnameescape(expand('%') . 'ʹ')
  endif

  setlocal modifiable
  %d_
  let b:viewport_address = [bufnr, s_mark, e_mark]
  call append(1, lines)
  0d_
  " reset undo
  let ul = &undolevels
  set undolevels=-1
  execute "normal mza \<BS>\<ESC>`z"
  let &undolevels=ul
  unlet ul
  set nomodified

  command! -buffer Update :call <SID>Read()

  let b:viewport_lines = lines
endf

command! -range -nargs=* ViewPort :<line1>,<line2>call ViewPort(<f-args>)
command! -range -nargs=* ViewPortEdit :<line1>,<line2>call ViewPort("edit")
command! -range -nargs=* ViewPortSplit :<line1>,<line2>call ViewPort("split")
command! -range -nargs=* ViewPortVSplit :<line1>,<line2>call ViewPort("vsplit")
command! -range -nargs=* ViewPortTabNew :<line1>,<line2>call ViewPort("tabnew")

vnoremap <Plug>ViewPortEdit :ViewPortEdit<CR>
vnoremap <Plug>ViewPortSplit :ViewPortSplit<CR>
vnoremap <Plug>ViewPortVSplit :ViewPortVSplit<CR>
vnoremap <Plug>ViewPortTabNew :ViewPortTabNew<CR>

let g:loaded_viewport = 1

" vim: set filetype=vim foldmethod=marker foldlevel=0 nowrap:
