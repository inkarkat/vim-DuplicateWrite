" DuplicateWrite.vim: Cascade the writing of a file to another location.
"
" DEPENDENCIES:
"   - ingo/compat.vim autoload script
"   - ingo/escape/file.vim autoload script
"   - ingo/fs/path.vim autoload script
"   - ingo/msg.vim autoload script
"
" Copyright: (C) 2005-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.009	13-Sep-2013	ENH: Check for a passed dirspec, and use the
"				same filename then.
"	008	08-Aug-2013	Move escapings.vim into ingo-library.
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

function! DuplicateWrite#GetSourceFilespec()
    return ingo#escape#file#autocmdescape(expand('%:p'))
endfunction

function! s:TurnOff( sourceFilespec )
    try
	execute 'autocmd! DuplicateWrite *' a:sourceFilespec
    catch /^Vim\%((\a\+)\)\=:E216/ " E216: No such group or event
	call ingo#msg#ErrorMsg('No cascaded writes defined for this buffer')
    endtry

    unlet! b:DuplicateWrite
endfunction

function! s:ConfirmTurnOff( sourceFilespec )
    if confirm('DuplicateWrite is still active for this buffer. Do you want to deactivate it?', "&Yes\n&No") == 1
	call s:TurnOff(a:sourceFilespec)
    endif
endfunction

function! DuplicateWrite#Off()
    call s:TurnOff(DuplicateWrite#GetSourceFilespec())
endfunction

function! DuplicateWrite#Add( source, target )
    let l:targetFilespec = (isdirectory(a:target) ? ingo#fs#path#Combine(a:target, expand('%:t')) : a:target)

    augroup DuplicateWrite
	execute 'autocmd DuplicateWrite BufWritePost' a:source 'keepalt write!' ingo#compat#fnameescape(l:targetFilespec)
	if g:DuplicateWriteKeepOnBufDelete == 0
	    " The autocmd is kept.
	elseif g:DuplicateWriteKeepOnBufDelete == 1
	    execute 'autocmd! DuplicateWrite BufDelete' a:source 'call <SID>TurnOff(' . string(a:source) . ')'
	elseif g:DuplicateWriteKeepOnBufDelete == 2
	    execute 'autocmd! DuplicateWrite BufDelete' a:source 'call <SID>ConfirmTurnOff(' . string(a:source) . ')'
	else
	    throw 'ASSERT: Invalid value for g:DuplicateWriteKeepOnBufDelete: ' . g:DuplicateWriteKeepOnBufDelete
	endif
    augroup END

    let b:DuplicateWrite = (exists('b:DuplicateWrite') ? b:DuplicateWrite + 1 : 1)  " Mark buffer to enable easy flagging in statusline.
endfunction

function! DuplicateWrite#List( isGlobal )
    try
	execute 'autocmd DuplicateWrite BufWritePost' (a:isGlobal ? '' : DuplicateWrite#GetSourceFilespec())
    catch /^Vim\%((\a\+)\)\=:E216/ " E216: No such group or event
	call ingo#msg#ErrorMsg('No cascaded writes defined')
    endtry
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
