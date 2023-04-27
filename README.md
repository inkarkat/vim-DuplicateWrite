DUPLICATE WRITE
===============================================================================
_by Ingo Karkat_

DESCRIPTION
------------------------------------------------------------------------------

Though you should use scripts for automated deployment and version control for
merges, sometimes, you need to quickly duplicate a file to another file system
location whenever it is changed.
This plugin defines a :DuplicateWrite command that sets up additional
:write targets. From then on, whenever you save that buffer, the write is
cascaded to the additional files. Thus, when editing a script in your project
directory, you can have it immediately (on only on demand, with [!]) copied to
the install directory that is in the PATH. Or, with the help of the netrw
plugin, you can even automatically upload a locally edited HTML page to the
remote web server.

### HOW IT WORKS

The plugin hooks into the BufWritePost event to issue additional :write
commands.

### RELATED WORKS

- The FileSync plugin ([vimscript #5064](http://www.vim.org/scripts/script.php?script_id=5064)) can automatically sync files or
  directory trees on write, using a Vim command like !cp, netrw plugin, or
  custom function.
- The mirror.vim plugin ([vimscript #5204](http://www.vim.org/scripts/script.php?script_id=5204)) needs a mirror configuration, and
  then provides custom commands to open, diff, push, etc. mirrored files.

USAGE
------------------------------------------------------------------------------

    :[range]DuplicateWrite[!] [++opt] [+cmd] [-cmd] {file}|{dirspec} [...]
                            Create a cascaded write of [range in, keeping
                            specifiers like . and $ and dynamically re-evaluating
                            them on each write] the current buffer to the
                            specified {file}, or to a file with the same filename
                            located in {dirspec}. From now on, whenever the buffer
                            is |:w|ritten, it will also be persisted to the passed
                            location. (Until you :bdelete it.)
                            With [!], duplication only happens with forced
                            :write!, not with :write. This is useful if the
                            duplication target is on a slow networked filesystem
                            or if a file write triggers other costly actions
                            (like a service restart after a config update).
                            [++opt] is passed to :write. An optional [+cmd] is
                            executed before the write; likewise, [-cmd] is
                            executed after the write; the degenerate [-] will
                            :undo any changes to the buffer done by [+cmd].
                            In the {cmd}s, spaces and also special characters
                            (cmdline-special) like % and <cword> must be
                            escaped. The plugin supports a special <tfile>
                            identifer that gets replaced with the duplicated
                            target file.

                            You can issue the command multiple times (with
                            different {file} targets) for a buffer to add cascades
                            to several concurrent locations.

    :[range]DuplicateScp[!] [++opt] [+cmd] [-cmd] [{user}@]{host} [...]
                            Create a cascaded write of [range in] the current
                            buffer to the same (relative to $HOME / absolute) file
                            system location on remote {host} [logging in with
                            {user}].
                            Leverages the netrw plugin. You can also directly
                            pass the
                                scp://{host}/{path}
                            to :DuplicateWrite, but this variant saves you from
                            remembering the syntax and the path mangling.

    :DuplicateWriteOff      Turn off all cascaded writes for the current buffer.

    :DuplicateWriteList     List the cascaded write target(s) for the current
                            buffer.

    :DuplicateWriteListAll  List the cascaded write target(s) for all open
                            buffers that have any. The buffers are listed with
                            their number followed by the name; the targets are
                            listed in the following, indented lines, for example:
                            4  "DuplicateWrite.txt" ->
                                    "C:\temp\DuplicateWrite.txt"
                                    "X:\backup.txt"

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-DuplicateWrite
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim DuplicateWrite*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.
- Requires the ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.025 or
  higher.

CONFIGURATION
------------------------------------------------------------------------------

For a permanent configuration, put the following commands into your vimrc:

To avoid giving an argument to :DuplicateWrite, you can define a List of
{source-glob}, {argument-object} pairs: The part of the buffer's filespec that
matches {source-glob} will then be replaced by {argument-object}.pathspec to
yield the target:

    let g:DuplicateWrite_DefaultMirrors = [
    \   ['D:\project\foo', {'pathspec': 'X:\foo'}],
    \   ['**\src\**', {
    \                   'pathspec': 'E:\deploy',
    \                   'bang': 0,
    \                   'range': '100,$',
    \                   'opt': '++ff=dos',
    \                   'preCmd': '%s/Copyright: \zsXXXX/Acme Corp/e,
    \                   'postCmd': 'UNDO'
    \                 }]
    \]

This would for example duplicate a file D:\\project\\foo\\bin\\zap.cmd to
X:\\foo\\bin\\zap.cmd and any file anywhere inside a src/ directory directly to
E:\\deploy when you execute :DuplicateWrite. A buffer-local configuration
overrides the global one. All matching {source-glob} are processed, so if you
need to duplicate to multiple locations, define several same {source-glob}s.

The duplicate writes themselves also trigger |autocmd|s; we need this nesting
to let plugins like netrw interfere and handle special (remote) filesystem
locations. However, other plugins may also be triggered, and that may be
undesirable (for example, you don't want to trigger syntax checking on the
duplicates, or add them to a MRU list in Vim). Because of this, the plugin
ignores certain events (via 'eventignore') during its execution:

    let g:DuplicateWrite_EventIgnore = 'BufWritePre,BufWritePost'

Especially when using default mirrors, the target directory for the duplicated
write may not exist yet. The following variable defines the plugin's behavior
in that case; either "no", "yes", or "ask":

    let g:DuplicateWrite_CreateNonExistingTargetDirectory = 'ask'

Remote target directories (e.g. netrw URLs like scp://path/to/file) cannot
be checked for existence; in order to be able to write to them (and skip the
useless target directory check), certain dirspecs (also local ones) can be
exempted. Any dirspec that matches the regular expression not checked:

    let g:DuplicateWrite_TargetDirectoryCheckIgnorePattern = '^\a\+://'

INTEGRATION
------------------------------------------------------------------------------

The filespecs of the cascaded write targets are stored in the buffer-local
List variable b:DuplicateWrite. You can use its existence / number of elements
to determine whether / how many duplications are configured, and use this e.g.
in a custom 'statusline'. To programatically add duplicate writes, use the
DuplicateWrite#Add() function.

CONTRIBUTING
------------------------------------------------------------------------------

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-DuplicateWrite/issues or email (address
below).

HISTORY
------------------------------------------------------------------------------

##### 2.10    RELEASEME
- ENH: Add :DuplicateScp [{user}@]{host} [...] variant of :DuplicateWrite that
  streamlines netrw usage to the same location on another host.
- ENH: Support an optional [range] for :DuplicateWrite and :DuplicateScp to
  only persist part of the buffer. (For example, just the JavaScript part of a
  GitHub action, or a scriptlet embedded in a Markdown file.) To be more
  useful, the original range is extracted from the command history and
  reevaluated on each write, so that addresses like . and $ are adapted to the
  current situation.

##### 2.01    29-Jun-2018
- The target directory check interferes with remote (netrw) targets. Add
  g:DuplicateWrite\_TargetDirectoryCheckIgnorePattern configuration that skips
  URIs by default.
- BUG: A netrw target (e.g. scp://hostname/path) causes the autocmds to get
  lost.
- FIX: Cleanup of autocmds may not apply after :bdelete.

##### 2.00    24-Aug-2016
- ENH: Support passing [++opt] [+cmd] [-cmd] before filespecs, and allow
  multiple filespec arguments to :DuplicateWrite.
- ENH: Add default mirror configuration in g:DuplicateWrite\_DefaultMirrors.
- Use nested autocmds, but allow to suppress certain events via
  g:DuplicateWrite\_EventIgnore.
- ENH: Check for existence of target directory, and react according to
  g:DuplicateWrite\_CreateNonExistingTargetDirectory.
- ENH: Support duplicate write only with :write when using :DuplicateWrite!
  during definition.

__You need to update to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.025!__

##### 1.01    13-Sep-2013
- FIX: Use full absolute path and normalize to be immune against changes in
  CWD.

__You need to update to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.013!__

##### 1.00    13-Sep-2013
- First published version after a complete reimplementation.

##### 0.01    19-Jul-2005
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2005-2023 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat &lt;ingo@karkat.de&gt;
