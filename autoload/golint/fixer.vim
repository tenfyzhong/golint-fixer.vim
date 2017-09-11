"==============================================================
"    file: fixer.vim
"   brief: 
" VIM Version: 8.0
"  author: tenfy
"   email: tenfy@tenfy.cn
" created: 2017-05-31 17:26:31
"==============================================================

" handle warning: export type or method
" 'exported type xxx should have comment or be unexported'
" 'exported method xxx.xxx should have comment or be unexported'
" Exported const Whatsit should have comment (or a comment on this block) or be unexported
function! golint#fixer#exported_should_have_comment(pattern, item, matchlist) "{{{ 
    let lnum = a:item['lnum']
    let identifier = a:matchlist[1]
    let tabs = indent(lnum) / &tabstop
    let content = repeat("\t", tabs)
    let content .= '// ' . identifier . ' '
    call append(lnum-1, content)
    call cursor(lnum, 1)
    startinsert!
endfunction "}}}

" handle warning: package comment should not have leading space
function! golint#fixer#not_leading_space(pattern, item, matchlist) "{{{
    let lnum = a:item['lnum']
    while 1
        let content = getline(lnum)
        if match(content, 'Package') != -1
            break
        endif
        let lnum += 1
    endwhile
    exec lnum . 's/\m\s*Package/Package/'
endfunction "}}}

" handle warning: 
" package comment should be of the form "Package ..."
" comment on exported type xxx should be of the form "xxx ..." (with optional leading article)
" comment on exported xxx yyy should be of the form "yyy ..."
function! golint#fixer#comment_should_be_of_the_form(pattern, item, matchlist) "{{{
    let lnum = a:item['lnum']
    let content = getline(lnum)
    let words = split(a:matchlist[1], ' ')
    if match(content, '\m\c^\s*\/[/*]\s*' . a:matchlist[1] . '\s*\%(\*\/\)\?\s*') != -1
        " match //\s*Package package_name
        " match /*\s*Package package_name
        " match /*\s*Package package_name*/
        exec 's/\m\c\s*'.a:matchlist[1].'\s*/ '.a:matchlist[1].' '
    elseif len(words) == 2 && match(content, '\m\c^\s*\/[/*]\s*'.words[0].'\s*\%(\*\/\)\?\s*$') != -1
        " match //\s*Package
        " match /*\s*Package
        " match /*\s*Package*/
        exec 's/\m\c\s*'.words[0].'\s*/ '.a:matchlist[1].' '
    elseif len(words) == 2 && match(content, '\m\c^\s*\/[/*]\s*'.words[1].'\s*\%(\*\/\)\?\s*') != -1
        " match // package_name
        " match /* package_name
        " match /* package_name*/
        exec 's/\m\c\s*'.words[1].'\s*/ '.a:matchlist[1].' '
    else " match no prefix `Package` or `package_name`
        exec 's/\m\(\/[/*]\)\s*/\1 '.a:matchlist[1].' '
    endif
    call cursor(lnum, 1)
    call search(a:matchlist[1].' ', 'e')
    startinsert
endfunction "}}}

" handle warning: a blank import should be only in a main or test package, or have a comment justifying it
function! golint#fixer#blank_import_add_comment(pattern, item, matchlist) "{{{
    s/\s*$/ \/\//
    startinsert!
endfunction "}}}

" handle warning: don't use an underscore in package name
function! golint#fixer#remove_underscore_in_package_name(pattern, item, matchlist) "{{{
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
function! golint#fixer#convert_all_caps_to_camelcase(pattern, item, matchlist) "{{{
    let lnum = a:item['lnum']
    let content = getline(lnum)
    let words = split(content, '\s\+')
    let under_word = ''
    for word in words
        if word =~# '_'
            let under_word = word
            break
        endif
    endfor
    if empty(under_word)
        return 
    endif
    let new_word = <SID>camelcase(under_word)
    call <SID>rename(lnum, a:item['col'], under_word, new_word)
endfunction "}}}

" handle warning: 
" don't use leading k in Go names; xxx yyy should be zzz
" don't use underscores in Go names; xxx yyy should be zzz
function! golint#fixer#go_name_should_be(pattern, item, matchlist) "{{{
    if empty(a:matchlist)
        return 
    endif
    let old_name = a:matchlist[1]
    let new_name = a:matchlist[2]
    let lnum = a:item['lnum']
    let col = a:item['lnum']
    call <SID>rename(lnum, col, old_name, new_name)
