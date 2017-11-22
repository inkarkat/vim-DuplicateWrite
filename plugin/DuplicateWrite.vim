" DuplicateWrite.vim: Cascade the writing of a file to another location.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - DuplicateWrite.vim autoload script
"   - ingo/err.vim autoload script
"
" Copyright: (C) 2005-2016 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.00.011	11-Jul-2016	ENH: Support duplicate write only with :write
"				when using :DuplicateWrite! during definition.
"   2.00.010	09-Jul-2016	ENH: Add default mirror configuration in
"				g:DuplicateWrite_DefaultMirrors.
"				Use nested autocmds, but allow to suppress
"				certain events via g:DuplicateWrite_EventIgnore.
"				ENH: Check for existence of target directory,
"				and react according to
"				g:DuplicateWrite_CreateNonExistingTargetDirectory.
"				Rename DuplicateWrite#Add() to
"				DuplicateWrite#Command().
"   2.00.009	08-Jul-2016	ENH: Allow multiple arguments to
"				:DuplicateWrite, including [++opt] [+cmd].
"				Use ingo/err.vim.
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

"- configuration ---------------------------------------------------------------

if ! exists('g:DuplicateWrite_DefaultMirrors')
    let g:DuplicateWrite_DefaultMirrors = []
endif
if ! exists('g:DuplicateWrite_EventIgnore')
    let g:DuplicateWrite_EventIgnore = 'BufWritePre,BufWritePost'
endif
if ! exists('g:DuplicateWrite_CreateNonExistingTargetDirectory')
    let g:DuplicateWrite_CreateNonExistingTargetDirectory = 'ask'
endif


"- commands --------------------------------------------------------------------

command! -bang -bar -nargs=* -complete=file DuplicateWrite if ! DuplicateWrite#Command(<bang>0, <q-args>) | echoerr ingo#err#Get() | endif
command! -bar DuplicateWriteOff if ! DuplicateWrite#Off() | echoerr ingo#err#Get() | endif
command! -bar DuplicateWriteList if ! DuplicateWrite#List() | echoerr ingo#err#Get() | endif
command! -bar DuplicateWriteListAll if ! DuplicateWrite#ListAll() | echoerr ingo#err#Get() | endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
