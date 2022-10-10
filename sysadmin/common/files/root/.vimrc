set autoindent
set background=dark
set backspace=indent,eol,start
set colorcolumn=81
set hlsearch
set incsearch
set mouse=
set nomodeline
set ruler
set showcmd
set showmatch
set smarttab

if has("autocmd")
	autocmd BufReadPost * if line("'\"") && line("'\"") <= line("$")
	 \| exe "normal g'\"" | endif
	autocmd FileType python setlocal smartindent
	autocmd FileType text setlocal textwidth=80
	autocmd BufNewFile,BufRead *.ts setlocal filetype=javascript
	filetype plugin indent on
endif "has("autocmd")

"256 colours
set t_Co=256

syntax on
