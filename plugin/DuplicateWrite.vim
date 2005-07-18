" DuplicateWrite.vim: Cascades the writing of a file so that the file is also
" written to another location and/or name. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
" REVISION	DATE		REMARKS 
"	0.01	19-Jul-2005	file creation

" Avoid installing twice or when in compatible mode
if exists("loaded_DuplicateWrite")
    finish
endif
let loaded_DuplicateWrite = 1

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
    let l:sourceFilespec = expand("%:p")
    " Windows: Replace backslashes in filespec with forward slashes. 
    " Otherwise, the autocmd won't match the filespec. 
    let l:sourceFilespec = substitute( l:sourceFilespec, '\', '/', 'g' )

    augroup DuplicateWrite
    execute "autocmd DuplicateWrite BufWritePost " . s:GetSourceFileSpec() . " write! " . a:targetFilespec
    augroup END
endfunction

function! s:DuplicateWriteOff()
    execute "autocmd! DuplicateWrite BufWritePost " . s:GetSourceFileSpec()
endfunction

function! s:DuplicateWriteList()
    execute "autocmd DuplicateWrite BufWritePost " . s:GetSourceFileSpec()
endfunction

function! s:GetSourceFileSpec()
    let l:sourceFilespec = expand("%:p")
    " Windows: Replace backslashes in filespec with forward slashes. 
    " Otherwise, the autocmd won't match the filespec. 
    let l:sourceFilespec = substitute( l:sourceFilespec, '\', '/', 'g' )

    return l:sourceFilespec
endfunction

