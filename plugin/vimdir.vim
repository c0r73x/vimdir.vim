" File:        vimdir.vim
" Version:     0.0.1
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
let g:vimdir_verbose = 1

if ! exists("g:vimdir_verbose")
    let g:vimdir_verbose = 0
endif

if ! exists("g:vimdir_show_hidden")
    let g:vimdir_show_hidden = 0
endif

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

                let l:dir = fnamemodify(expand(l:name), ':p:h')
                if ! isdirectory(l:dir)
                    call mkdir(l:dir, 'p')
                endif

                if exists("l:copy[".l:num."]")
                    if g:vimdir_verbose == 1
                        echo "copy ".b:sorted[l:num].' => '.l:name
                    endif
                    call system("cp -r ".l:fname." ".l:tname)
                else
                    if g:vimdir_verbose == 1
                        echo "move ".b:sorted[l:num].' => '.l:name
                    endif
                    call rename(l:fname, l:tname)
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
        end
    endfor

    call delete(expand('%'))
    exec 'bdelete!'
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
    let l:file = tempname()
    execute "badd ".l:file
    execute "buffer ".l:file

    setlocal ft=vimdir
    setlocal syntax=vidir-ls " Using vidir-ls vimplugin
    setlocal nolist
    setlocal textwidth=0

    let b:dirs = []
    let b:files = []

    if exists("a:1")
        exec "lcd".fnamemodify(expand(a:1), ':p')
        exec s:push(a:1, 1)
    else
        exec s:push('.', 1)
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