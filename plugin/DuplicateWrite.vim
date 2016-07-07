" DuplicateWrite.vim: Cascade the writing of a file to another location.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - DuplicateWrite.vim autoload script
"
" Copyright: (C) 2005-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.008	13-Sep-2013	Add -bar.
"				Adapt the invoked functions to the completely
"				changed implementation.
"	007	08-Aug-2013	Move escapings.vim into ingo-library.
"	006	27-Aug-2012	Split off autoload script.
"	005	26-Feb-2012	Renamed b:duplicatewrite to b:DuplicateWrite to
"				match plugin name.
"	004	12-Apr-2011	BUG: Duplicate write clobbers alternate file,
"				use :keepalt.
"				Cosmetics: Script formatting and function
"				ordering.
"				Use escapings#fnameescape() to properly handle
"				all filespecs. Requiring Vim 7.0 or higher now.
"				Add b:duplicatewrite flag for easy flagging in
"				statusline.
"	0.03	10-Nov-2005	BF: Filespecs containing spaces do work now.
"	0.02	19-Jul-2005	Added configurable behavior on buffer deletion.
"	0.01	19-Jul-2005	file creation

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_DuplicateWrite') || (v:version < 700)
    finish
endif
let g:loaded_DuplicateWrite = 1

command! -bar -nargs=1 -complete=file DuplicateWrite call DuplicateWrite#Add(<q-args>)
command! -bar DuplicateWriteOff call DuplicateWrite#Off()
command! -bar DuplicateWriteList call DuplicateWrite#List()
command! -bar DuplicateWriteListAll call DuplicateWrite#ListAll()

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
