" DuplicateWrite.vim: Cascade the writing of a file so that the file is also
" written to another location and/or name. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
" REVISION	DATE		REMARKS 
"	0.03	10-Nov-2005	BF: Filespecs containing spaces do work now. 
"	0.02	19-Jul-2005	Added configurable behavior on buffer deletion. 
"	0.01	19-Jul-2005	file creation

" Avoid installing twice or when in compatible mode
if exists("loaded_DuplicateWrite")
    finish
endif
let loaded_DuplicateWrite = 1

"-- global configuration ------------------------------------------------------
if !exists("g:DuplicateWriteOnBufDelete")
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
command! -nargs=1 -complete=file DuplicateWriteTo call <SID>DuplicateWriteTo(<f-args>)

" Remove all cascaded writes of the current buffer. 
command! -nargs=0 DuplicateWriteOff call <SID>DuplicateWriteOff()

" List the cascaded writes of the current buffer. 
command! -nargs=0 DuplicateWriteList call <SID>DuplicateWriteList()

" List all cascaded writes. 
command! -nargs=0 DuplicateWriteListAll autocmd DuplicateWrite BufWritePost



"-- functions -----------------------------------------------------------------
function! s:DuplicateWriteTo( targetFilespec )
    augroup DuplicateWrite
    execute "autocmd DuplicateWrite BufWritePost " . s:GetSourceFileSpec() . " write! " . a:targetFilespec
    if g:DuplicateWriteKeepOnBufDelete == 0
	" The autocmd is kept. 
    elseif g:DuplicateWriteKeepOnBufDelete == 1
	execute "autocmd DuplicateWrite BufDelete " . s:GetSourceFileSpec() . " call <SID>TurnOff( \"" . s:GetSourceFileSpec() . "\" )"
    elseif g:DuplicateWriteKeepOnBufDelete == 2
	execute "autocmd DuplicateWrite BufDelete " . s:GetSourceFileSpec() . " call <SID>ConfirmTurnOff( \"" . s:GetSourceFileSpec() . "\" )"
    else
	assert 0
    endif
    augroup END
endfunction

function! s:DuplicateWriteOff()
    call s:TurnOff( s:GetSourceFileSpec() )
endfunction

function! s:DuplicateWriteList()
    execute "autocmd DuplicateWrite BufWritePost " . s:GetSourceFileSpec()
endfunction

function! s:GetSourceFileSpec()
    let l:sourceFilespec = expand("%:p")
    " Windows: Replace backslashes in filespec with forward slashes. 
    " Otherwise, the autocmd won't match the filespec. 
    let l:sourceFilespec = substitute( l:sourceFilespec, '\', '/', 'g' )

    " Escape spaces in filespec.
    " Otherwise, the autocmd will be parsed wrongly, taking only the first part
    " of the filespec as the file and interpreting the remainder of the filespec
    " as part of the command. 
    let l:sourceFilespec = escape( l:sourceFilespec, ' ' )

    return l:sourceFilespec
endfunction

function! s:TurnOff( sourceFilespec )
    execute "autocmd! DuplicateWrite * " . a:sourceFilespec
endfunction

function! s:ConfirmTurnOff( sourceFilespec )
    if confirm( "DuplicateWrite is still active for this buffer. Do you want to deactivate it?", "&Yes\n&No" ) == 1
	call s:TurnOff( a:sourceFilespec )
    endif
endfunction

