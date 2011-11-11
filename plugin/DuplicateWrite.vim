" DuplicateWrite.vim: Cascade the writing of a file so that the file is also
" written to another location and/or name. 
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher. 
"   - escapings.vim autoload script. 
"
" Copyright: (C) 2005-2011 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
" REVISION	DATE		REMARKS 
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



"-- functions -----------------------------------------------------------------
function! s:GetSourceFileSpec()
    let l:sourceFilespec = expand('%:p')
    " Windows: Replace backslashes in filespec with forward slashes. 
    " Otherwise, the autocmd won't match the filespec. 
    let l:sourceFilespec = substitute( l:sourceFilespec, '\', '/', 'g' )

    " Escape spaces in filespec.
    " Otherwise, the autocmd will be parsed wrongly, taking only the first part
    " of the filespec as the file and interpreting the remainder of the filespec
    " as part of the command. 
    let l:sourceFilespec = escape(l:sourceFilespec, ' ')

    return l:sourceFilespec
endfunction

function! s:TurnOff( sourceFilespec )
    execute 'autocmd! DuplicateWrite *' a:sourceFilespec

    unlet! b:duplicatewrite
endfunction

function! s:ConfirmTurnOff( sourceFilespec )
    if confirm( 'DuplicateWrite is still active for this buffer. Do you want to deactivate it?', "&Yes\n&No" ) == 1
	call s:TurnOff(a:sourceFilespec)
    endif
endfunction

function! s:DuplicateWriteOff()
    call s:TurnOff(s:GetSourceFileSpec())
endfunction

function! s:DuplicateWriteList()
    execute 'autocmd DuplicateWrite BufWritePost' s:GetSourceFileSpec()
endfunction

function! s:DuplicateWriteTo( targetFilespec )
    let b:duplicatewrite = (exists('b:duplicatewrite') ? b:duplicatewrite + 1 : 1)  " Mark buffer to enable easy flagging in statusline.

    augroup DuplicateWrite
	execute 'autocmd DuplicateWrite BufWritePost' s:GetSourceFileSpec() 'keepalt write!' escapings#fnameescape(a:targetFilespec)
	if g:DuplicateWriteKeepOnBufDelete == 0
	    " The autocmd is kept. 
	elseif g:DuplicateWriteKeepOnBufDelete == 1
	    execute 'autocmd DuplicateWrite BufDelete' s:GetSourceFileSpec() 'call <SID>TurnOff(' . string(s:GetSourceFileSpec()) . ')'
	elseif g:DuplicateWriteKeepOnBufDelete == 2
	    execute 'autocmd DuplicateWrite BufDelete' s:GetSourceFileSpec() 'call <SID>ConfirmTurnOff(' . string(s:GetSourceFileSpec()) . ')'
	else
	    throw 'ASSERT: Invalid value for g:DuplicateWriteKeepOnBufDelete: ' . g:DuplicateWriteKeepOnBufDelete
	endif
    augroup END
endfunction



"-- commands ------------------------------------------------------------------
" Create a cascaded write of the current buffer to the specified file. 
command! -nargs=1 -complete=file DuplicateWriteTo call <SID>DuplicateWriteTo(<f-args>)

" Remove all cascaded writes of the current buffer. 
command! -nargs=0 DuplicateWriteOff call <SID>DuplicateWriteOff()

" List the cascaded writes of the current buffer. 
command! -nargs=0 DuplicateWriteList call <SID>DuplicateWriteList()

" List all cascaded writes. 
command! -nargs=0 DuplicateWriteListAll autocmd DuplicateWrite BufWritePost

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
