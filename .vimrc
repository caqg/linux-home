" vim Initialization

set directory=
set directory+=~/tmp
set directory+=.		"do not interfere with git or svn
set directory+=/var/tmp
set directory+=/tmp

set path=.,,
set path+=/usr/include/c++/4.8
set path+=/usr/include/x86_64-linux-gnu/c++/4.8
set path+=/usr/include/c++/4.8/backward
set path+=/usr/lib/gcc/x86_64-linux-gnu/4.8/include
set path+=/usr/local/include
set path+=/usr/lib/gcc/x86_64-linux-gnu/4.8/include-fixed
set path+=/usr/include/x86_64-linux-gnu
set path+=/usr/include


source $HOME/.exrc
syntax on
filetype indent on
filetype plugin on
"set smarttab
"set expandtab

if has("cscope")
  set cscopeprg=cscope
  set cscopetag
  set csto=0
  set cscopeverbose
  if filereadable("cscope.out")
    cscope add cscope.out
  endif
endif

let TE_Ctags_Path="ctags"
let TE_Use_Right_Window=1

" Not in plain vi
set backup
set laststatus=1
set writebackup
set nohlsearch
set incsearch
if v:version >= 700
  set numberwidth=5
endif

" C/C++, closer to the Emacs settings
autocmd FileType c,cpp,java :set cinoptions=:0,j1,J1,l0,g0,t0,(0,)30
autocmd FileType c,cpp,java :set foldmethod=syntax
autocmd FileType c,cpp,java :set foldcolumn=4
autocmd FileType c,cpp,java :set nofoldenable

set ruler
set diffopt=filler,iwhite

" Adjust Verilog's indentation
function! VerilogSettings ()
  if exists('b:current_syntax')
    if b:current_syntax == 'verilog'
      let b:verilog_indent_modules = 1
    endif
  endif
endfunction
autocmd BufReadPost *.v call VerilogSettings()

" Man pages
runtime! ftplugin/man.vim

"end .vimrc
