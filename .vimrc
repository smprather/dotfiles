" Use this for debugging vim
" vi -V10debug.log +g

" To enable 256 colors. But it should not be needed.
"set t_Co=256

" handle things like table lines
set encoding=utf-8

set nocompatible
set shell=sh

"set backupdir=/tmp/$USER/vimtemp
"set directory=/tmp/$USER/vimtemp
"set undodir=/tmp/$USER/vimtemp

"function! PyAddParensToDebugs()
"    execute "normal! mZ"
"    execute "%s/^\\(\\s*\\)\\(ic\\)\\( \\(.*\\)\\)\\{-}$/\\1\\2(\\4)/"
"    execute "%s/^\\(\\s*\\)\\(ice\\)\\( \\(.*\\)\\)\\{-}$/\\1ic(\\4)\\r\\1exit()/"
"    execute "%s/^\\(\\s*\\)\\(exit\\|e\\)$/\\1exit()/"
"    execute "normal! `Z"
"endfunction

" Use persistent history.
"if !isdirectory("/var/tmp/mylesp-vim-undo-dir")
"  call mkdir("/var/tmp/mylesp-vim-undo-dir", "", 0700)
"endif
"if !isdirectory("/var/tmp/mylesp-vim-view-dir")
"  call mkdir("/var/tmp/mylesp-vim-view-dir", "", 0700)
"endif
"set undodir=/tmp/mylesp-vim-undo-dir
"set undofile
"set viewdir=/var/tmp/mylesp-vim-view-dir

" Make directory-nav buffers go away when done
" I need to switch over to NerdTree instead of netrw
"let g:netrw_fastbrowse=2

call plug#begin()
" The default plugin directory will be as follows:
"   - Vim (Linux/macOS): '~/.vim/plugged'
"   - Vim (Windows): '~/vimfiles/plugged'
"   - Neovim (Linux/macOS/Windows): stdpath('data') . '/plugged'
" You can specify a custom plugin directory by passing it as the argument
"   - e.g. `call plug#begin('~/.vim/plugged')`
"   - Avoid using standard Vim directory names like 'plugin'

" Make sure you use single quotes
"Plug 'preservim/nerdtree'
"Plug 'vim-scripts/indentpython.vim'
"Plug 'tmhedberg/SimpylFold'
"Plug 'bitc/vim-bad-whitespace'
"Plug 'tarikgraba/vim-liberty'
"Plug 'tpope/vim-commentary'
Plug 'ervandew/supertab'
" Initialize plugin system
" - Automatically executes `filetype plugin indent on` and `syntax enable`.
call plug#end()
" You can revert the settings after the call like so:
"   filetype indent off   " Disable file-type-specific indentation
"   syntax off            " Disable syntax highlighting

" SuperTab configuration
" attempting to use the text preceding the cursor to decide which type of
" completion to attempt.
let g:SuperTabDefaultCompletionType = "context"

filetype plugin indent on
set ts=4 sts=4 sw=4 expandtab

" The autocmds MUST come after 'filetype plugin indent on' in order to
" override settings that come from the <install_dir>/runtime/* filetype and
" indent files.
"augroup my_au_group | autocmd!
"    " Jump to the last position when reopening a file
"    autocmd BufReadPost * if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
"                          \ |     exe 'normal! g`"zz'
"                          \ | endif
"
"    autocmd FileType netrw setl bufhidden=wipe
"    autocmd BufWritePre * if count(['python'],&filetype)
"        \ |                   silent! call PyAddParensToDebugs()
"        \ |                   silent! Black
"        \ |               endif
"    " Fix auto-indentation for YAML files
"    autocmd FileType yaml setlocal ts=2 sts=2 sw=2 indentkeys-=0# indentkeys-=<:>

