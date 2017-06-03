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
        let content .= '// ' . identifier 
        call append(lnum-1, content)
        call cursor(lnum, 1)
        startinsert!
    endif
endfunction "}}}

" handle warning: package comment should not have leading space
function! golint#fixer#not_leading_space(pattern, item) "{{{
    let lnum = a:item['lnum']
    let content = getline(lnum)
    s/\m\s*Package/Package/
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
endfunction "}}}

" handle warning: a blank import should be only in a main or test package, or have a comment justifying it
function! golint#fixer#blank_import_add_comment(pattern, item) "{{{
    s/\s*$/ \/\//
    startinsert!
endfunction "}}}

" handle warning: don't use an underscore in package name
function! golint#fixer#remove_underscore_in_package_name(pattern, item) "{{{
    let lnum = a:item['lnum']
    let content = getline(lnum)
    let list = matchlist(content, '\m\s*package\s\+\(\S\+\)')
    if empty(list)
        return 
    endif

    let package = substitute(list[1], '\s', '', 'g')
    let new_name = substitute(package, '_', '', 'g')
    if empty(new_name) && new_name != package
        return 
    endif

    exec 's/'.package.'/'.new_name.'/'
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
        return 
    endif
    let new_word = <SID>camelcase(under_word)
    if <SID>use_go_rename()
        call cursor(lnum, a:item['col'])
        exec 'GoRename ' . new_word
    else
        exec 's/\m\c'.under_word.'/'.new_word
    endif
endfunction "}}}

" handle warning: 
" don't use leading k in Go names; xxx yyy should be zzz
" don't use underscores in Go names; xxx yyy should be zzz
function! golint#fixer#go_name_should_be(pattern, item) "{{{
    let list = matchlist(a:item['text'], a:pattern)
    if empty(list)
        return 
    endif
    let old_name = list[1]
    let new_name = list[2]
    if <SID>use_go_rename()
        call cursor(a:item['lnum'], a:item['col'])
        exec 'GoRename ' . new_name
    else
        exec 's/\<'.old_name.'\>/'.new_name
    endif
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
endfunction "}}}

" handle warning: Should drop = 0 from declaration of var xxx; it is the zero value
function! golint#fixer#drop_zero_value_from_declaration(pattern, item) "{{{
    s/\s*=\s*\%(0\|""\)//
endfunction "}}}

" handle warning: if block ends with a return statement, so drop this else and outdent its block
function! golint#fixer#drop_else_and_outdent_its_block(pattern, item) "{{{
    let lnum = a:item['lnum']
    let content = getline(lnum)
    let list = matchlist(content, '\melse\s*{\s*\(.*\)')
    let comment = list[1]

    call cursor(lnum, 1)
    call search('{')
    normal %
    let end = line('.') 

    " delete `else {`
    exec lnum.'s/\s*else\s*{.*//'
    " delete }
    exec end.'s/}//'
    exec (lnum+1).','.(end-1).'s/\t\|    //'
    if comment != ''
        let tabs = indent(lnum+1) / &tabstop
        let comment = repeat("\t", tabs) . comment
        call append(lnum, comment)
    endif
endfunction "}}}

" handle warning: context.Context should be the first parameter of a function
function! golint#fixer#context_should_be_the_first_parameter_of_a_function(pattern, item) "{{{
    s/\m\(func.*(\)\(.*\),\s*\(\w\+\s\+context.Context\)\(.*\)/\1\3, \2\4/
endfunction "}}}

" handle warning: error should be the last type when returning multiple items
" swap parameter position
" swap return position
function! golint#fixer#error_should_be_the_last_type(pattern, item) "{{{
    " get error position
    let content = getline(a:item['lnum'])
    let list = matchlist(content, 'func.*(\(.*\))')

    let types = split(list[1], '\s*,\s*')
    let error_pos = 0
    for type in types
        if type =~# '\<error\>'
            break
        else
            let error_pos += 1
        endif
    endfor

    call cursor(a:item['lnum'], 1)
    call search('{')
    normal %
    let function_last_lnum = line('.')
    call cursor(a:item['lnum'], 1)

    s/\m\(.*(.\{-}\)\(\w*\s*error\),\s*\(.*\)\().*\)/\1\3, \2\4/
    s/\m\s*,\s*/, /g
    s/\m(\s*/(/
    s/\m\s*)/)/

    let lnum = a:item['lnum']
    while lnum < function_last_lnum
        call cursor(lnum, 1)
        let match = search('return\s*\S*,\s*\S*', '', function_last_lnum)
        if match == 0
            " no match
            break
        endif
        let match_content = getline(match)
        let match_content = substitute(match_content, 'return\s\+\(.*\)\%(\/[/*].*\)\?', '\1', '')
        " BUG added by tenfyzhong 2017-06-03 22:50 match_content has a \t prefix
        let match_content = substitute(match_content, '\s\+', ' ', 'g')
        let return_values = split(match_content, '\s*,\s*')
        let error_value = return_values[error_pos]
        call remove(return_values, error_pos)
        call add(return_values, error_value)
        let new_return_value = join(return_values, ', ')
        let new_return_value = substitute(new_return_value, '\s\+', ' ', 'g')
        let new_return_value = substitute(new_return_value, '^\s*', '', 'g')
        let new_return_value = substitute(new_return_value, '\s*$', '', 'g')
        exec 's/\mreturn\s*\zs.*\ze\%(\/[/*].*\)\?/'.new_return_value
        let lnum = line('.') + 1
    endwhile
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

