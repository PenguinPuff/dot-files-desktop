set nocompatible
filetype on
filetype off

let $VIMRCDIR = fnamemodify($MYVIMRC, ':p:h')

let s:platform = {
\   'osx': has('macunix'),
\   'linux': has('unix') && !has('macunix') && !has('win32unix'),
\   'windows': has('win32') || has('win64'),
\}

function! JoinPath(...) abort
    return join(a:000, s:platform['windows'] ? '\' : '/')
endfunction

function! LogMsg(fmt, ...) abort
    let stack = reverse(
    \   map(
    \       split(substitute(expand('<sfile>'), '^function ', '', ''), '\.\.'),
    \       'substitute(v:val, ''\m\[\d\+\]$'', "", "")'
    \   )[:-1]
    \)

    echom call('printf', [ '[%s] ' .. a:fmt, stack[len(stack) > 1] ] + a:000)
endfunction

" =======================================================

let s:vimbundle_dir = JoinPath($VIMRCDIR, '.vimbundle')
let s:bundles = []

" Dark colorscheme
call add(s:bundles, { 'repo': 'https://github.com/rose-pine/vim' })

" Keyboard layout switcher
call add(s:bundles, { 'repo': 'https://github.com/lyokha/vim-xkbswitch' })

" Extended syntax highlighting
call add(s:bundles, { 'repo': 'https://github.com/sheerun/vim-polyglot' })

" Customizable status line
call add(s:bundles, { 'repo': 'https://github.com/itchyny/lightline.vim' })

" Append git blame information to the output of <C-g>
call add(s:bundles, { 'repo': 'https://github.com/limitedeternity/CTRLGGitBlame.vim' })

" Highlight jump targets (f, F, t, T)
call add(s:bundles, { 'repo': 'https://github.com/unblevable/quick-scope' })

" Enable repeat action for plugins (.)
call add(s:bundles, { 'repo': 'https://github.com/tpope/vim-repeat' })

" Extended 'goto matching text' (%)
call add(s:bundles, { 'repo': 'https://github.com/andymass/vim-matchup' })

" Mappings to work with comments
" -----------------------------------------
" | v-line + gc.                          |
" |                                       |
" | test1   ===>   // test1   ===>  test1 |
" | test2          // test2         test2 |
" -----------------------------------------
call add(s:bundles, { 'repo': 'https://github.com/tpope/vim-commentary' })

" Mappings to work with surroundings
" -------------------------------------
" | v-line + :'<,'>norm A, + gvS[gvJX |
" |                                   |
" | test1   ===>   [ test1, test2 ]   |
" | test2                             |
" |-----------------------------------|
" | insert + <C-g>s(                  |
" |                                   |
" | |   ===>   ( | )                  |
" -------------------------------------
call add(s:bundles, { 'repo': 'https://github.com/tpope/vim-surround' })

" Emacs-like narrowing feature
" ------------------------------------------
" | v-line + :'<,'>FocusStart + :FocusStop |
" ------------------------------------------
call add(s:bundles, { 'repo': 'https://github.com/limitedeternity/vim-focus' })

" Linting + LSP completion (<Tab>) + Formatting
call add(s:bundles, { 'repo': 'https://github.com/dense-analysis/ale' })

" AI completion (<S-Tab>)
call add(s:bundles, { 'repo': 'https://github.com/Exafunction/codeium.vim' })

" Filetype-specific snippet engine (<Space>)
call add(s:bundles, { 'repo': 'https://github.com/brennier/quicktex' })

" File navigator (<F4>)
call add(s:bundles, { 'repo': 'https://github.com/scrooloose/nerdtree' })

" Undo history graph (<F5>)
call add(s:bundles, { 'repo': 'https://github.com/mbbill/undotree' })

" Distraction-free display (<F6>)
call add(s:bundles, { 'repo': 'https://github.com/junegunn/goyo.vim' })

" Fuzzy finder (<F7>)
call add(s:bundles, { 'repo': 'https://github.com/junegunn/fzf', 'do': 'FzfPost' })

function! FzfPost() abort
    call fzf#install()
    call feedkeys(':', 'nx')
    redraw!
endfunction

" Basic commands for fzf
call add(s:bundles, { 'repo': 'https://github.com/junegunn/fzf.vim' })

" Session manager based on fzf (<S-F12>)
call add(s:bundles, { 'repo': 'https://github.com/limitedeternity/fzf-session.vim' })

function! LoadBundles() abort
    let rtp_prepend = []
    let rtp_append = []

    for bundle in s:bundles
        let name = split(bundle['repo'], '/')[-1]
        let path = JoinPath(s:vimbundle_dir, name)

        if !isdirectory(path)
            echo printf('[*] %s', name)
            let output = system(printf('git clone %s %s', shellescape(bundle['repo']), shellescape(path)))

            if v:shell_error != 0
                echohl ErrorMsg | echo output | echohl None
                continue
            endif

            let bundle['postflag'] = 1
            echo printf('[+] %s', name)
        endif

        call add(rtp_prepend, fnameescape(path))

        let after_dir = JoinPath(path, 'after')

        if isdirectory(after_dir)
            call add(rtp_append, fnameescape(after_dir))
        endif

        let doc_dir = JoinPath(path, 'doc')

        if isdirectory(doc_dir)
            execute printf('helptags %s', fnameescape(doc_dir))
        endif
    endfor

    execute printf('set rtp^=%s', join(rtp_prepend, ','))
    execute printf('set rtp+=%s', join(rtp_append, ','))
endfunction

function! PostLoadBundles(...) abort
    for bundle in s:bundles
        if get(bundle, 'postflag', 0) == 1
            call call(get(bundle, 'do', { -> 0 }), [])
            call remove(bundle, 'postflag')
        endif
    endfor
endfunction

function! UpdateBundles() abort
    for bundle in s:bundles
        let name = split(bundle['repo'], '/')[-1]
        let path = JoinPath(s:vimbundle_dir, name)

        if !isdirectory(path)
            continue
        endif

        echo printf('[*] %s', name)
        let output = system(printf('git -C %s fetch', shellescape(path)))

        if v:shell_error != 0
            echohl ErrorMsg | echo output | echohl None
            continue
        endif

        let output = system(printf('git -C %s rev-list HEAD...origin --count --first-parent', shellescape(path)))

        if v:shell_error != 0
            echohl ErrorMsg | echo output | echohl None
            continue
        endif

        if str2nr(output) == 0
            echo printf('[.] %s', name)
            continue
        endif

        let output = system(printf('git -C %s ff', shellescape(path)))

        if v:shell_error != 0
            echohl ErrorMsg | echo output | echohl None
            continue
        endif

        call call(get(bundle, 'do', { -> 0 }), [])
        echo printf('[+] %s', name)
    endfor
endfunction

call LoadBundles()
autocmd VimEnter * call timer_start(0, 'PostLoadBundles')
command! -nargs=0 UpdateBundles call UpdateBundles()

" -- gruvbox-material config
let g:gruvbox_material_background = 'hard'
let g:gruvbox_material_better_performance = 1
let g:gruvbox_material_disable_italic_comment = 1

" -- vim-xkbswitch config
let g:XkbSwitchEnabled = 1
let g:XkbSwitchNLayout = 'us'
let g:XkbSwitchIMappings = ['ru']

" -- lightline config
let g:lightline = {
\   'colorscheme': 'gruvbox_material',
\   'active': {
\     'left': [
\       ['mode', 'paste'],
\       ['readonly', 'filename', 'modified'],
\     ],
\     'right': [
\       ['lineinfo'],
\       ['fileformat', 'fileencoding'],
\     ]
\   },
\   'inactive': {
\     'left': [ ['readonly', 'filename', 'modified'] ],
\     'right': [ ['lineinfo'] ],
\   },
\   'component_function': {
\     'lineinfo': 'LightlineLineInfo',
\     'readonly': 'LightlineReadOnly',
\     'modified': 'LightlineModified',
\   },
\}

let s:lightline_disable_for = [ '^help$', '^nerdtree$', '^undotree$' ]

function! LightlineLineInfo() abort
    let enabled = &ft !~# printf('\v(%s)', join(s:lightline_disable_for, '|'))
    return enabled && winwidth(0) >= 86 ? printf('%04s:%03s', line('.'), col('.')) : ''
endfunction

function! LightlineReadOnly() abort
    let enabled = &ft !~# printf('\v(%s)', join(s:lightline_disable_for, '|'))
    return enabled && &readonly ? 'RO' : ''
endfunction

function! LightlineModified() abort
    let enabled = &ft !~# printf('\v(%s)', join(s:lightline_disable_for, '|'))
    return enabled && &modified ? '+' : ''
endfunction

" -- quick-scope config
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

" -- matchup config
let g:matchup_text_obj_enabled = 0
let g:matchup_surround_enabled = 0

" -- ale config
augroup ale_linters
    autocmd!
    autocmd BufNew,BufReadPre * if !exists('b:ale_linters') | let b:ale_linters = 'all' | endif
augroup end

let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'python': ['add_blank_lines_for_python_control_statements', 'black'],
\}

