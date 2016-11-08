"
" TITLE:   VIM-MAKEJOB
" AUTHOR:  Daniel Moch <daniel@danielmoch.com>
" VERSION: 0.2
"
if exists('g:loaded_makejob') || version < 800
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
    let output = []
    while ch_status(a:channel, {'part': 'out'}) == 'buffered'
        let output += [ch_read(a:channel)]
    endwhile

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

    echo s:jobinfo[split(a:channel)[1]]['prog']." ended with "
                \ .len(makeoutput)." findings"
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
    let opts = { 'close_cb' : s:Function('s:JobHandler') }
    let job = job_start(joblist, opts)
    let s:jobinfo[split(job_getchannel(job))[1]] = {'prog': joblist[0],'lmake': a:lmake}
    echo s:jobinfo[split(job_getchannel(job))[1]]['prog'].' started'
endfunction

command! -nargs=? MakeJob call s:MakeJob(0,<f-args>)
command! -nargs=? LmakeJob call s:MakeJob(1,<f-args>)
