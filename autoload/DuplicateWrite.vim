" DuplicateWrite.vim: Cascade the writing of a file to another location.
"
" DEPENDENCIES:
"   - ingo-library.vim plugin
"
" Copyright: (C) 2005-2023 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
let s:save_cpo = &cpo
set cpo&vim

function! DuplicateWrite#TargetDirectoryCheck( filespec )
    let l:dirspec = fnamemodify(a:filespec, ':h')
    if isdirectory(l:dirspec)
	return 1
    elseif l:dirspec =~# g:DuplicateWrite_TargetDirectoryCheckIgnorePattern
	return 1
    elseif g:DuplicateWrite_CreateNonExistingTargetDirectory ==# 'no'
	throw printf('DuplicateWrite: Cannot write "%s"; target directory does not exist', fnamemodify(a:filespec, ':~:.'))
    elseif g:DuplicateWrite_CreateNonExistingTargetDirectory ==# 'ask'
	let l:recalledResponse = (exists('g:DuplicateWrite_CreateDirResponse') ? g:DuplicateWrite_CreateDirResponse : -1)
	let l:response = (l:recalledResponse == -1 ?
	\   confirm(
	\       printf('The directory "%s" to write "%s" does not exist yet, create it?',
	\           l:dirspec, fnamemodify(a:filespec, ':t')
	\       ),
	\       "&Yes\n&No\n&Always\nNe&ver", 1, 'Question') :
	\   l:recalledResponse
	\)
	if     l:response == 1 || l:response == 3
	    if l:response == 3
		let g:DuplicateWrite_CreateDirResponse = 3
	    endif
	elseif l:response == 2
	    call ingo#msg#WarningMsg(printf('Skipping write to "%s"; target directory does not exist', fnamemodify(a:filespec, ':~:.')))
	    return 0
	elseif l:response == 4
	    let g:DuplicateWrite_CreateDirResponse = 4
	    call ingo#msg#WarningMsg(printf('Skipping write to "%s"; target directory does not exist', fnamemodify(a:filespec, ':~:.')))
	    return 0
	endif
    endif

    call mkdir(l:dirspec, 'p')
    return 1
