" File:        vimdir.vim
" Version:     0.0.2
" Description: Manage files and directories in vim
" Maintainer:  Christian Persson <c0r73x@gmail.com>
" Repository:  https://github.com/c0r73x/vimdir.vim
" License:     Copyright (C) 2014 Christian Persson
"              Released under the MIT license
"
" Inspired by vidir by Joey Hess (https://joeyh.name/code/moreutils/)

if exists("g:loaded_vimdir")
    finish
endif

let g:loaded_vimdir = 1

if ! exists("g:vimdir_verbose")
    let g:vimdir_verbose = 0
endif

if ! exists("g:vimdir_show_hidden")
    let g:vimdir_show_hidden = 0
endif

if ! exists("g:vimdir_force")
    let g:vimdir_force = 0
endif

function! s:confirm(text, choices, default)
    if g:vimdir_force == 0
        return confirm(a:text, a:choices, a:default)
    endif

    return 1
endfunction

function! s:process()
    let l:remove = copy(b:sorted)
    let l:copy = []

    for i in range(0, line('$'))
        let l:line = getline(i)

        if len(matchstr(l:line, '^\s*\(\d\+\)\s\+\(.*\)$')) > 0
            let l:match = matchlist(l:line, '^\s*\(\d\+\)\s\+\(.*\)$')

            let l:num = l:match[1]
            let l:name = l:match[2]

            let l:remove[l:num] = ''

            if l:name != b:sorted[l:num]
                let l:fname = fnamemodify(expand(b:sorted[l:num]), ':p')
                let l:tname = fnamemodify(expand(l:name), ':p')

                if ! filereadable(l:fname)
                    echohl ErrorMsg
                                \ | echomsg b:sorted[l:num] . " does not exist!"
                                \ | echohl None
                    next
                endif

                let l:dir = fnamemodify(expand(l:name), ':p:h')
                if ! isdirectory(l:dir)
                    call mkdir(l:dir, 'p')
                endif

                if filereadable(l:tname)
                    let l:tmp = l:name . '~'
                    let l:c = 0

                    while filereadable(l:tmp)
                        let l:c = l:c + 1
                        let l:tmp = l:name . '~' . l:c
                    endwhile

                    if g:vimdir_verbose == 1
                        echo "tmp move ".l:name.' => '.l:tmp
                    endif

                    if rename(l:name, l:tmp) != 0
                        echohl ErrorMsg
                                    \ | echomsg "Failed to rename "
                                    \ . l:name . " to " . l:tmp ."!"
                                    \ | echohl None
                    endif

                    for r in range(0, len(b:sorted) - 1)
                        if l:name == b:sorted[r]
                            let l:remove[r] = ''
                            let b:sorted[r] = l:tmp
                        endif
                    endfor
                endif

                if exists("l:copy[".l:num."]")
                    if g:vimdir_verbose == 1
                        echo "copy ".b:sorted[l:num].' => '.l:name
                    endif
                    if system("cp -r ".l:fname." ".l:tname." 2>&1") != ''
                        echohl ErrorMsg
                                    \ | echomsg "Failed to copy "
                                    \ . l:fname . " to " . l:tname ."!"
                                    \ | echohl None
                    endif
                else
                    if g:vimdir_verbose == 1
                        echo "move ".b:sorted[l:num].' => '.l:name
                    endif
                    if rename(l:fname, l:tname) != 0
                        echohl ErrorMsg
                                    \ | echomsg "Failed to rename "
                                    \ . l:fname . " to " . l:tname ."!"
                                    \ | echohl None
                    endif
                endif
            else
                let l:name = b:sorted[l:num]
            endif

            call add(l:copy,1)
            let b:sorted[l:num] = l:name

        elseif len(matchstr(l:line, '^\s*.*\/$')) > 0
            let l:dir = matchlist(l:line, '^\s*\(.*\)\/$')[1]
            call mkdir(l:dir, 'p')

            if g:vimdir_verbose == 1
                echo 'created directory '.l:dir
            endif
        elseif len(matchstr(l:line, '^\s*.*$')) > 0
            let l:nfile = matchlist(l:line, '^\s*\(.*\)$')[1]

            let l:dir = fnamemodify(expand(l:nfile), ':p:h')
            if ! isdirectory(l:dir)
                call mkdir(l:dir, 'p')
            endif

            call system('touch ' . l:nfile)

            if g:vimdir_verbose == 1
                echo 'created '.l:nfile
            endif
        endif
    endfor

    for r in range(0, len(l:remove)-1)
        if len(l:remove[r]) > 0
            let b:sorted[r] = ''
            let l:rname = fnamemodify(expand(l:remove[r]), ':p')

            if(s:confirm("Are you sure you want to delete " . l:rname . "?",
                        \ "&Yes\n&No",
                        \ 1) == 1)

                if isdirectory(l:rname)
                    call system("rm -r " . l:rname . "&")

                    if g:vimdir_verbose == 1
                        echo "removed ".l:remove[r]
                    endif
                else
                    if delete(l:rname) == 0
                        if g:vimdir_verbose == 1
                            echo "removed ".l:remove[r]
                        endif
                    else
                        echohl ErrorMsg
                                    \ | echomsg "Failed to remove " . l:remove[r]
                                    \ | echohl None
                    endif
                endif
            endif
        end
    endfor

    call delete(expand('%'))
    exec '%delete'

    call s:list()
