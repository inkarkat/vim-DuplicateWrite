" DuplicateWrite.vim: Cascade the writing of a file to another location.
"
" DEPENDENCIES:
"   - ingo/cmdargs/file.vim autoload script
"   - ingo/cmdargs/glob.vim autoload script
"   - ingo/compat.vim autoload script
"   - ingo/err.vim autoload script
"   - ingo/fs/path.vim autoload script
"   - ingo/msg.vim autoload script
"   - ingo/os.vim autoload script
"
" Copyright: (C) 2005-2016 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.01.010	13-Sep-2013	FIX: Use full absolute path and normalize to be
"				immune against changes in CWD.
"   1.00.009	13-Sep-2013	ENH: Check for a passed dirspec, and use the
"				same filename then.
"				Rewrite the implementation completely: Instead
"				of using the filespec in the autocmds, we define
"				a single buffer-scoped autocmd, and keep the
"				filespecs in the b:DuplicateWrite variable. This
"				makes it easier to avoid adding the same
"				cascaded write target twice. The duplication is
"				automatically cleared on :bdelete, so we don't
"				need the configurable behavior any more. It also
"				means the list functions become more involved,
"				but this also allows us to improve on the output
"				format.
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
let s:save_cpo = &cpo
set cpo&vim

function! DuplicateWrite#Off()
    unlet! b:DuplicateWrite

    try
	execute 'autocmd! DuplicateWrite * <buffer>'
	return 1
    catch /^Vim\%((\a\+)\)\=:E216:/ " E216: No such group or event
	call ingo#err#Set('No cascaded writes defined for this buffer')
	return 0
    endtry
endfunction

function! DuplicateWrite#Add( filePatternsString )
    let l:filePatterns = ingo#cmdargs#file#SplitAndUnescape(a:filePatternsString)

    " Strip off the optional ++opt +cmd file options and commands.
    let [l:filePatterns, l:fileOptionsAndCommands] = ingo#cmdargs#file#FilterFileOptionsAndCommands(l:filePatterns)
    let l:filespecs = ingo#cmdargs#glob#Expand(l:filePatterns, 1, 1)

    if len(l:filespecs) == 0
	call ingo#err#Set('file, dirspec, or glob required')
	return 0
    endif

    call ingo#err#Set('No file(s) have been added') " This may be overwritten by more specific errors in s:Add().
    let l:cnt = 0
    for l:filespec in l:filespecs
	if s:Add(l:fileOptionsAndCommands, l:filespec)
	    let l:cnt += 1
	endif
    endfor

    return (l:cnt > 0)
endfunction
function! s:Add( fileOptionsAndCommands, target )
    if isdirectory(a:target)
	if empty(expand('%:t'))
	    call ingo#err#Set('No file name; either name the buffer or pass a full filespec')
	    return 0
	else
	    let l:targetFile = ingo#fs#path#Combine(a:target, expand('%:t'))
	endif
    else
	let l:targetFile = a:target
    endif

    " To avoid that changes of the CWD affect the target location, expand to a
    " full absolute path.
    " Normalize all path separators to allow a simple string comparison for the
    " duplicate check.
    let l:targetFilespec = ingo#fs#path#Normalize(fnamemodify(l:targetFile, ':p'))

    if ingo#fs#path#Equals(l:targetFilespec, expand('%:p'))
	" Ignore current buffer. This may be included in a passed glob or by
	" accident.
	return 0
    endif

    let l:cmd = (get(a:fileOptionsAndCommands, -1, '') =~# '^++\@!' ? remove(a:fileOptionsAndCommands, -1)[1:] : '')
    let l:opt = a:fileOptionsAndCommands

    augroup DuplicateWrite
	autocmd! * <buffer>
	autocmd BufWritePost <buffer>
	\   for g:DuplicateWrite_Object in b:DuplicateWrite |
	\       try |
	\           execute g:DuplicateWrite_Object.cmd |
	\           execute "keepalt write!" join(map(g:DuplicateWrite_Object.opt, "escape(v:val, '\\ ')")) ingo#compat#fnameescape(g:DuplicateWrite_Object.filespec) |
	\       catch /^Vim\%((\a\+)\)\=:/ |
	\           call ingo#msg#VimExceptionMsg() |
	\           sleep 1 |
	\       endtry |
	\   endfor |
	\   unlet g:DuplicateWrite_Object
	" Use try...catch to prevent the first write error from cancelling all
	" further cascaded writes.
	" To avoid that the error message is overwritten by subsequent
	" successful cascaded writes (and their potentially triggered autocmds),
	" wait for a second. The user can recall the error with :messages later.

	" Clear the autocmds, as they survive when the :bdelete'd buffer is
	" revived via :buffer.
	autocmd BufDelete <buffer> autocmd! DuplicateWrite * <buffer>
    augroup END

    let l:object = { 'filespec': l:targetFilespec, 'opt': l:opt, 'cmd': l:cmd }

    if ! exists('b:DuplicateWrite') | let b:DuplicateWrite = [] | endif
    let l:idx = index(
    \   map(
    \       copy(b:DuplicateWrite),
    \       'v:val.filespec'
    \   ),
    \   l:targetFilespec, 0, ingo#fs#path#IsCaseInsensitive()
    \)
    if l:idx == -1
	call add(b:DuplicateWrite, l:object)
    elseif b:DuplicateWrite[l:idx] ==# l:object
	call ingo#msg#WarningMsg(printf('A cascaded write to "%s" is already defined', l:targetFilespec))
    else
	let b:DuplicateWrite[l:idx] = l:object
	call ingo#msg#StatusMsg(printf('Updated cascaded write to "%s"', l:targetFilespec))
    endif
    return 1
endfunction

function! s:ToString( object )
    return join(
    \   map(copy(a:object.opt), "escape(v:val, '\\ ')") +
    \   (empty(a:object.cmd) ? [] : [escape(a:object.cmd, '\ ')]) +
    \   ['"' . a:object.filespec . '"']
    \)
endfunction
function! s:ToStrings( objects )
    return map(copy(a:objects), 's:ToString(v:val)')
endfunction
function! DuplicateWrite#List()
    if exists('b:DuplicateWrite')
	echo join(s:ToStrings(b:DuplicateWrite), "\n")
	return 1
    else
	call ingo#err#Set('No cascaded writes defined for this buffer')
	return 0
    endif
endfunction
function! DuplicateWrite#ListAll()
    let l:isFound = 0
    for l:bufNr in range(1, bufnr('$'))
	let l:duplicateWrite = getbufvar(l:bufNr, 'DuplicateWrite')
	if ! empty(l:duplicateWrite)
	    let l:isFound = 1
	    echo printf('%3d  "%s" ->', l:bufNr, bufname(l:bufNr))
	    echo '        ' . join(s:ToStrings(l:duplicateWrite), "\n        ")
	endif
	unlet! l:duplicateWrite
    endfor
    if ! l:isFound
	call ingo#err#Set('No cascaded writes defined')
	return 0
    endif
    return 1
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