let g:ale_rust_rls_config = {
\   'rust': {
\     'clippy_preference': 'on'
\   }
\}

let g:ale_use_neovim_diagnostics_api = has('nvim-0.6')
let g:ale_completion_enabled = 0
let g:ale_lsp_suggestions = 1
let g:ale_fix_on_save = 1

let g:ale_echo_cursor = 0
let g:ale_set_highlights = 0
let g:ale_sign_error = 'E'
let g:ale_sign_warning = 'W'
let g:ale_sign_info = 'I'

" -- codeium config
let g:codeium_disable_bindings = 1
let g:codeium_manual = 1

" -- quicktex config
" -----------------------
" | + tectonic -X watch |
" | + Open in Sumatra   |
" -----------------------
let g:quicktex_always_latex = 1
let g:quicktex_usedefault = 0

let g:quicktex_tex = {
\  '!m' : '\( <+++> \) <++>',
\  '!env': "\<Esc>Bvedi\\begin{\<Esc>pa}\<CR><+++>\<CR>\\end{\<Esc>pa}"
\}

let g:quicktex_math = {
\  '\frac': '\frac{<+++>}{<++>} <++>'
\}

" -- nerdtree config
let g:NERDTreeIgnore = [ '^\.DS_Store$', '^\.git$', '^node_modules$' ]
let g:NERDTreeShowHidden = 1