endfunction

function! s:push(path, first)
    if isdirectory(a:path)
        if g:vimdir_show_hidden == 1
            let l:dir=split(globpath(a:path,"*") . "\n" .
                        \ globpath(a:path,".[^.]*"))
        else
            let l:dir=split(globpath(a:path, '*'), '\n')
        endif

        if a:first != 1
            call add(b:dirs, a:path."/")
        endif

        if exists("s:recursive") || a:first == 1
            if len(l:dir) > 0
                for i in range(0, (len(l:dir)-1))
                    exec s:push(l:dir[i], 0)
                endfor
            endif
        endif
    else
        call add(b:files, a:path)
    endif
endfunction

function! s:list(...)
    let l:path = '.'

    if exists("b:vimdir_path")
        let l:path = b:vimdir_path
    else
        if exists("a:1")
            let l:path = a:1
        endif

        let l:file = tempname()
        execute "badd ".l:file
        execute "buffer ".l:file

        setlocal ft=vimdir
        setlocal syntax=vidir-ls " Using vidir-ls vimplugin
        setlocal nolist
        setlocal textwidth=0

        let b:vimdir_path = l:path
    endif

    let b:dirs = []
    let b:files = []

    let l:fname = fnamemodify(expand(l:path), ':p')

    if !empty(glob(l:fname)) && isdirectory(l:fname)
        exec s:push(l:path, 1)
    else
        call delete(expand('%'))
        exec 'bdelete!'

        echohl ErrorMsg
                    \ | echomsg "Couldn't open directory \"" .a:1."\""
                    \ | echohl None
        return
    endif

    if exists("s:recursive")
        let b:sorted = sort(b:dirs + b:files)
    else
        let b:sorted = sort(b:dirs) + sort(b:files)
    endif

    for i in range(0, (len(b:sorted)-1))
        call append(line('$')-1,"\t".i."\t".b:sorted[i])
    endfor

    autocmd BufWritePost <buffer> :exec s:process()
endfunction

function! s:vimdir_recursive(...)
    let s:recursive = 1
    call call("s:list", a:000)
endfunction

function! s:vimdir(...)
    if exists("s:recursive")
        unlet s:recursive
    endif

    call call("s:list", a:000)
endfunction

command! -complete=dir -nargs=? Vimdir :execute s:vimdir(<f-args>)
command! -complete=dir -nargs=? VimdirR :execute s:vimdir_recursive(<f-args>)

let g:loaded_vimdir = 2
