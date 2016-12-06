"
" TITLE:   VIM-MAKEJOB
" AUTHOR:  Daniel Moch <daniel@danielmoch.com>
" VERSION: 1.1.1-dev
"
if exists('g:loaded_makejob') || version < 800 || !has('job') ||
            \ !has('channel') || !has('quickfix')
    finish
endif
let g:loaded_makejob = 1

let s:jobinfo = {}

function! s:JobHandler(channel) abort
    let job = remove(s:jobinfo, split(a:channel)[1])
    let is_lmake = job['lmake']

    " For reasons I don't understand, copying and re-writing
    " errorformat fixes a lot of parsing errors
    let tempefm = job['grep'] ? &grepformat : &errorformat
    if job['grep']
        let &grepformat = tempefm
    else
        let &errorformat = tempefm
    endif

    execute bufwinnr(job['srcbufnr']).'wincmd w'

    if is_lmake
        let qfcmd = job['grepadd'] ? 'laddbuffer' : 'lgetbuffer'
    else
        let qfcmd = job['grepadd'] ? 'caddbuffer' : 'cgetbuffer'
    endif

    if bufwinnr(job['outbufnr'])
        silent execute bufwinnr(job['outbufnr']).'close'
    endif
    silent execute qfcmd.' '.job['outbufnr']
    silent execute job['outbufnr'].'bwipe!' 
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

    if job['grep']
        if is_lmake
            silent doautocmd QuickFixCmdPost lgrep
        else
            silent doautocmd QuickFixCmdPost grep
        endif
    else
        if is_lmake
            silent doautocmd QuickFixCmdPost lmake
        else
            silent doautocmd QuickFixCmdPost make
        endif
    end

    if job['cfirst']
        silent! cfirst
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

function! s:Expand(input)
    let split_input = split(a:input)
    let expanded_input = []
    for token in split_input
        if expand(token) != ''
            let expanded_input += [expand(token)]
        else
            let expanded_input += [token]
        endif
    endfor
    return join(expanded_input)
endfunction

function! s:MakeJob(grep, lmake, grepadd, bang, ...)
    let make = a:grep ? s:Expand(&grepprg) : s:Expand(&makeprg)
    let prog = split(make)[0]
    let internal_grep = make ==# 'internal' ? 1 : 0
    execute 'let openbufnr = bufnr("^'.prog.'$")'
    if openbufnr != -1
        echohl WarningMsg
        echomsg prog.' already running'
        echohl None
        return
    endif
    "  Need to check for whitespace inputs as well as no input
    if a:0 && (a:1 != '')
        if a:grep
            if internal_grep
                let make = 'vimgrep '.a:1
            elseif make =~ '\$\*'
                let make = [&shell, &shellcmdflag, substitute(make, '\$\*', a:1, 'g')]
            else
                let make = [&shell, &shellcmdflag, make.' '.a:1]
            endif
        else
            let trimmed_arg = substitute(a:1, '^\s\+\|\s\+$', '', 'g')
            let make = make.' '.expand(trimmed_arg)
        endif
    else
        echohl ErrorMsg
        if a:lmake
            let grepname = grepadd ? 'LgrepAddJob' : 'LgrepJob'
        else
            let grepname = grepadd ? 'GrepAddJob' : 'GrepJob'
        endif
        echomsg 'Passed only whitespace to '.grepname
        echohl None
        return
    endif

    let opts = { 'close_cb' : function('s:JobHandler'),
                \ 'out_io': 'buffer',
                \ 'out_name': prog,
                \ 'out_modifiable': 0,
                \ 'err_io': 'buffer',
                \ 'err_name': prog,
                \ 'err_modifiable': 0,
                \ 'in_io': 'null'}

    if a:grep
        if a:lmake
            silent doautocmd QuickFixCmdPre lgrep
        else
            silent doautocmd QuickFixCmdPre grep
        endif
    else
        if a:lmake
            silent doautocmd QuickFixCmdPre lmake
        else
            silent doautocmd QuickFixCmdPre make
        endif
    endif

    if &autowrite && !a:grep
        silent write
    endif

    if internal_grep
        execute make
        return
    else
        let outbufnr = s:CreateMakeJobWindow(prog)

        let job = job_start(make, opts)
        let s:jobinfo[split(job_getchannel(job))[1]] = 
                    \ { 'prog': prog,'lmake': a:lmake,
                    \   'outbufnr': outbufnr, 'srcbufnr': winbufnr(0),
                    \   'cfirst': !a:bang, 'grep': a:grep,
                    \    'grepadd': a:grepadd }
        echomsg s:jobinfo[split(job_getchannel(job))[1]]['prog'].' started'
    end
endfunction

command! -bang -nargs=* -complete=file MakeJob call s:MakeJob(0,0,0,<bang>0,<q-args>)
command! -bang -nargs=* -complete=file LmakeJob call s:MakeJob(0,1,0,<bang>0,<q-args>)
command! -bang -nargs=+ -complete=file GrepJob call s:MakeJob(1,0,0,<bang>0,<q-args>)
command! -bang -nargs=+ -complete=file LgrepJob call s:MakeJob(1,1,0,<bang>0,<q-args>)
command! -bang -nargs=+ -complete=file GrepaddJob call s:MakeJob(1,0,1,<bang>0,<q-args>)
command! -bang -nargs=+ -complete=file LgrepaddJob call s:MakeJob(1,1,1,<bang>0,<q-args>)
