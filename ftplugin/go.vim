"==============================================================
"    file: go.vim
"   brief: 
" VIM Version: 8.0
"  author: tenfy
"   email: tenfyzhong@qq.com
" created: 2017-05-31 13:37:15
"==============================================================


let s:match_function = [{'pattern': '\m^exported \w\+ \%(\w\+\.\)\?\(\w\+\) should have comment or be unexported$', 'func': 'golint#fixer#exported'},
            \]

function! s:Fix() "{{{
    let cur_col = line('.')
    " let qflist = getloclist(0)
    let qflist = getqflist()
    for item in qflist
        if item['lnum'] == cur_col
            for mf in s:match_function
                let list = matchlist(item['text'], mf['pattern'])
                if !empty(list)
                    exec 'call ' . mf['func'] . '(mf["pattern"], item)'
                endif
            endfor
        endif
    endfor
endfunction "}}}

nnoremap <Plug>GoLintFix :GoLintFix<cr>

if !hasmapto('<Plug>GoLintFix')
    nmap <leader>lf <Plug>GoLintFix 
endif

command! -nargs=0 GoLintFix call <SID>Fix()
