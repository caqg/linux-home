" filetype.vim
"
if exists("did_load_filetypes")
	finish
endif

augroup filetypedetect
	au! BufRead,BufNewFile .gitk		setfiletype tcl
	au! BufRead,BufNewFile .gtkwaverc	setfiletype tcl
	au! BufRead,BufNewFile .tclshrc		setfiletype tcl
	au! BufRead,BufNewFile .wishrc		setfiletype tcl
augroup END

" end filetype.vim
