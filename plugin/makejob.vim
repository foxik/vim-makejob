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

function! s:InitAutocmd(lmake, grep, cmd)
    let l:returnval = 'doautocmd QuickFixCmd'.a:cmd.' '
    if a:grep
        let l:returnval .= a:lmake ? 'lgrep' : 'grep'
    else
        let l:returnval .= a:lmake ? 'lmake' : 'make'
    end
    return l:returnval
endfunction

function! s:JobHandler(channel) abort
    let l:job = remove(s:jobinfo, split(a:channel)[1])

    " For reasons I don't understand, copying and re-writing
    " errorformat fixes a lot of parsing errors
    let l:tempefm = l:job['grep'] ? &grepformat : &errorformat
    if l:job['grep']
        let &grepformat = l:tempefm
    else
        let &errorformat = l:tempefm
    endif

    execute bufwinnr(l:job['srcbufnr']).'wincmd w'

    if l:job['lmake']
        let l:qfcmd = l:job['grepadd'] ? 'laddbuffer' : 'lgetbuffer'
    else
        let l:qfcmd = l:job['grepadd'] ? 'caddbuffer' : 'cgetbuffer'
    endif

    if bufwinnr(l:job['outbufnr'])
        silent execute bufwinnr(l:job['outbufnr']).'close'
    endif
    silent execute l:qfcmd.' '.l:job['outbufnr']
    silent execute l:job['outbufnr'].'bwipe!' 
    wincmd p

    let l:initqf = l:job['lmake'] ? getloclist(bufwinnr(job['srcbufnr'])) : getqflist()
    let l:makeoutput = 0
    let l:idx = 0
    while l:idx < len(l:initqf)
        let l:qfentry = l:initqf[l:idx]
        if l:qfentry['valid']
            let l:makeoutput += 1
        endif
        let l:idx += 1
    endwhile

    silent execute s:InitAutocmd(l:job['lmake'], l:job['grep'], 'Post')

    if l:job['cfirst']
        silent! cfirst
    end

    echomsg l:job['prog']." ended with ".l:makeoutput." findings"
endfunction

function! s:CreateMakeJobWindow(prog)
    silent execute 'belowright 10split '.a:prog
    setlocal bufhidden=hide buftype=nofile nobuflisted nolist
    setlocal noswapfile nowrap nomodifiable
    let l:bufnum = winbufnr(0)
    wincmd p
    return l:bufnum
endfunction

function! s:Expand(input)
    let l:split_input = split(a:input)
    let l:expanded_input = []
    for l:token in l:split_input
        if l:token != '$*' && expand(l:token) != ''
            let l:expanded_input += [expand(l:token)]
        else
            let l:expanded_input += [l:token]
        endif
    endfor
    return join(l:expanded_input)
endfunction

function! s:MakeJob(grep, lmake, grepadd, bang, ...)
    let l:make = a:grep ? s:Expand(&grepprg) : s:Expand(&makeprg)
    let l:prog = split(l:make)[0]
    let l:internal_grep = l:make ==# 'internal' ? 1 : 0
    execute 'let l:openbufnr = bufnr("^'.l:prog.'$")'
    if l:openbufnr != -1
        echohl WarningMsg
        echomsg l:prog.' already running'
        echohl None
        return
    endif
    "  Need to check for whitespace inputs as well as no input
    if a:0 && (a:1 != '')
        if a:grep
            if l:internal_grep
                let l:make = 'vimgrep '.a:1
            elseif l:make =~ '\$\*'
                let l:make = [&shell, &shellcmdflag, substitute(l:make, '\$\*', a:1, 'g')]
            else
                let l:make = [&shell, &shellcmdflag, l:make.' '.a:1]
            endif
        else
            let l:trimmed_arg = substitute(a:1, '^\s\+\|\s\+$', '', 'g')
            let l:make = l:make.' '.expand(l:trimmed_arg)
        endif
    endif

    let l:opts = { 'close_cb' : function('s:JobHandler'),
                \ 'out_io': 'buffer',
                \ 'out_name': l:prog,
                \ 'out_modifiable': 0,
                \ 'err_io': 'buffer',
                \ 'err_name': l:prog,
                \ 'err_modifiable': 0,
                \ 'in_io': 'null'}

    silent execute s:InitAutocmd(a:lmake, a:grep, 'Pre')

    if &autowrite && !a:grep
        silent write
    endif

    if l:internal_grep
        execute l:make
        return
    else
        let l:outbufnr = s:CreateMakeJobWindow(prog)

        let l:job = job_start(l:make, l:opts)
        let s:jobinfo[split(job_getchannel(l:job))[1]] = 
                    \ { 'prog': l:prog,'lmake': a:lmake,
                    \   'outbufnr': l:outbufnr, 'srcbufnr': winbufnr(0),
                    \   'cfirst': !a:bang, 'grep': a:grep,
                    \    'grepadd': a:grepadd }
        echomsg s:jobinfo[split(job_getchannel(l:job))[1]]['prog'].' started'
    end
endfunction

command! -bang -nargs=* -complete=file MakeJob call s:MakeJob(0,0,0,<bang>0,<q-args>)
command! -bang -nargs=* -complete=file LmakeJob call s:MakeJob(0,1,0,<bang>0,<q-args>)
command! -bang -nargs=+ -complete=file GrepJob call s:MakeJob(1,0,0,<bang>0,<q-args>)
command! -bang -nargs=+ -complete=file LgrepJob call s:MakeJob(1,1,0,<bang>0,<q-args>)
command! -bang -nargs=+ -complete=file GrepaddJob call s:MakeJob(1,0,1,<bang>0,<q-args>)
command! -bang -nargs=+ -complete=file LgrepaddJob call s:MakeJob(1,1,1,<bang>0,<q-args>)
