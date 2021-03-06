"==============================================================
"    file: go.vim
"   brief: 
" VIM Version: 8.0
"  author: tenfy
"   email: tenfyzhong@qq.com
" created: 2017-05-31 13:37:15
"==============================================================


let s:match_function = [
            \ {'pattern': '\m^exported \w\+ \%(\w\+\.\)\?\(\w\+\) should have comment \%((or a comment on this block) \)\?or be unexported$', 'func': function('golint#fixer#exported_should_have_comment')},
            \ {'pattern': '\m^package comment should not have leading space$', 'func': function('golint#fixer#not_leading_space')},
            \ {'pattern': '\m^package comment should be of the form "\(Package \w\+\) \.\.\."$', 'func': function('golint#fixer#comment_should_be_of_the_form')},
            \ {'pattern': '\m^a blank import should be only in a main or test package, or have a comment justifying it$', 'func': function('golint#fixer#blank_import_add_comment')},
            \ {'pattern': '\m^don''t use an underscore in package name$', 'func': function('golint#fixer#remove_underscore_in_package_name')},
            \ {'pattern': '\m^don''t use ALL_CAPS in Go names; use CamelCase$', 'func': function('golint#fixer#convert_all_caps_to_camelcase')},
            \ {'pattern': '\m^\%(don''t use \%(leading k\|underscores\) in Go names; \)\?.* \(\w\+\) should be \(\w\+\)$', 'func': function('golint#fixer#go_name_should_be')},
            \ {'pattern': '\m^comment on exported \w\+ \w\+ should be of the form "\(\w\+\) \.\.\." (with optional leading article)$', 'func': function('golint#fixer#comment_should_be_of_the_form')},
            \ {'pattern': '\m^comment on exported \w\+ \%(\w\+.\)\?\w\+ should be of the form "\(\w\+\) \.\.\."$', 'func': function('golint#fixer#comment_should_be_of_the_form')},
            \ {'pattern': '\m^exported \(\w\+\) \%(\w\+\) should have its own declaration$', 'func': function('golint#fixer#exported_should_have_its_own_declaration')},
            \ {'pattern': '\m^should drop = \(.\+\) from declaration of var .\+; it is the zero value$', 'func': function('golint#fixer#drop_zero_value_from_declaration')},
            \ {'pattern': '^if block ends with a return statement, so drop this else and outdent its block\%( (move short variable declaration to its own line if necessary)\)\?$', 'func': function('golint#fixer#drop_else_and_outdent_its_block')},
            \ {'pattern': '\M^context.Context should be the first parameter of a function$', 'func': function('golint#fixer#context_should_be_the_first_parameter_of_a_function')},
            \ {'pattern': '\M^error should be the last type when returning multiple items$', 'func': function('golint#fixer#error_should_be_the_last_type')},
            \ {'pattern': '\m^should replace \(.*\)(fmt.Sprintf(\.\.\.)) with \(.*\)\.Errorf(\.\.\.)$', 'func': function('golint#fixer#should_replace_sprintf_with_errorf')},
            \ {'pattern': '\m^error var \(.*\) should have name of the form [eE]rrFoo$', 'func': function('golint#fixer#error_var_should_have_name_of_the_form')},
            \ {'pattern': '\m^error strings should not be capitalized or end with punctuation or a newline$', 'func': function('golint#fixer#error_strings_should_not_be_capitalized_or_end_with_punctuation_or_new_line')},
            \ {'pattern': '^should not use dot imports$', 'func': function('golint#fixer#should_not_use_dot_imports')}, 
            \ {'pattern': '\m^should replace \(.*\)\s\+with\s\(.*\)$', 'func': function('golint#fixer#should_replace_xxx_with_yyy')}, 
            \ {'pattern': '^package comment is detached; there should be no blank lines between it and the package statement$', 'func': function('golint#fixer#should_be_no_blank_lines')}, 
            \ {'pattern': '\m^should omit 2nd value from range; this loop is equivalent to `for .\+ :\?= range \.\.\.`$', 'func': function('golint#fixer#omit_2nd_value_from_range')}, 
            \ {'pattern': '^receiver name should be a reflection of its identity; don''t use generic names such as "this" or "self"$', 'func': function('golint#fixer#receive_name_should_not_be_this_or_self')}, 
            \ {'pattern': '\m^receiver name \(.*\) should be consistent with previous receiver name \(.*\) for .*$', 'func': function('golint#fixer#receive_name_should_be_consistent_with_previous_receive_name')}, 
            \ {'pattern': '^receiver name should not be an underscore$', 'func': function('golint#fixer#receive_name_should_not_be_an_underscore')}, 
            \ {'pattern': '^\w* name will be used as .*\.\(.*\) by other packages, and that stutters; consider calling this \(.*\)$', 'func': function('golint#fixer#name_stutters_consider_calling')}, 
            \ {'pattern': '\m^var \(.*\) is of type .*; don''t use unit-specific suffix "\(.*\)"$', 'func': function('golint#fixer#time_dont_use_unit_specific_suffix')}, 
            \ {'pattern': '\m^should omit type \(.\+\) from declaration of var .*; it will be inferred from the right-hand side$', 'func': function('golint#fixer#should_omit_type_from_declaration')}, 
            \ {'pattern': '\m^missing '','' before newline in composite literal$', 'func': function('golint#fixer#miss_comma')}, 
            \]

function! s:process(list) "{{{
    let cur_col = line('.')
    for item in a:list
        if item['lnum'] == cur_col && (item['type'] ==# 'W' || item['type'] ==# 'E')
            for mf in s:match_function
                let matchlist = matchlist(item['text'], mf['pattern'])
                if !empty(matchlist)
                    call mf['func'](mf["pattern"], item, matchlist)
                    return 1
                endif
            endfor
        endif
    endfor
    return 0
endfunction "}}}

function! s:fix() "{{{
    let qflist = getqflist()
    let result = <SID>process(qflist)
    if result == 1
        return
    endif

    let loclist = getloclist(0)
    let result = <SID>process(loclist)
    if result == 1
        return
    endif

    " Process failed. 
    echo 'I don''t know how to process the warning.'
endfunction "}}}

if get(g:, 'golint_fixer_use_default_mapping', 1)
    nnoremap <buffer><leader>rl :GoLintFix<cr>
endif

command! -nargs=0 GoLintFix call <SID>fix()