"    " view files are about 500 bytes
"    " bufleave but not bufwinleave captures closing 2nd tab
"    " nested is needed by bufwrite* (if triggered via other autocmd)
"    " BufHidden for compatibility with `set hidden`
"    autocmd BufUnload,BufWritePost,QuitPre,BufHidden ?* nested silent! mkview!

    " Equalize pane sizes after terminal resize
"    autocmd BufWinEnter,VimResized * wincmd =
"augroup end

"let g:LargeFile = 1000
"let g:black_linelength = 130

"Performance improvements from (speed)
"https://vi.stackexchange.com/questions/10495/most-annoying-slow-down-of-a-plain-text-editor
"if !has('nvim')
"    set regexpengine=1
"    set lazyredraw
"    set ttyfast
"    set synmaxcol=1200
"endif
"if has('nvim')
"    " Initialize all lua-driven plugins
"    " ~/.vim/init.lua
"    runtime init.lua
"
"    let g:semshi#error_sign=v:true
"    let g:semshi#error_sign_delay=30.0
"    let g:semshi#update_delay_factor=0.0005
"    let g:SimpylFold_docstring_preview=1
"    set guicursor=
"    " Figure out the system Python for Neovim.
"    if exists("$VIRTUAL_ENV")
"        let g:python3_host_prog=substitute(system("/bin/which -a python3 | head -n1"), "\n", '', 'g')
"    else
"        let g:python3_host_prog="/proj/cot_globals/envs/glb_python3.11.4/bin/python3"
"    endif
"endif

" Based on fold advice from here
" https://vi.stackexchange.com/questions/13864/bufwinleave-mkview-with-unnamed-file-error-32
set viewoptions=folds,cursor
set sessionoptions=folds
" Enable folding
"set foldmethod=indent
set foldmethod=manual
set foldlevel=99

set nostartofline

" Function to permanently delete views created by 'mkview'
" Sometimes a files view gets messed up and needs to be deleted.
"function! MyDeleteView()
"    let path = fnamemodify(bufname('%'),':p')
"    " vim's odd =~ escaping for /
"    let path = substitute(path, '=', '==', 'g')
"    if empty($HOME)
"    else
"        let path = substitute(path, '^'.$HOME, '\~', '')
"    endif
"    let path = substitute(path, '/', '=+', 'g') . '='
"    " view directory
"    let path = &viewdir.'/'.path
"    call delete(path)
"    echo "Deleted: ".path
"endfunction
" # Command Delview (and it's abbreviation 'delview')
" command Delview call MyDeleteView()
" Lower-case user commands: http://vim.wikia.com/wiki/Replace_a_builtin_command_using_cabbrev
" cabbrev delview <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'Delview' : 'delview')<CR>

set mouse=
set hidden
set shortmess=at
set mousefocus
set mousehide
set mousemodel=extend
set autoindent
"set smartindent
set textwidth=130
set fo-=t
set backspace=indent,eol,start

" This sets the first character used for commonly chorded commands
let mapleader=" "

" Get rid of the visual bell since it was displaying insanely slow
" in the GUI (like a full second)
set vb t_vb=

" Only show the menu in the GUI; no scrollbars
if !has('nvim')
    if has("gui_running")
        set guioptions=m
        set guicursor=i:block
    endif
endif

" Keep cursor centered vertically
set scrolloff=999

" Compatibility (with vi) options (':h cpo' for more info)
set cpoptions=ceFs

"Add the column # and line # of the cursor position in the status line
set ruler
set rulerformat=%55(%{strftime('%a\ %b\ %e\ %I:%M\ %p')}\ %5l,%-6(%c%V%)\ %P%)
"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*

set laststatus=2
set statusline=%f
set statusline+=%h
set statusline+=%m
set statusline+=%r
set statusline+=\ %=
set statusline+=Line:%4l/%4L[%3p%%]
set statusline+=\ Col:%3c
hi StatusLine guifg=#0000AA guibg=#ffffff

