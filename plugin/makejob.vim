"
" TITLE:   NVIM-MAKEJOB
" AUTHOR:  Daniel Moch <daniel@danielmoch.com>
" VERSION: 0.1
"
if exists('g:loaded_makejob') || !has('nvim')
    finish
endif
let g:loaded_makejob = 1

let s:jobinfo = {}

function! s:JobHandler(job_id, data, event_type) abort
    if a:event_type == 'stdout' && type(a:data) == type([])
        let s:jobinfo[a:job_id]['output'] =
                    \ s:jobinfo[a:job_id]['output'][:-2] +
                    \ [s:jobinfo[a:job_id]['output'][-1] . get(a:data,
                    \ 0, '')] +
                    \ a:data[1:]
    elseif a:event_type == 'exit'
        let is_lmake = s:jobinfo[a:job_id]['lmake']
        let output = s:jobinfo[a:job_id]['output']

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
        let makeoutput = []
        let idx = 0
        while idx < len(initqf)
            let qfentry = initqf[idx]
            if qfentry['valid']
                let makeoutput += [qfentry]
            endif
            let idx += 1
        endwhile

        if is_lmake
            call setloclist(winnr(), makeoutput, 'r')
        else
            call setqflist(makeoutput, 'r')
        endif

        echo s:jobinfo[a:job_id]['prog']." ended with "
                    \ .len(makeoutput)." findings"
    endif
endfunction

function! s:NumChars(string, char, ...)
    if a:0
        let idx = stridx(a:string, a:char, a:1 + 1)
        let recursenum = a:2
    else
        let idx = stridx(a:string, a:char)
        let recursenum = 0
    endif
    if idx >= 0
        return s:NumChars(a:string, a:char, idx, recursenum + 1)
    else
        return recursenum
    endif
endfunction

function! s:NormalizeJobList(joblist)
    let idx = 0
    let normalized = []
    while idx < len(a:joblist)
        let param = a:joblist[idx]
        if s:NumChars(param, '"') == 1
            let idx2 = idx + 1
            for nextparam in a:joblist[idx2:]
                if stridx(nextparam, '"') >= 0
                    let normalized += [join(a:joblist[idx:idx2])]
                    let idx = idx2
                    break
                endif
                let idx2 += 1
            endfor
        else
            let normalized += [param]
        endif
        let idx += 1
    endwhile
    return normalized
endfunction

function! s:MakeJob(lmake, ...)
    let joblist = s:NormalizeJobList(split(&makeprg))
    if a:0
        if a:1 == '%'
            let joblist += [bufname(a:1)]
        else
            let joblist += [a:1]
        endif
    endif
    let opts = {
                \ 'on_stdout': function('s:JobHandler'),
                \ 'on_stderr': function('s:JobHandler'),
                \ 'on_exit': function('s:JobHandler')
                \ }
    let jobid = jobstart(joblist, opts)
    let s:jobinfo[jobid] = {'prog': joblist[0], 'output': [''],
                \ 'lmake': a:lmake}
    echo s:jobinfo[jobid]['prog'].' started'
endfunction

command! -nargs=? MakeJob call s:MakeJob(0,<f-args>)
command! -nargs=? LmakeJob call s:MakeJob(1,<f-args>)
