"
" TITLE:   VIM-MAKEJOB
" AUTHOR:  Daniel Moch <daniel@danielmoch.com>
" VERSION: 1.0.2-dev
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
    silent execute job['outbufnr'].'bwipe!' 

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

    if job['cfirst']
        cfirst
    end

    echomsg job['prog']." ended with ".makeoutput." findings"
endfunction

function! s:CreateMakeJobWindow(prog)
    silent execute 'belowright 10split '.a:prog
    setlocal bufhidden=hide buftype=nofile nobuflisted nolist
    setlocal noswapfile nowrap nomodifiable
    let bufnum = winbufnr(0)
    wincmd p
    return bufnum
endfunction

function! s:MakeJob(lmake, bang, ...)
    let make = &makeprg
    let prog = split(make)[0]
    execute 'let openbufnr = bufnr("^'.prog.'$")'
    if openbufnr != -1
        echohl WarningMsg
        echomsg prog.' already running'
        echohl None
        return
    endif
    if a:0
        let make = make.' '.expand(a:1)
    endif
    let opts = { 'close_cb' : s:Function('s:JobHandler'),
                \ 'out_io': 'buffer',
                \ 'out_name': prog,
                \ 'out_modifiable': 0,
                \ 'err_io': 'buffer',
                \ 'err_name': prog,
                \ 'err_modifiable': 0}

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
                \   'outbufnr': outbufnr, 'srcbufnr': winbufnr(0),
                \   'cfirst': !a:bang }
    echomsg s:jobinfo[split(job_getchannel(job))[1]]['prog'].' started'
endfunction

command! -bang -nargs=? -complete=file MakeJob call s:MakeJob(0,<bang>0,<f-args>)
command! -bang -nargs=? -complete=file LmakeJob call s:MakeJob(1,<bang>0,<f-args>)
