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

" handle warning: package comment should be of the form "Package ..."
function! golint#fixer#package_comment_should_be_of_the_form(pattern, item) "{{{
    let lnum = a:item['lnum']
    let content = getline(lnum)
    let list = matchlist(a:item['text'], a:pattern)
    if match(content, '\m\c^\s*\/[/*]\s*package ' . list[1] . '\s*\%(\*\/\)\?\s*') != -1
        " match //Package package_name
        " match /*Package package_name
        " match /*Package package_name*/
        exec 's/\m\c\s*package\s\+'.list[1].'\s*/Package '.list[1].' '
    elseif match(content, '\m\c^\s*\/[/*]\s*package\s*\%(\*\/\)\?\s*$') != -1
        " match //Package
        " match /*Package
        " match /*Package*/
        exec 's/\m\cpackage\s*/Package ' . list[1] . ' '
    elseif match(content, '\m\c^\s*\/[/*]\s*'.list[1].'\s*\%(\*\/\)\?\s*') != -1
        " match //package_name
        " match /*package_name
        " match /*package_name*/
        exec 's/\m\c\('.list[1].'\)\s*/Package '.list[1].' '
    else " match no prefix `Package` of `package_name`
        exec 's/\m\(\/[/*]\)\s*/\1Package '.list[1].' '
    endif
    call cursor(lnum, 1)
    call search(list[1].' ', 'e')
    startinsert
    return 1
endfunction "}}}

" handle warning: a blank import should be only in a main or test package, or have a comment justifying it
function! golint#fixer#blank_import_add_comment(pattern, item) "{{{
    s/\s*$/ \/\/ /
    startinsert!
    return 1
endfunction "}}}