" -- undotree config
let g:undotree_DiffCommand = 'git --no-pager diff --histogram --no-index --'
let g:undotree_WindowLayout = 2
let g:undotree_SetFocusWhenToggle = 1

" -- goyo.vim config
let g:goyo_margin_top = 2
let g:goyo_margin_bottom = 2

" -- fzf config
let g:fzf_colors = {
\  'fg':      ['fg', 'Normal'],
\  'bg':      ['bg', 'Normal'],
\  'hl':      ['fg', 'Comment'],
\  'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
\  'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
\  'hl+':     ['fg', 'Statement'],
\  'info':    ['fg', 'PreProc'],
\  'border':  ['fg', 'Ignore'],
\  'prompt':  ['fg', 'Conditional'],
\  'pointer': ['fg', 'Exception'],
\  'marker':  ['fg', 'Keyword'],
\  'spinner': ['fg', 'Label'],
\  'header':  ['fg', 'Comment']
\}

let g:fzf_action = {
\  'enter': 'split'
\}

let g:fzf_buffers_jump = 1

" -- fzf-session config
let g:session#session_dir = JoinPath($VIMRCDIR, '.vimsession')

syntax on
filetype plugin indent on

" -- general
set encoding=utf-8 nobomb

if s:platform['windows']
    set fileformats=dos,unix,mac
else
    set fileformats=unix,dos,mac
endif

" -- spell check
set nospell
set spelllang=ru_yo,en_us
set spellsuggest=best,5
set spelloptions=camel

" -- performance
set complete-=i          " prevent usage of included files by ins-completion-menu
set hidden               " background buffer
set lazyredraw           " don't update the display while executing macros
set nofsync              " save battery by letting OS flush to disk
set ttyfast              " send more characters
set updatetime=300       " 300ms (default is 4000ms)

" -- behavior
set backspace=indent,eol,start   " allow backspacing over everything
set formatoptions+=j             " delete comment characters when joining lines
set nomodeline                   " don't use modeline (security)
set virtualedit=block            " fix visual block mode

if !s:platform['windows']
    set shell=bash               " prevent fish from breaking everything
endif

" -- session
set autoread                     " reload on external change
set sessionoptions-=options
set viewoptions-=options

