"
" TITLE:   VIM-MAKEJOB
" AUTHOR:  Daniel Moch <daniel@danielmoch.com>
" VERSION: 0.3
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
    let is_lmake = s:jobinfo[split(a:channel)[1]]['lmake']
    let output = getbufline('MakeJob', 1, '$')
    silent bdelete! MakeJob 

    " For reasons I don't understand, copying and re-writing
    " errorformat fixes a lot of parsing errors
    let tempefm = &errorformat
    let &errorformat = tempefm

    if is_lmake
        lgetexpr output
    else
        cgetexpr output
    endif

    let initqf = is_lmake ? getloclist(winnr()) : getqflist()
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

    echomsg s:jobinfo[split(a:channel)[1]]['prog']." ended with "
                \ .makeoutput." findings"
endfunction

function! s:MakeJob(lmake, ...)
    let make = &makeprg
    if a:0
        if a:1 == '%'
            let make = make.' '.bufname(a:1)
        else
            let make = make.' '.a:1
        endif
    endif
    let opts = { 'close_cb' : s:Function('s:JobHandler'),
                \ 'out_io': 'buffer', 'out_name': 'MakeJob' }

    if a:lmake
        silent doautocmd QuickFixCmdPre lmake
    else
        silent doautocmd QuickFixCmdPre make
    endif

    if &autowrite
        silent write
    endif

    silent belowright pedit MakeJob

    let job = job_start(make, opts)
    let s:jobinfo[split(job_getchannel(job))[1]] = {'prog': split(make)[0],'lmake': a:lmake}
    echomsg s:jobinfo[split(job_getchannel(job))[1]]['prog'].' started'
endfunction

command! -nargs=? MakeJob call s:MakeJob(0,<f-args>)
command! -nargs=? LmakeJob call s:MakeJob(1,<f-args>)
