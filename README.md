vim-viewport
============

Narrow region for Vim.

Config
------

vim-viewport does not create any keymaps by default.

```vim
" open visually selected region in horizontal split
vmap <leader>nr <Plug>ViewportSplit

" open visually selected region in vertical split
vmap <leader>nr <Plug>ViewportVSplit

" open visually selected region in new buffer
vmap <leader>nr <Plug>ViewportEdit

" open visually selected region in new tab
vmap <leader>nr <Plug>ViewportTabNew
```

vim-viewport reserves two Vim marks for its own usage: one for the
starting point and one for the ending point of the narrowed region. These
marks must necessarily be sacrificed to vim-viewport. They can be
configured as follows:

```vim
" configure mark used to denote start of narrowed region (defaults to t)
let g:viewport_start_mark = 't'

" configure mark used to denote end of narrowed region (defaults to y)
let g:viewport_end_mark = 'y'
```

Installation
------------

```bash
# vim 8 package
git clone https://github.com/atweiden/vim-viewport \
  "$HOME/.vim/pack/plugins/start/vim-viewport"

# pathogen
git clone https://github.com/atweiden/vim-viewport \
  "$HOME/.vim/bundle/vim-viewport"
```

```vim
" plug
Plug 'atweiden/vim-viewport'

" vundle
Plugin 'atweiden/vim-viewport'

" dein.vim
call dein#add('atweiden/vim-viewport')

" minpac
call minpac#add('atweiden/vim-viewport')
```

License
-------

[Vim][LICENSE]


[LICENSE]: LICENSE