" -- backup / swp
set nobackup
set nowritebackup
set noswapfile

set history=50
set viminfo=!,%,f0,h,<800,'20,/50,:50
          " | | |  | |    |   |   |
          " | | |  | |    |   |   + Remember last 50 commands
          " | | |  | |    |   + Remember last 50 search patterns
          " | | |  | |    + Remember marks for last 20 files (default: 100)
          " | | |  | + Remember up to 800 lines in each register (default: 50)
          " | | |  + Disable hlsearch while loading viminfo
          " | | + Forget [0-9A-Z] file marks
          " | + Remember buffer list
          " + Remember g:UPPERCASE variables

let s:viminfo_file = JoinPath($VIMRCDIR, '.viminfo')
execute printf('set viminfo+=n%s', escape(s:viminfo_file, ' \'))

if has("persistent_undo")
    let s:vimundo_dir = JoinPath($VIMRCDIR, '.vimundo')

    if !isdirectory(s:vimundo_dir)
        call mkdir(s:vimundo_dir, 'p', 0700)
    endif

    execute printf('set undodir=%s', fnameescape(s:vimundo_dir))
    set undofile
endif

" -- search / regexp
set ignorecase smartcase " case-insensitive search unless there are upper-case letters
set gdefault             " regex global by default
set magic                " extended regex
set incsearch            " incremental search (while typing)
set wrapscan             " wraparound search
set hlsearch             " highlight matches

" -- user interface
let $LANG = 'en_US'
set langmenu=en_US
set helplang=en

if has('gui_running')
    set guioptions=gad
endif

if !has('nvim')
    set ttymouse=sgr
endif

set mouse=a              " enable mouse in all modes
set belloff=all          " disable bells
set confirm              " use a dialog when an operation has to be confirmed

" use 24-bit colors inside terminals
if has('termguicolors')
    set termguicolors
endif

" enable blinking together with different cursor shapes
set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50
  \,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor
  \,sm:block-blinkwait175-blinkoff150-blinkon175

" highlight the line number of the cursor (with CursorLineNr)
set cursorline
set cursorlineopt=number

" apply colorscheme
set background=dark
silent! colorscheme gruvbox-material

set number                  " absolute line numbers
set laststatus=2            " always show status line
set noruler                 " disable ruler in favor of lightline
set noshowmode              " disable mode display in favor of lightline
set splitbelow splitright   " how to split new windows
set shortmess+=c            " dont pass messages to ins-completion-menu

set showmatch               " show matching parenthesis
set matchtime=3             " make showmatch a bit faster

" -- indent / format
set wrap linebreak          " wrap lines on word boundaries
set breakindent             " make wraps visually indented
set textwidth=120           " wrap width
let &showbreak = '> '       " wrap indicator

set autoindent
set smartindent
set copyindent

set smarttab
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4
set shiftround

let g:vim_indent_cont = 0   " :help ft-vim-indent

" -- folding
set nofoldenable
set foldlevel=99
set fillchars=fold:\ ,foldopen:-,foldclose:+
set foldtext=CustomFoldText()
set foldmethod=expr
set foldexpr=GetPotionFold(v:lnum)
set foldnestmax=3

augroup ft_fold
    autocmd!
    autocmd FileType diff setlocal foldexpr=GetDiffFold(v:lnum)
augroup end

function! GetDiffFold(lnum) abort
    let line = getline(a:lnum)

    if line =~# '^\(diff\|Index\)'
        return '>1'
    elseif line =~# '^\(@@\|\d\)'
        return '>2'
    elseif line =~# '^\*\*\* \d\+,\d\+ \*\*\*\*$'
        return '>2'
    elseif line =~# '^--- \d\+,\d\+ ----$'
        return '>2'
    else
        return '='
    endif
endfunction

function! GetPotionFold(lnum) abort
    if getline(a:lnum) =~? '\v^\s*$'
        return '-1'
    endif

    let this_indent = indent(a:lnum) / &shiftwidth
    let next_indent = indent(NextNonBlankLine(a:lnum)) / &shiftwidth

    if next_indent <= this_indent
        return this_indent
    else
        return '>' . next_indent
    endif
endfunction

function! NextNonBlankLine(lnum) abort
    let numlines = line('$')
    let current = a:lnum + 1

    while current <= numlines
        if getline(current) =~? '\v\S'
            return current
        endif

        let current += 1
    endwhile

    return -2
endfunction

function! CustomFoldText() abort
    let fs = v:foldstart

    while getline(fs) =~ '^\s*$'
        let fs = NextNonBlankLine(fs + 1)
    endwhile

    if fs > v:foldend
        let line = getline(v:foldstart)
    else
        let line = substitute(getline(fs), '\t', repeat(' ', &tabstop), 'g')
    endif

    let w = winwidth(0) - &foldcolumn - (&number ? 8 : 0)
    let foldSize = v:foldend - v:foldstart
    let foldStr = printf(' <+> %d line%s / %d level', foldSize, foldSize % 10 == 1 ? '' : 's', v:foldlevel)
    let expansionString = repeat(' ', w - strwidth(line . foldStr))
    return line . expansionString . foldStr
endfunction

" -- completion
set wildmenu
set wildmode=longest:full,full
set completeopt=menu,menuone,preview,noselect,noinsert

function! AleCompletion(findstart, base) abort
    let result = ale#completion#OmniFunc(a:findstart, a:base)

    if result is -3
        echohl WarningMsg | call LogMsg('switching to syntax-omni') | echohl None
        setlocal omnifunc=syntaxcomplete#Complete
        return call(&omnifunc, [ a:findstart, a:base ])
    endif

    return result
endfunction

set omnifunc=AleCompletion
command! -nargs=0 ResetOmni setlocal omnifunc=AleCompletion

function! HasCodeiumCompletion() abort
    return exists('b:_codeium_completions') &&
         \ has_key(b:_codeium_completions, 'items') &&
         \ has_key(b:_codeium_completions, 'index')
endfunction

function! SmartTab() abort
    if HasCodeiumCompletion()
        return codeium#Accept()
    endif

    if pumvisible()
        return "\<C-Y>"
    endif

    if strpart(getline('.'), 0, col('.') - 1) =~ '^\s*$'
        return "\<Tab>"
    endif

    return "\<C-X>\<C-O>"
endfunction

function! SmartEsc() abort
    if HasCodeiumCompletion()
        return codeium#Clear()
    endif

    if pumvisible()
        return "\<C-E>"
    endif

    return "\<Esc>"
endfunction

inoremap <silent><expr> <Tab> SmartTab()
inoremap <silent><expr> <Esc> SmartEsc()

inoremap <S-Tab> <Cmd>call codeium#CycleOrComplete()<CR>
inoremap <C-\> <Cmd>call quicktex#DoJump()<CR>

" Start NERDTree when Vim is started without file arguments
augroup nerdtree_nofile
    autocmd!
    autocmd StdinReadPre * let s:std_in = 1
    autocmd VimEnter * if argc() == 0 && !exists('s:std_in') | NERDTreeToggle | endif
augroup end

" Automatic toggling between hybrid and absolute line numbers
augroup number_toggle
    autocmd!
    autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() !=# 'i' | set rnu   | endif
    autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu                   | set nornu | endif
augroup end

function! MakeCwd() abort
    let cwd = expand('%:p:h')

    if cwd =~ '://'
        return
    endif

    if !isdirectory(cwd)
        call mkdir(cwd, 'p')
    endif
endfunction

" Create parent directories when writing files
autocmd BufWritePre * call MakeCwd()

" Return to last edit position when opening files
function! RestoreCursor() abort
    let disable_for = [ '^gitcommit$', '^xxd$', '^gitrebase$' ]
    let enabled = &ft !~# printf('\v(%s)', join(disable_for, '|'))

    if !enabled
        return
    endif

    let line = line("'\"")

    if line > 1 && line <= line("$")
        execute "normal! g'\""
    endif
endfunction

autocmd BufReadPost * call RestoreCursor()

" Save file when leaving insert mode
autocmd InsertLeave * if !empty(expand('%')) | update | endif

function! ToggleHex() abort
    if !exists('b:hextoggle') || !b:hextoggle
        let b:row_bak = line('.')
        let b:col_bak = col('.')

        let b:mod_bak = &mod
        let b:ro_bak = &ro
        let b:ma_bak = &ma
        let b:ft_bak = &ft
        let b:bin_bak = &bin

        let b:hextoggle = 1
        let &ro = 0
        let &ma = 1

        let &ft = 'xxd'
        let &bin = 1

        silent :e
        silent execute '%!xxd'

        let &mod = 0
        let &ro = 1
        let &ma = 0
    else
        let b:hextoggle = 0
        let &ro = 0
        let &ma = 1

        let &ft = b:ft_bak
        let &bin = b:bin_bak

        silent execute '%!xxd -r'

        let &mod = b:mod_bak
        let &ro = b:ro_bak
        let &ma = b:ma_bak

        call cursor(b:row_bak, b:col_bak)
    endif
endfunction

" F1 - Help
nmap <silent> <F1> :Helptags<CR>

" F2 - Save
nmap <silent> <F2> :up<CR>

" F3 - Hex
nmap <silent> <F3> :call ToggleHex()<CR>

" F4 - NERDTree
function! FixedNTToggle() abort
    if winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()
        quit
    else
        NERDTreeToggle
    endif
endfunction

nmap <silent> <F4> :call FixedNTToggle()<CR>

" F5 - UndoTree
nmap <silent> <F5> :UndotreeToggle<CR>

" F6 - View/Edit
function! GoyoToggle() abort
    let goyo_mode = exists('#goyo')

    while v:true
        if &ro && !goyo_mode || !&ro && goyo_mode
            Goyo
            break
        endif

        let &ro = !&ro
    endwhile

    echohl WarningMsg | call LogMsg('&ro = %d', &ro) | echohl None
endfunction

nmap <silent> <F6> :call GoyoToggle()<CR>

" F7 - Search
nmap <silent> <F7> :Lines<CR>

" F10 - Quit
nmap <silent> <F10> :q<CR>

" F12 - Screen
nmap <silent> <F12> :Windows<CR>

" Shift-F1 - Terminal
command! -nargs=0 Terminal if has('nvim') | below new | endif | terminal
nmap <silent> <S-F1> :Terminal<CR>

" Shift-F2 - SaveAs
function! SaveAs() abort
    let fname = input("Save file as: ")

    if empty(fname)
        return
    endif

    execute "saveas " . fname
endfunction

nmap <silent> <S-F2> :call SaveAs()<CR>

" Shift-F10 - SaveQ
nmap <silent> <S-F10> :x<CR>

" Shift-F12 - Session
nmap <silent> <S-F12> :Sessions<CR>

" Alt-F8 - Goto
nmap <silent> <A-F8> :Marks<CR>

" Alt-F11 - ViewHs
nmap <silent> <A-F11> :History<CR>

" Cross-platform meta key
let mapleader = "\<Space>"

" Move buffer to specified direction
nmap <leader>H <C-W>H
nmap <leader>J <C-W>J
nmap <leader>K <C-W>K
nmap <leader>L <C-W>L

" Switch to buffer in specified direction
nmap <leader>h <C-W>h
nmap <leader>j <C-W>j
nmap <leader>k <C-W>k
nmap <leader>l <C-W>l

" Resize buffers
nmap <left> <C-w><
nmap <right> <C-w>>
nmap <up> <C-w>+
nmap <down> <C-w>-

" Ease navigation
nnoremap j gj
vnoremap j gj
nnoremap gj j
vnoremap gj j

nnoremap k gk
vnoremap k gk
nnoremap gk k
vnoremap gk k

nnoremap H ^
vnoremap H ^
nnoremap L g_
vnoremap L g_

nnoremap <silent> K :call ScrollUp()<CR>
nnoremap <silent> J :call ScrollDown()<CR>

function! ScrollUp() abort
    if line(".") == line("w0")
        execute "normal! " . winheight(0) / 4 . "gk"
    else
        execute "normal! H"
    endif
endfunction

function! ScrollDown() abort
    if line(".") == line("w$")
        execute "normal! " . winheight(0) / 4 . "gj"
    else
        execute "normal! L"
    endif
endfunction

" Join only selected lines
vnoremap <silent> K :'<,'>join<CR>
vnoremap <silent> J :'<,'>join<CR>

" IntelliSense movements
nnoremap <silent> gr :ALEFindReferences<CR>
nnoremap <silent> gR :ALERename<CR>
nnoremap <silent> gd :ALEGoToDefinition -vsplit<CR>
nnoremap <silent> gD :ALEGoToTypeDefinition -vsplit<CR>

" Reselect visual block after indent/outdent
vnoremap > >gv
vnoremap < <gv

" Use <Tab> in visual mode to indent/outdent
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv

" Select the text that was last pasted
nnoremap gV `[v`]

" Move line up/down
nnoremap <silent> <A-j> :m .+1<CR>==
nnoremap <silent> <A-k> :m .-2<CR>==
inoremap <silent> <A-j> <ESC>:m .+1<CR>==gi
inoremap <silent> <A-k> <ESC>:m .-2<CR>==gi
vnoremap <silent> <A-j> :m '>+1<CR>gv=gv
vnoremap <silent> <A-k> :m '<-2<CR>gv=gv

" Force <C-u> in insert mode to start a new undo group
inoremap <C-u> <C-g>u<C-u>

" Use <C-l> in insert mode to fix previous spelling mistake
inoremap <C-l> <C-g>u<Esc>[s1z=`]a<C-g>u

" Use Enter to toggle search highlight
nnoremap <silent> <CR> :set invhlsearch<CR>

" Fix search bindings
nnoremap ? :set hlsearch<CR>?
nnoremap / :set hlsearch<CR>/
nnoremap <silent> * :set hlsearch<CR>*``
nnoremap <silent> # :set hlsearch<CR>#``

" Enable search bindings in visual mode
vnoremap <silent> * :<C-u>call VisualSelection('/')<CR>:set hlsearch<CR>/<C-r>=@/<CR><CR>``
vnoremap <silent> # :<C-u>call VisualSelection('?')<CR>:set hlsearch<CR>?<C-r>=@/<CR><CR>``

function! VisualSelection(cmd) abort
    let saved_reg = @"
    execute "normal! gvy"

    if @@ =~? '^[0-9a-z,_]*$'
        let @/ = @@
    else
        let pattern = escape(@@, a:cmd . '\')
        let pattern = substitute(pattern, '^\_s\+', '\\s\\+', '')
        let pattern = substitute(pattern, '\_s\+$', '\\s\\*', '')
        let pattern = substitute(pattern, '\_s\+', '\\_s\\+', 'g')

        let @/ = '\V' . pattern
    endif

    execute "normal! gV"
    let @" = saved_reg
endfunction

" Write buffer to file in elevated mode
command! -nargs=? -complete=file Sw call SudoWrite(<f-args>)

function! SudoWrite(...) abort
    if !s:platform['windows']
        let l:fmt = 'write !sudo tee %s > /dev/null'
    else
        if !executable('sudo')
            if !executable('scoop')
                throw 'Scoop (https://scoop.sh/) is required to install gsudo'
            endif

            echo 'Installing gsudo...'
            let output = system('scoop install gsudo')

            if v:shell_error != 0
                echohl ErrorMsg | echo output | echohl None
                throw 'Installation failed'
            endif

            echo 'Installation successful. Elevating...'
        endif

        let l:fmt = 'write !sudo --ti tee %s > nul'
    endif

    if a:0 == 0
        execute printf(l:fmt, shellescape(@%))
        edit!
    else
        execute printf(l:fmt, shellescape(a:1))
    endif
endfunction

" Make Q repeat last macro instead of going into Ex mode
nnoremap Q @@

" Select all
nmap <leader>a gg<S-v>G

" Clipboard
if s:platform['linux']
    vmap <leader>c "+y
    vmap <leader>x "+c
    nmap <leader>v "+p
else
    vmap <leader>c "*y
    vmap <leader>x "*c
    nmap <leader>v "*p
endif

" https://stackoverflow.com/questions/290465/how-to-paste-over-without-overwriting-register
xnoremap <expr> p 'pgv"' . v:register . 'y`>'

" https://vi.stackexchange.com/questions/8467/how-can-i-easily-list-the-content-of-the-registers-before-pasting
nnoremap "p :registers <bar> :echo '>' <bar> execute 'normal! "' . nr2char(getchar()) . 'p'<CR>

" Leave insert mode in terminal window
tnoremap <expr> <Esc> (&ft ==# 'fzf') ? "<Esc>" : "<C-\><C-n>"
