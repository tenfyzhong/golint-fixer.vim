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
function! golint#fixer#exported_should_have_comment(pattern, item) "{{{ 
    let list = matchlist(a:item['text'], a:pattern)
    if !empty(list)
        let lnum = a:item['lnum']
        let identifier = list[1]
        let tabs = indent(lnum) / &tabstop
        let content = repeat("\t", tabs)
        let content .= '//' . identifier 
        call append(lnum-1, content)
        call cursor(lnum, 1)
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

" handle warning: 
" package comment should be of the form "Package ..."
" comment on exported type xxx should be of the form "xxx ..." (with optional leading article)
" comment on exported xxx yyy should be of the form "yyy ..."
function! golint#fixer#comment_should_be_of_the_form(pattern, item) "{{{
    let lnum = a:item['lnum']
    let content = getline(lnum)
    let list = matchlist(a:item['text'], a:pattern)
    let words = split(list[1], ' ')
    if match(content, '\m\c^\s*\/[/*]\s*' . list[1] . '\s*\%(\*\/\)\?\s*') != -1
        " match //Package package_name
        " match /*Package package_name
        " match /*Package package_name*/
        exec 's/\m\c\s*'.list[1].'\s*/'.list[1].' '
    elseif len(words) == 2 && match(content, '\m\c^\s*\/[/*]\s*'.words[0].'\s*\%(\*\/\)\?\s*$') != -1
        " match //Package
        " match /*Package
        " match /*Package*/
        exec 's/\m\c'.words[0].'\s*/'.list[1].' '
    elseif len(words) == 2 && match(content, '\m\c^\s*\/[/*]\s*'.words[1].'\s*\%(\*\/\)\?\s*') != -1
        " match //package_name
        " match /*package_name
        " match /*package_name*/
        exec 's/\m\c'.words[1].'\s*/'.list[1].' '
    else " match no prefix `Package` of `package_name`
        exec 's/\m\(\/[/*]\)\s*/\1'.list[1].' '
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

" handle warning: don't use an underscore in package name
function! golint#fixer#remove_underscore_in_package_name(pattern, item) "{{{
    let lnum = a:item['lnum']
    let content = getline(lnum)
    let list = matchlist(content, '\m\s*package\s\+\(\S\+\)')
    if empty(list)
        return 0
    endif

    let package = substitute(list[1], '\s', '', 'g')
    let new_name = substitute(package, '_', '', 'g')
    if empty(new_name) && new_name != package
        return 0
    endif

    exec 's/'.package.'/'.new_name.'/'
    return 1
endfunction "}}}

" handle warning: don't use ALL_CAPS in Go names; use CamelCase
function! golint#fixer#convert_all_caps_to_camelcase(pattern, item) "{{{
    let lnum = a:item['lnum']
    let content = getline(lnum)
    let content = substitute(content, '\s\+', ' ', 'g') " convert tab to space
    let words = split(content, ' ')
    let under_word = ''
    for word in words
        if word =~# '_'
            let under_word = word
        endif
    endfor
    if empty(under_word)
        return 0
    endif
    let new_word = <SID>camelcase(under_word)
    if <SID>use_go_rename()
        call cursor(lnum, a:item['col'])
        exec 'GoRename ' . new_word
    else
        exec 's/\m\c'.under_word.'/'.new_word
    endif
    return 1
endfunction "}}}

" handle warning: 
" don't use leading k in Go names; xxx yyy should be zzz
" don't use underscores in Go names; xxx yyy should be zzz
function! golint#fixer#go_name_should_be(pattern, item) "{{{
    let list = matchlist(a:item['text'], a:pattern)
    if empty(list)
        return 0
    endif
    let old_name = list[1]
    let new_name = list[2]
    if <SID>use_go_rename()
        call cursor(a:item['lnum'], a:item['col'])
        exec 'GoRename ' . new_name
    else
        exec 's/\<'.old_name.'\>/'.new_name
    endif
    return 1
endfunction "}}}

" handle warning: exported xxx xxx should have its own declaration
function! golint#fixer#exported_should_have_its_own_declaration(pattern, item) "{{{
    let list = matchlist(a:item['text'], a:pattern)
    let keyword = list[1]
    let lnum = a:item['lnum']
    let content = getline(lnum)

    let content = substitute(content, '\%(\/[/*].*\)\?$', '', '')   " remove comment
    let content = substitute(content, keyword, '', '')  " remove var/const keywrod
    let content = substitute(content, '\s\+', ' ', 'g')  " substitute more then one space to one
    let content = substitute(content, '^\s*\(.*\S\)\s*$', '\1', '') " trim space

    let name_value = split(content, '\s*=\s*')
    let names = split(name_value[0], '\s*,\s*')[1:]
    let last_name_and_type = split(names[-1], '\s\+')
    let type = ''
    if len(last_name_and_type) > 1 
        let names[-1] = last_name_and_type[0]
        let type = last_name_and_type[1]
    endif

    let values = []
    if len(name_value) == 2
        let values = split(name_value[1], '\s*,\s*')[1:]
    endif 

    " delete name and value
    for name in names 
        exec 's/,\s*'.name.'//'
    endfor
    for value in values
        exec 's/,\s*'.value.'//'
    endfor

    let i = 0
    let append_list = []
    while i < len(names)
        let new_content = keyword . ' ' . names[i] 
        if type != ''
            " has type
            let new_content .= ' ' . type
        endif
        if len(values) > 0
            " has value
            let new_content .= ' = ' . values[i]
        endif
        call insert(append_list, new_content)
        let i += 1
    endwhile
    call append(lnum-1, append_list)
    call cursor(lnum+len(names), 1)
    s/\m\s\+/ /g
    return 1
endfunction "}}}

function! s:camelcase(word) "{{{ under_word to camelcase
    let new_word = substitute(a:word,'\C\(_\)\=\(.\)','\=submatch(1)==""?tolower(submatch(2)) : toupper(submatch(2))','g')
    let new_word = substitute(new_word, '\m_\+$', '', 'g')
    if a:word =~# '^_' || a:word =~# '^\l'
        let new_word = substitute(new_word, '^.', '\l&', '')
    elseif a:word =~# '^\u'
        let new_word = substitute(new_word, '^.', '\u&', '')
    endif
    return new_word
endfunction "}}}

function! s:use_go_rename() "{{{
    return get(g:, 'golint_fixer_use_go_rename', 1) && exists(':GoRename')
endfunction "}}}