endfunction "}}}

" handle warning: exported xxx xxx should have its own declaration
function! golint#fixer#exported_should_have_its_own_declaration(pattern, item, matchlist) "{{{
    let keyword = a:matchlist[1]
    let lnum = a:item['lnum']
    let content = getline(lnum)

    let has_keyword = match(content, '\m\<'.keyword.'\>') != -1
    let tabs = indent(lnum) / &tabstop
    let leading_space = repeat("\t", tabs)

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
        let new_content = leading_space
        if has_keyword 
            let new_content .= keyword . ' ' . names[i]
        else
            let new_content .= names[i]
        endif
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
    s/^\s*//
    exec 's/^/'.leading_space
endfunction "}}}

" handle warning: Should drop = 0 from declaration of var xxx; it is the zero value
function! golint#fixer#drop_zero_value_from_declaration(pattern, item, matchlist) "{{{
    " s/\s*=\s*\%(0\|""\)//
    let drop = a:matchlist[1]
    let drop = substitute(drop, '\\', '\\\\', 'g')
    exec 's/\s*=\s*\(\/\*.*\*\/\)\?\s*'.drop.'/\1'
endfunction "}}}

" handle warning: 
" if block ends with a return statement, so drop this else and outdent its block
" if block ends with a return statement, so drop this else and outdent its block (move short variable declaration to its own line if necessary)
function! golint#fixer#drop_else_and_outdent_its_block(pattern, item, matchlist) "{{{
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
function! golint#fixer#context_should_be_the_first_parameter_of_a_function(pattern, item, matchlist) "{{{
    s/\m\(func.*(\)\(.*\),\s*\(\w\+\s\+context.Context\)\(.*\)/\1\3, \2\4/
endfunction "}}}

" handle warning: error should be the last type when returning multiple items
" swap parameter position
" swap return position
function! golint#fixer#error_should_be_the_last_type(pattern, item, matchlist) "{{{
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

" handle warning: should replace %s(fmt.Sprintf(...)) with %s.Errorf(...)
" should replace errors.New(fmt.Sprintf(...)) with fmt.Errorf(...)
" should replace t.Error(fmt.Sprintf(...)) with t.Errorf(...)
function! golint#fixer#should_replace_sprintf_with_errorf(pattern, item, matchlist) "{{{
    exec 's/\m'.a:matchlist[1].'(fmt\.Sprintf(\(.*\)))/'.a:matchlist[2].'.Errorf(\1)'
endfunction "}}}

" handle warning: error var xxx should have name of the form errFoo
function! golint#fixer#error_var_should_have_name_of_the_form(pattern, item, matchlist) "{{{
    let old_name = a:matchlist[1]
    let prefix = old_name =~# '^\u' ? 'Err' : 'err'
    let new_name = substitute(old_name, '.*', prefix.'\u&', '')
    let lnum = a:item['lnum']
    let col = a:item['col']
    call <sid>rename(lnum, col, old_name, new_name)
endfunction "}}}

" hanle warning: error strings should not be capitalized or end with punctuation or a newline
function! golint#fixer#error_strings_should_not_be_capitalized_or_end_with_punctuation_or_new_line(pattern, item, matchlist) "{{{
    s/\m\%(\\n\|\.\)\(["`]\)/\1
endfunction "}}}

" handle warning: should not use dot imports
function! golint#fixer#should_not_use_dot_imports(pattern, item, matchlist) "{{{
    s/\mimport\s\+\.\s\+/import /
endfunction "}}}

" handle warning: should replace %s with %s%s
" should replace x += 1 with x++
" Should replace y -= 1 with y--
function! golint#fixer#should_replace_xxx_with_yyy(pattern, item, matchlist) "{{{
    let xxx = a:matchlist[1]
    let yyy = a:matchlist[2]
    let xxx = substitute(xxx, ' ', '\\s*\\%(\\/\\*.*\\*\\/\\)\\?\\s*', 'g') " submatch space to space/inline_comment/space
    exec 's/\m'.xxx.'/'.yyy
endfunction "}}}

" handle warning: package comment is detached; there should be no blank lines between it and the package statement
function! golint#fixer#should_be_no_blank_lines(pattern, item, matchlist) "{{{
    let lnum = a:item['lnum']
    while getline(lnum) =~# '^\s*$'
        exec lnum . 'd'
    endwhile
endfunction  "}}}

" handle warning: should omit 2nd value from range; this loop is equivalent to `for xxx = range ...`
function! golint#fixer#omit_2nd_value_from_range(pattern, item, matchlist) "{{{
    s/,\s*\%(\/\*.*\*\/\)\?\s*_\s*\%(\/\*.*\*\/\)\?\s*/ /
endfunction "}}}"

" handle waring: 
" receiver name should be a reflection of its identity; don't use generic names such as "this" or "self"
function! golint#fixer#receive_name_should_not_be_this_or_self(pattern, item, matchlist) "{{{
    let lnum = a:item['lnum']
    let content = getline(lnum)
    " func /*.*/ ( /*.*/ this *bar )()
    let list = matchlist(content, '\mfunc\s*\%(\/\*.*\*\/\)\?\s*(\s*\%(\/\*.*\*\/\)\?\s*\(\<this\>\|\<self\>\)\s*\%(\/\*.*\*\/\)\?\s*\*\?\s*\%(\/\*.*\*\/\)\?\s*\(\w\)\w*)')
    let generic_name = list[1]
    let new_name = list[2]
    call search('{')
    normal %
    let function_last_lnum = line('.')
    call <SID>scope_rename(generic_name, new_name, lnum, function_last_lnum)
endfunction "}}}

" handle warning: receiver name %s should be consistent with previous receiver name %s for %s
" pattern: '\m^receiver name \(.*\) should be consistent with previous receiver name \(.*\) for .*$'
function! golint#fixer#receive_name_should_be_consistent_with_previous_receive_name(pattern, item, matchlist) "{{{
    let old_name = a:matchlist[1]
    let new_name = a:matchlist[2]
    exec 's/\m\<'.old_name.'\>/'.new_name.'/g'
endfunction "}}}

" handle warning: receiver name should not be an underscore
function! golint#fixer#receive_name_should_not_be_an_underscore(pattern, item, matchlist) "{{{
    " func /*.*/ ( /*.*/ _ *bar )()
    s/\m\(func\s*\%(\/\*.*\*\/\)\?\s*(\s*\%(\/\*.*\*\/\)\?\s*\)_\(\s*\%(\/\*.*\*\/\)\?\s*\*\?\s*\%(\/\*.*\*\/\)\?\s*\(\w\)\w*)\)/\1\3\2/
endfunction "}}}

" handle warning: type/func name will be used as xxx.yyy by other packages, and that stutters; consider calling this zzz
function! golint#fixer#name_stutters_consider_calling(pattern, item, matchlist) "{{{
    let old_name = a:matchlist[1]
    let new_name = a:matchlist[2]
    call <SID>rename(a:item['lnum'], a:item['col'], old_name, new_name)
endfunction "}}}

" handle warning: var %s is of type %v; don't use unit-specific suffix %q
function! golint#fixer#time_dont_use_unit_specific_suffix(pattern, item, matchlist) "{{{
    let old_name = a:matchlist[1]
    let suffix = a:matchlist[2]
    let new_name = substitute(old_name, '\(.*\)'.suffix, '\1', '')
    call <SID>rename(a:item['lnum'], a:item['col'], old_name, new_name)
endfunction "}}}

" handle warning: should omit type %s from declaration of var %s; it will be inferred from the right-hand side
function! golint#fixer#should_omit_type_from_declaration(pattern, item, matchlist) "{{{
    let type = a:matchlist[1]
    let type = substitute(type, '[*.]', '\\&', 'g')
    exec 's/\m'.type.'\s*//'
endfunction "}}}

function! s:scope_rename(old_name, new_name, begin_lnum, end_lnum) "{{{
    let lnum = a:begin_lnum
    while lnum < a:end_lnum
        call cursor(lnum, 1)
        let f = search('\m\<'.a:old_name.'\>', '', a:end_lnum)
        if f == 0
            break
        endif
        exec 's/\m\<'.a:old_name.'\>/'.a:new_name.'/g'
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

function! s:rename(lnum, col, old_name, new_name) "{{{
    if <SID>use_go_rename()
        call cursor(a:lnum, a:col)
        exec 'GoRename ' . a:new_name
    endif
    if getline(a:lnum) =~# '\<'.a:old_name.'\>'
        exec 's/\m\<'.a:old_name.'\>/'.a:new_name.'/g'
        return 0
    endif
    return 1
endfunction "}}}