"set cursorline
"set cursorcolumn
"let crosshair_color="#205050"
"execute printf('highlight CursorLine guibg=%s', crosshair_color)
"execute printf('highlight CursorColumn guibg=%s', crosshair_color)

" Makes searching case insignificant EXCEPT when you include a cap
" letter in the searchstring.  'incsearch' makes search interactive
set ignorecase
set smartcase
set incsearch

" Better control over file name completion when using :e <file> .
" Couple of varieties of wildmode. Need to figure out which I like better.
"set wildmode=longest,list,full
set wildmode=longest:full,full
set wildmenu


" This turns off all beeping and screen flashing
set vb t_vb=
set noeb

" This makes it so that the 'hit-return' msg doesn't always come up for
" long messages. (even though it's not working for me)
set shm=at

" Highlight search results. Use bind ctrl-l to un-highlight.
set hlsearch

" Path must be set like this to be compatible with the way vim-ruby adds the
" ruby libs to the path var
set path=.,,,


" Zoom / Restore window. Use <leader>a to run this.
function! s:ZoomToggle() abort
  if exists('t:zoomed') && t:zoomed
    execute t:zoom_winrestcmd
    let t:zoomed = 0
  else
    let t:zoom_winrestcmd = winrestcmd()
    resize
    vertical resize
    let t:zoomed = 1
  endif
endfunction
command! ZoomToggle call s:ZoomToggle()
nnoremap <silent> <leader>a :ZoomToggle<CR>

" My key mappings
map  <c-d> dd
nmap  e     :e<space>
map  t     j0.
map  T     j.
map  <M-m> `m
map  1     @q
map <c-h>  <c-w><c-w>
map  =     <c-w>+
map  -     <c-w>-
map  _     <c-w>>
map  +     <c-w><
map Y       ^W^W^Y^W^W
map <leader>rt :%s/\\t/  /g<cr>
map <leader>Q  :q<cr>
map <leader>q  :qall!<cr>
map <leader>x  :xa<cr>
map <leader>s  :w<cr>
map <leader>sa :wa<cr>
map <leader>m  :mks!
map <leader>d  :set nobuflisted<cr>:bn<cr>
map <leader>sv :vsp<cr>
map <leader>sh :sp<cr>
map <leader>pp :set invpaste paste?<cr>
map <leader>nw :set nowrap<cr>
map <leader>w  :set wrap<cr>
map <leader>=  <c-w>=
vmap <leader>y :w! /tmp/vitmp_$USER<CR>
nmap <leader>p :r! cat /tmp/vitmp_$USER<CR>
map <leader># :windo set invnumber<CR>
map <leader>f zR
" Delete all trailing whitespace
map <leader>dtw :let _s=@/ <Bar> :%s/\\s\\+$//e <Bar> :let @/=_s <Bar> :nohl <Bar> :unlet _s <CR>
"nnoremap <space> i <esc>
" Enable fold-toggle with ctrl-spacebar
" This is how you map ctrl-space in vim
noremap <C-@> za
noremap <BS> <<
map <leader>ss :mksession! ~/.session.vim<CR>
map <leader>ls :source ~/.session.vim<CR>
nnoremap v  V
nnoremap V  v
map <c-j> :bn<cr>
map <c-k> :bp<cr>
" I'm still considering using vim tabs
imap kj <esc>
nnoremap <silent> <c-l> <c-l>:noh<cr>
" Toggle syntax highlighting when more performance is needed
nnoremap <silent> <leader>t :if exists("g:syntax_on") <Bar> syntax off <Bar> else <Bar> syntax enable <Bar> hi CursorLine cterm=NONE ctermbg=235 <Bar> hi StatusLine ctermbg=DarkBlue ctermfg=white <Bar> endif <CR>

cnoremap kj <esc>

nnoremap ; :
nnoremap ;; ;


if filereadable(expand("~/.vimrc_hook.bottom"))
    source ~/.vimrc_hook.bottom
endif

