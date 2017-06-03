"==============================================================
"    file: go.vim
"   brief: 
" VIM Version: 8.0
"  author: tenfy
"   email: tenfyzhong@qq.com
" created: 2017-05-31 13:37:15
"==============================================================


let s:match_function = [
            \ {'pattern': '\m^exported \w\+ \%(\w\+\.\)\?\(\w\+\) should have comment or be unexported$', 'func': function('golint#fixer#exported_should_have_comment')},
            \ {'pattern': '\m^package comment should not have leading space$', 'func': function('golint#fixer#not_leading_space')},
            \ {'pattern': '\m^package comment should be of the form "\(Package \w\+\) \.\.\."$', 'func': function('golint#fixer#comment_should_be_of_the_form')},
            \ {'pattern': '\m^a blank import should be only in a main or test package, or have a comment justifying it$', 'func': function('golint#fixer#blank_import_add_comment')},
            \ {'pattern': '\m^don''t use an underscore in package name$', 'func': function('golint#fixer#remove_underscore_in_package_name')},
            \ {'pattern': '\m^don''t use ALL_CAPS in Go names; use CamelCase$', 'func': function('golint#fixer#convert_all_caps_to_camelcase')},
            \ {'pattern': '\m^don''t use \%(leading k\|underscores\) in Go names; \%(\w*\) \(\w\+\) should be \(\w\+\)$', 'func': function('golint#fixer#go_name_should_be')},
            \ {'pattern': '\m^comment on exported \w\+ \w\+ should be of the form "\(\w\+\) \.\.\." (with optional leading article)$', 'func': function('golint#fixer#comment_should_be_of_the_form')},
            \ {'pattern': '\m^comment on exported \w\+ \%(\w\+.\)\?\w\+ should be of the form "\(\w\+\) \.\.\."$', 'func': function('golint#fixer#comment_should_be_of_the_form')},
            \ {'pattern': '\m^exported \(\w\+\) \%(\w\+\) should have its own declaration$', 'func': function('golint#fixer#exported_should_have_its_own_declaration')},
            \]

function! s:Fix() "{{{
    let cur_col = line('.')
    " let qflist = getloclist(0)
    let qflist = getqflist()
    for item in qflist
        if item['lnum'] == cur_col && (item['type'] ==# 'W' || item['type'] ==# 'E')
            for mf in s:match_function
                let list = matchlist(item['text'], mf['pattern'])
                if !empty(list)
                    call mf['func'](mf["pattern"], item)
                    return
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
