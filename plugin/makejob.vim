"
" TITLE:   VIM-MAKEJOB
" AUTHOR:  Daniel Moch <daniel@danielmoch.com>
" VERSION: 1.0
"
if exists('g:loaded_makejob') || version < 800 || !has('job') ||
            \ !has('channel')
    finish
endif
let g:loaded_makejob = 1

let s:jobinfo = {}

function! s:Function(name)
    return substitute(a:name, '^s:', matchstr(expand('<sfile>'), 
                \'<SNR>\d\+_\ze[fF]unction$'),'')
endfunction

function! s:JobHandler(channel) abort
    let job = remove(s:jobinfo, split(a:channel)[1])
    let is_lmake = job['lmake']
    let output = getbufline(job['outbufnr'], 1, '$')
    silent execute job['outbufnr'].'bdelete!' 

    " For reasons I don't understand, copying and re-writing
    " errorformat fixes a lot of parsing errors
    let tempefm = &errorformat
    let &errorformat = tempefm

    execute bufwinnr(job['srcbufnr']).'wincmd w'

    if is_lmake
        lgetexpr output
    else
        cgetexpr output
    endif

    wincmd p

    let initqf = is_lmake ? getloclist(bufwinnr(job['srcbufnr'])) : getqflist()
    let makeoutput = 0
    let idx = 0
    while idx < len(initqf)
        let qfentry = initqf[idx]
        if qfentry['valid']
            let makeoutput += 1
        endif
        let idx += 1
    endwhile

    if is_lmake
        silent doautocmd QuickFixCmdPost lmake
    else
        silent doautocmd QuickFixCmdPost make
    endif

    echomsg job['prog']." ended with ".makeoutput." findings"
endfunction

function! s:CreateMakeJobWindow(prog)
    silent execute 'belowright 10split '.a:prog
    setlocal bufhidden=wipe buftype=nofile nobuflisted nolist
    setlocal noswapfile nowrap nomodifiable
    let bufnum = winbufnr(0)
    wincmd p
    return bufnum
endfunction

function! s:MakeJob(lmake, ...)
    let make = &makeprg
    let prog = split(make)[0]
    execute 'let openbufnr = bufnr("^'.prog.'$")'
    if openbufnr != -1
        echohl WarningMsg
        echo prog.' already running'
        echohl None
        return
    endif
    if a:0
        if a:1 == '%'
            let make = make.' '.bufname(a:1)
        else
            let make = make.' '.a:1
        endif
    endif
    let opts = { 'close_cb' : s:Function('s:JobHandler'),
                \ 'out_io': 'buffer', 'out_name': prog,
                \ 'out_modifiable': 0 }

    if a:lmake
        silent doautocmd QuickFixCmdPre lmake
    else
        silent doautocmd QuickFixCmdPre make
    endif

    if &autowrite
        silent write
    endif

    let outbufnr = s:CreateMakeJobWindow(prog)

    let job = job_start(make, opts)
    let s:jobinfo[split(job_getchannel(job))[1]] = 
                \ { 'prog': prog,'lmake': a:lmake,
                \   'outbufnr': outbufnr, 'srcbufnr': winbufnr(0) }
    echomsg s:jobinfo[split(job_getchannel(job))[1]]['prog'].' started'
endfunction

command! -nargs=? MakeJob call s:MakeJob(0,<f-args>)
command! -nargs=? LmakeJob call s:MakeJob(1,<f-args>)
