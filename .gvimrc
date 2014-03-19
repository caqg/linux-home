" gvim Initialization -- 2006-10-11 01:33:19UT (cesar@cesar-xp)

set background=light
set guicursor=a:block
"set guifont=Terminal\ 14
"set guifont=Monospace\ Regular\ 10
set guifont=Ubuntu\ Mono\ 11
set guioptions+=a
set guioptions+=b
set guioptions+=h
set guioptions+=g
set guioptions-=l
set guioptions+=r
set guioptions+=t
set guioptions-=b
set guioptions-=r
set guioptions-=T

if &diff
  set columns=180
  set lines=999
else
  set columns=96
  set lines=36
endif

color solarized
call togglebg#map("<F12>")
set background=light

"end .gvimrc
