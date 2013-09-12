" DuplicateWrite.vim: Cascade the writing of a file so that the file is also
" written to another location and/or name.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - DuplicateWrite.vim autoload script
"   - ingo/compat.vim autoload script
"
" Copyright: (C) 2005-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
" REVISION	DATE		REMARKS
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

"-- configuration -------------------------------------------------------------

if !exists('g:DuplicateWriteOnBufDelete')
    " This setting decides what happens when a buffer with 'DuplicateWriteTo' is
    " deleted (e.g. ':bd'):
    " 0: The cascaded write is kept. If the file is reloaded, the cascaded write
    "	 is resumed.
    " 1: The cascaded write is removed.
    " 2: The user is queried whether DuplicateWrite should be deactivated.
    let g:DuplicateWriteKeepOnBufDelete = 1
endif


"-- commands ------------------------------------------------------------------

" Create a cascaded write of the current buffer to the specified file.
command! -nargs=1 -complete=file DuplicateWriteTo call DuplicateWrite#To(<q-args>)

" Remove all cascaded writes of the current buffer.
command! -nargs=0 DuplicateWriteOff call DuplicateWrite#Off()

" List the cascaded writes of the current buffer.
command! -nargs=0 DuplicateWriteList call DuplicateWrite#List()

" List all cascaded writes.
command! -nargs=0 DuplicateWriteListAll autocmd DuplicateWrite BufWritePost

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
