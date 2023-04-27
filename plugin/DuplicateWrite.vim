" DuplicateWrite.vim: Cascade the writing of a file to another location.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - ingo-library.vim plugin
"
" Copyright: (C) 2005-2023 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

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
if ! exists('g:DuplicateWrite_TargetDirectoryCheckIgnorePattern')
    let g:DuplicateWrite_TargetDirectoryCheckIgnorePattern = '^\a\+://'
endif


"- commands --------------------------------------------------------------------

command! -bang -bar -range=-1 -nargs=* -complete=file DuplicateWrite if ! DuplicateWrite#Command(<count> == -1 ? '' : <line1> . ',' . <line2>, <bang>0, <q-args>) | echoerr ingo#err#Get() | endif
command! -bang -bar -range=-1 -nargs=+ -complete=file DuplicateScp if ! DuplicateWrite#ScpCommand(<count> == -1 ? '' : <line1> . ',' . <line2>, <bang>0, <q-args>) | echoerr ingo#err#Get() | endif
command! -bar DuplicateWriteOff if ! DuplicateWrite#Off() | echoerr ingo#err#Get() | endif
command! -bar DuplicateWriteList if ! DuplicateWrite#List() | echoerr ingo#err#Get() | endif
command! -bar DuplicateWriteListAll if ! DuplicateWrite#ListAll() | echoerr ingo#err#Get() | endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
