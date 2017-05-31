"==============================================================
"    file: fixer.vim
"   brief: 
" VIM Version: 8.0
"  author: tenfy
"   email: tenfyzhong@qq.com
" created: 2017-05-31 17:26:31
"==============================================================

" handle warning: export type or method
" 'exported type xxx should have comment or be unexported'
" 'exported method xxx.xxx should have comment or be unexported'
function! golint#fixer#exported(pattern, item) "{{{ 
    let list = matchlist(a:item['text'], a:pattern)
    if !empty(list)
        let lnum = a:item['lnum']
        let identifier = list[1]
        let tabs = indent(lnum) / &tabstop
        let content = repeat("\t", tabs)
        let content .= '// ' . identifier 
        call append(lnum-1, content)
        call cursor(lnum, 0)
        startinsert!
        return 1
    endif
    return 0
endfunction "}}}

" handle warning: package comment should not have leading space
function! golint#fixer#not_leading_space(pattern, item) "{{{
    let lnum = a:item['lnum']
    let content = getline(lnum)
    s/\m\s*Package/Package/
    return 1
endfunction "}}}