endfunction
function! DuplicateWrite#EnsureAutocmd( shouldExistAlready )
    if exists('#DuplicateWrite#BufWritePost#<buffer>')
	return  | " Don't define twice.
    elseif a:shouldExistAlready && &verbose > 0
	call ingo#msg#WarningMsg('DuplicateWrite: Need to redefine the autocmds as they got lost (:setlocal nobuflisted causes that)')
    endif

    augroup DuplicateWrite
	autocmd! * <buffer>
	" Only trigger the duplicate write when the buffer is written with its
	" original name, not via :write /somewhere/else.txt; we can find out via
	" <afile>.
	"
	" Inside the loop, no new undo points are created. So, we need to invoke
	" DuplicateWrite#SetUndoPoint() only once before the loop; each
	" individual [+cmd] change by a duplicate write will then be undone to
	" that.
	autocmd BufWritePost <buffer> nested
	\   if ! exists('g:DuplicateWrite#Working') && expand('<afile>') ==# expand('%') |
	\       try |
	\           let g:DuplicateWrite#Working = 1 |
	\           let g:DuplicateWrite#SaveEventIgnore = &eventignore | let &eventignore = g:DuplicateWrite_EventIgnore |
	\           call DuplicateWrite#SetUndoPoint() |
	\           for g:DuplicateWrite#Object in b:DuplicateWrite |
	\               try |
	\                   if g:DuplicateWrite#Object.bang && ! v:cmdbang | continue | endif |
	\                   if ! DuplicateWrite#TargetDirectoryCheck(g:DuplicateWrite#Object.filespec) | continue | endif |
	\                   if &verbose > 0 && ! empty(g:DuplicateWrite#Object.preCmd) | echomsg 'DuplicateWrite: Execute' g:DuplicateWrite#Object.preCmd | endif |
	\                   execute g:DuplicateWrite#Object.preCmd |
	\                   execute 'keepalt' g:DuplicateWrite#Object.range . 'write!' join(map(g:DuplicateWrite#Object.opt, "escape(v:val, '\\ ')")) ingo#compat#fnameescape(g:DuplicateWrite#Object.filespec) |
	\                   if g:DuplicateWrite#Object.postCmd ==# 'UNDO' |
	\                       call DuplicateWrite#Undo() |
	\                   else |
	\                       if &verbose > 0 && ! empty(g:DuplicateWrite#Object.postCmd) | echomsg 'DuplicateWrite: Execute' g:DuplicateWrite#Object.postCmd | endif |
	\                       execute g:DuplicateWrite#Object.postCmd |
	\                   endif |
	\               catch /^Vim\%((\a\+)\)\=:/ |
	\                   call ingo#msg#VimExceptionMsg() |
	\                   sleep 1 |
	\               catch /^DuplicateWrite:/ |
	\                   call ingo#msg#CustomExceptionMsg('DuplicateWrite') |
	\                   sleep 1 |
	\               endtry |
	\           endfor |
	\       finally |
	\           let &eventignore = g:DuplicateWrite#SaveEventIgnore |
	\           unlet g:DuplicateWrite#Object g:DuplicateWrite#SaveEventIgnore g:DuplicateWrite#Working |
	\           call DuplicateWrite#EnsureAutocmd(1) |
	\       endtry |
	\   endif
	" Use try...catch to prevent the first write error from cancelling all
	" further cascaded writes.
	" To avoid that the error message is overwritten by subsequent
	" successful cascaded writes (and their potentially triggered autocmds),
	" wait for a second. The user can recall the error with :messages later.

	" Clear the autocmds, as they survive when the :bdelete'd buffer is
	" revived via :buffer.
	" Note: netrw temporarily clears 'buflisted' during its operation (on
	" :write scp://hostname/path); that also triggers the BufDelete event,
	" even though the buffer eventually remains active. To prevent the
	" removal of our autocmds, add a condition on this plugin not being
	" working.
	" Note: When BufDelete is fired, the current buffer isn't necessarily
	" the one where the event was defined on. Need to explicitly encode the
	" buffer number in the action to target the same buffer.
	execute "autocmd BufDelete <buffer> if ! exists('g:DuplicateWrite#Working') | execute 'autocmd! DuplicateWrite * <buffer=" . bufnr('') . ">' | endif"
    augroup END
endfunction

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

function! s:ProcessCmd( cmd, filespec)
    return substitute(a:cmd, '\%(\%(^\|[^\\]\)\%(\\\\\)*\\\)\@<!\(<tfile>\)\(\%(:[p8~.htreS]\|:g\?s\(.\).\{-}\3.\{-}\3\)*\)', '\=fnamemodify(a:filespec, submatch(2))', 'g')
endfunction
function! DuplicateWrite#ParseFilePatterns( filePatterns )
    " Strip off the optional ++opt +cmd file options and commands.
    let [l:filePatterns, l:fileOptionsAndCommands] = ingo#cmdargs#file#FilterFileOptionsAndCommands(a:filePatterns)

    let l:preCmd = (get(l:fileOptionsAndCommands, -1, '') =~# '^++\@!' ? remove(l:fileOptionsAndCommands, -1)[1:] : '')
    let l:opt = l:fileOptionsAndCommands

    " Strip off the optional -cmd file commands. As these are not Vim syntax, it
    " needs to be done separately.
    let l:postCmd = (get(l:filePatterns, 0, '') =~# '^-' ? remove(l:filePatterns, 0) : '')
    let l:postCmd = (l:postCmd ==# '-' ? 'UNDO' : l:postCmd[1:])

    return [l:opt, l:preCmd, l:postCmd, l:filePatterns]
endfunction
function! DuplicateWrite#Command( range, bang, filePatternsString, ... )
    let l:range = a:range
    if ! empty(l:range)
	" Obtain the original, unexpanded range from the command history so that
	" identifiers like . and $ continue to refer to the current position on
	" future saves. If we directly used the resolved line numbers, the range
	" would be static.
	let l:range = matchstr(histget('cmd', -1), '\C\%(^\||\)\s*\zs[^|]\+\ze\s*Duplicate\u')
	if empty(l:range)
	    let l:range = a:range   " Fall back to the static range if range extraction failed somehow.
	endif
    endif

    if empty(a:filePatternsString)
	return s:AddDefaultMirrors(l:range)
    endif

    let [l:opt, l:preCmd, l:postCmd, l:filePatterns] =
    \   DuplicateWrite#ParseFilePatterns(ingo#cmdargs#file#SplitAndUnescape(a:filePatternsString))
    let l:filespecs = ingo#cmdargs#glob#Expand(l:filePatterns, 1, 1)

    if a:0
	" Extension point: Allow an optional processing function to manipulate
	" the List of filespecs.
	if ! call(a:1, [l:filespecs])
	    return 0
	endif
    endif

    if len(l:filespecs) == 0
	call ingo#err#Set('file, dirspec, or glob required')
	return 0
    endif

    call ingo#err#Set('No file(s) have been added') " This may be overwritten by more specific errors in DuplicateWrite#Add().
    let l:cnt = 0
    for l:filespec in l:filespecs
	if DuplicateWrite#Add(l:range, a:bang, l:opt, s:ProcessCmd(l:preCmd, l:filespec), s:ProcessCmd(l:postCmd, l:filespec), l:filespec)
	    let l:cnt += 1
	endif
    endfor

    return (l:cnt > 0)
endfunction
function! s:AddDefaultMirrors( range )
    let l:configuration = ingo#plugin#setting#GetBufferLocal('DuplicateWrite_DefaultMirrors')
    call ingo#err#Set('No file(s) passed, and no default mirrors ' . (empty(l:configuration) ? 'defined' : 'apply')) " This may be overwritten by more specific errors in DuplicateWrite#Add().

    let l:originalFilespec = expand('%:p')
    let l:cnt = 0
    for [l:sourceGlob, l:argumentObject] in l:configuration
	let l:commonBase = matchstr(
	\   l:originalFilespec,
	\   (ingo#fs#path#IsCaseInsensitive(l:originalFilespec) ? '\c' : '\C') . ingo#regexp#fromwildcard#AnchoredToPathBoundaries(l:sourceGlob)
	\)
	if empty(l:commonBase)
	    continue
	endif

	let l:pathToFile = strpart(l:originalFilespec, strlen(l:commonBase))
	let l:filespec = ingo#fs#path#Normalize(
	\   empty(l:pathToFile) ?
	\       l:argumentObject.pathspec :
	\       ingo#fs#path#Combine(l:argumentObject.pathspec, l:pathToFile)
	\)
	if DuplicateWrite#Add(
	\   get(l:argumentObject, 'range', a:range),
	\   get(l:argumentObject, 'bang', 0),
	\   ingo#list#Make(get(l:argumentObject, 'opt', [])),
	\   get(l:argumentObject, 'preCmd', ''),
	\   get(l:argumentObject, 'postCmd', ''),
	\   l:filespec
	\)
	    let l:cnt += 1

	    call ingo#msg#StatusMsg(printf('Added duplicate write based on "%s" to %s',
	    \   l:sourceGlob,
	    \   s:ToString({
	    \       'range': get(l:argumentObject, 'range', a:range),
	    \       'bang': get(l:argumentObject, 'bang', 0),
	    \       'opt': ingo#list#Make(get(l:argumentObject, 'opt', [])),
	    \       'preCmd': get(l:argumentObject, 'preCmd', ''),
	    \       'postCmd': get(l:argumentObject, 'postCmd', ''),
	    \       'filespec': l:filespec
	    \   }
	    \)))
	endif
    endfor
    return (l:cnt > 0)
endfunction
function! DuplicateWrite#Add( range, bang, opt, preCmd, postCmd, target )
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

    call DuplicateWrite#EnsureAutocmd(0)

    let l:object = { 'filespec': l:targetFilespec, 'range': a:range, 'bang': a:bang, 'opt': a:opt, 'preCmd': a:preCmd, 'postCmd': a:postCmd }

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
    \   [a:object.bang ? '!' : ' '] +
    \   (empty(a:object.range) ? [] : [a:object.range]) +
    \   map(copy(a:object.opt), "escape(v:val, '\\ ')") +
    \   (empty(a:object.preCmd) ? [] : ['+' . escape(a:object.preCmd, '\ ')]) +
    \   (empty(a:object.postCmd) ? [] : ['-' . escape(a:object.postCmd, '\ ')]) +
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


function! DuplicateWrite#SetUndoPoint()
    let b:DuplicateWrite_Undo = { 'changenumber': changenr(), 'view': winsaveview() }
endfunction
function! s:Revert()
    let l:save_view = winsaveview()
	silent %delete _
	keepalt 1read
	silent 1delete _
    call winrestview(l:save_view)
    setlocal nomodified
endfunction
function! DuplicateWrite#Undo()
    let l:undoChangeNumber = b:DuplicateWrite_Undo.changenumber
    if l:undoChangeNumber < 0
	if &l:modified
	    " Undo is not available. (Soft-)reload the buffer instead.
	    call s:Revert()
	endif
    endif
    if changenr() > l:undoChangeNumber
	" What ever [+cmd] did, it is counted as a single change. So we don't
	" need to supply l:undoChangeNumber here. That's why we also could use
	" simple changenr() in DuplicateWrite#SetUndoPoint(), not the more
	" elaborate ingo#undo#GetChangeNumber().
	silent undo
    endif

    call winrestview(b:DuplicateWrite_Undo.view)
endfunction


function! DuplicateWrite#ScpCommand( range, bang, filePatternsString )
    if empty(a:filePatternsString)  " Should never happen, :DuplicateScp has mandatory arguments.
	call ingo#err#Set('No host(s) passed')
	return 0
    endif

    return DuplicateWrite#Command(a:range, a:bang, a:filePatternsString, function('s:HostArgumentsToFileSpecs'))
endfunction
function! s:HostArgumentsToFileSpecs( hostArguments )
    if empty(a:hostArguments)   " Can happen if only options have been passed.
	call ingo#err#Set('No host(s) passed')
	return 0
    endif

    let l:target = substitute(expand('%:p:~'), '^\~\V' . escape(ingo#fs#path#Separator(), '\'), '', '')
    if empty(l:target)
	call ingo#err#Set('No file name; either name the buffer or pass a full filespec')
	return 0
    endif

    call map(a:hostArguments, 'printf("scp://%s/%s", v:val, l:target)')
    return 1
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
