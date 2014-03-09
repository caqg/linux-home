" 2007-06-14 00:58:01UT (cesar@bears06-01) 

highlight clear
set background=light
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "oasis"

"highlight Normal ctermbg=White ctermfg=Black guibg=#f0f0c0 guifg=Black
highlight Normal ctermbg=White ctermfg=Black guibg=white guifg=Black
highlight Menu gui=NONE guibg=lightgoldenrodyellow guifg=sienna4
highlight Scrollbar gui=NONE guifg=sienna4 guibg=khaki
highlight Tooltip gui=NONE guifg=bg guibg=fg

highlight Comment term=NONE cterm=underline gui=italic guifg=gray50
highlight PreProc term=NONE cterm=NONE guifg=orangered4

highlight ErrorMsg term=standout ctermbg=DarkRed ctermfg=White guibg=Red guifg=White
highlight IncSearch term=reverse cterm=reverse gui=reverse
highlight ModeMsg term=bold cterm=bold gui=bold
highlight StatusLine term=reverse,bold cterm=reverse,bold gui=bold guifg=sienna4 guibg=khaki
highlight StatusLineNC term=reverse cterm=reverse gui=NONE guifg=sienna4 guibg=khaki
highlight VertSplit term=reverse cterm=reverse gui=reverse
highlight Visual term=reverse ctermbg=grey guibg=grey80
highlight VisualNOS term=underline,bold cterm=underline,bold gui=underline,bold
highlight DiffText term=reverse cterm=bold ctermbg=Red gui=bold guibg=Red
highlight Cursor guibg=Red3 guifg=NONE
highlight lCursor guibg=Cyan guifg=NONE
highlight Directory term=bold ctermfg=DarkBlue guifg=Blue
highlight LineNr term=underline ctermfg=Brown guifg=Brown
highlight MoreMsg term=bold ctermfg=DarkGreen gui=bold guifg=SeaGreen
highlight NonText term=bold ctermfg=Gray gui=bold guifg=darkgreen guibg=lightgoldenrodyellow
highlight Question term=standout ctermfg=DarkGreen gui=bold guifg=SeaGreen
highlight Search term=reverse ctermbg=Yellow ctermfg=NONE guibg=Yellow guifg=NONE
highlight SpecialKey term=bold ctermfg=DarkBlue guifg=Blue
highlight Title term=bold ctermfg=DarkMagenta gui=bold guifg=Magenta
highlight WarningMsg term=standout ctermfg=DarkRed guifg=Red
highlight WildMenu term=standout ctermbg=Yellow ctermfg=Black guibg=Yellow guifg=Black
highlight Folded term=standout ctermbg=Grey ctermfg=DarkBlue guibg=ivory2 guifg=brown4
highlight FoldColumn term=standout ctermbg=Grey ctermfg=DarkBlue guibg=khaki guifg=brown4
highlight DiffAdd term=bold ctermbg=LightBlue guibg=LightBlue
highlight DiffChange term=bold ctermbg=LightMagenta guibg=LightMagenta
highlight DiffDelete term=bold ctermfg=Blue ctermbg=LightCyan gui=bold guifg=Blue guibg=LightCyan
highlight CursorLine term=underline cterm=underline guibg=grey80
highlight CursorColumn term=reverse ctermbg=grey guibg=grey80

highlight Constant term=underline ctermfg=DarkRed guifg=DarkOrange4 guibg=white
highlight Special term=bold ctermfg=DarkMagenta guifg=SlateBlue guibg=white
if &t_Co > 8
  highlight Statement term=bold cterm=bold ctermfg=Brown gui=bold guifg=Brown
endif
highlight Ignore ctermfg=LightGrey guifg=grey90
