" DuplicateWrite.vim: Cascade the writing of a file so that the file is also
" written to another location and/or name.
"
" DEPENDENCIES:
"   - escapings.vim autoload script
"
" Copyright: (C) 2005-2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
" REVISION	DATE		REMARKS
"	007	14-Dec-2012	Extract escaping for :autocmd to
"				escapings#autocmdescape().
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

function! s:GetSourceFileSpec()
    return escapings#autocmdescape(expand('%:p'))
endfunction

function! s:TurnOff( sourceFilespec )
    execute 'autocmd! DuplicateWrite *' a:sourceFilespec

    unlet! b:DuplicateWrite
endfunction

function! s:ConfirmTurnOff( sourceFilespec )
    if confirm( 'DuplicateWrite is still active for this buffer. Do you want to deactivate it?', "&Yes\n&No" ) == 1
	call s:TurnOff(a:sourceFilespec)
    endif
endfunction

function! DuplicateWrite#Off()
    call s:TurnOff(s:GetSourceFileSpec())
endfunction

function! DuplicateWrite#List()
    execute 'autocmd DuplicateWrite BufWritePost' s:GetSourceFileSpec()
endfunction

function! DuplicateWrite#To( targetFilespec )
    let b:DuplicateWrite = (exists('b:DuplicateWrite') ? b:DuplicateWrite + 1 : 1)  " Mark buffer to enable easy flagging in statusline.

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

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
