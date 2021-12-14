"" set the runtime path to include Vundle and initialize
" " coursier bootstrap  ch.epfl.lamp:dotty-language-server_0.11:0.11.0-RC1 -M dotty.tools.languageserver.Main  -o /usr/local/bin/dotty -f --standalone
" set rtp+=~/.vim/bundle/Vundle.vim
set shell=sh
set visualbell
call plug#begin('~/.vim/plugged')

" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plug 'gmarik/Vundle.vim'
Plug 'jiangmiao/auto-pairs'
Plug 'pangloss/vim-javascript'
Plug 'Glench/Vim-Jinja2-Syntax'
"Plug 'lervag/vimtex'

" Add all your plugins here (note older versions of Vundle used Bundle instead of Plugin)


" Bundle 'Valloric/YouCompleteMe'
Plug 'scrooloose/nerdtree'
Plug 'epeli/slimux'
Plug 'othree/html5.vim'
Plug 'gregsexton/MatchTag'
" Plug 'JCLiang/vim-cscope-utils'
Plug 'neomake/neomake'
" Plug 'c.vim'
Plug 'nvie/vim-flake8'
Plug 'jistr/vim-nerdtree-tabs'
Plug 'kien/ctrlp.vim'
Plug 'tpope/vim-fugitive'
Plug 'tmhedberg/SimpylFold'
Plug 'vim-scripts/indentpython.vim'
Plug 'wikitopian/hardmode'
Plug 'endel/vim-github-colorscheme'
Plug 'dkprice/vim-easygrep'
"Plug 'scalameta/coc-metals', {'do': 'yarn install --frozen-lockfile'}
"Plug 'natebosch/vim-lsc'
"Plug 'prabirshrestha/async.vim'
"Plug 'prabirshrestha/vim-lsp'
"Plug 'prabirshrestha/asyncomplete.vim'
"Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'derekwyatt/vim-scala'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'vim-scripts/cscope_macros.vim'

Plug 'gurpreetatwal/vim-avro'
Plug 'tweekmonster/django-plus.vim'
" Plug 'Rykka/InstantRst'
" Plug 'Rykka/riv.vim'
" Plug 'vim-scripts/gnuplot-syntax-highlighting'
"Bundle 'ensime/ensime-vim'
"Plug 'klen/python-mode'

" All of your Plugins must be added before the following line
call plug#end()
filetype plugin indent on    " required

" Configuration for vim-scala
au BufRead,BufNewFile *.sbt set filetype=scala
au BufRead,BufNewFile *.bzl set filetype=python
let g:tex_flavor = 'latex'
set splitright
" GNUPLOT stuff
set syntax=gnuplot
au BufNewFile,BufRead *.plt,.gnu,.gp,.gnuplot setf gnuplot
autocmd BufRead,BufNewFile *.avdl,*.avro set filetype=avdl


"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>


" Enable folding
set foldmethod=indent
set foldlevel=99

" Enable folding with the spacebar
nnoremap <space> za
"au User lsp_setup call lsp#register_server({
"    \ 'name': 'ensime',
"    \ 'cmd': {server_info->[&shell, &shellcmdflag, 'dotty -stdio']},
"    \ 'whitelist': ['scala'],
"    \ })
"
if executable('java') && filereadable(expand('~/lsp/eclipse.jdt.ls/plugins/org.eclipse.equinox.launcher_1.5.600.v20191014-2022.jar'))
    au User lsp_setup call lsp#register_server({
        \ 'name': 'eclipse.jdt.ls',
        \ 'cmd': {server_info->[
        \     'java',
        \     '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        \     '-Dosgi.bundles.defaultStartLevel=4',
        \     '-Declipse.product=org.eclipse.jdt.ls.core.product',
        \     '-Dlog.level=ALL',
        \     '-noverify',
        \     '-Dfile.encoding=UTF-8',
        \     '-Xmx1G',
        \     '-jar',
        \     expand('~/lsp/eclipse.jdt.ls/plugins/org.eclipse.equinox.launcher_1.5.600.v20191014-2022.jar'),
        \     '-configuration',
        \     expand('~/lsp/eclipse.jdt.ls/config_linux'),
        \     '-data',
        \     getcwd()
        \ ]},
        \ 'whitelist': ['java'],
        \ 'root_uri' : { server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_directory(lsp#utils#get_buffer_path(), 'pom.xml/..')) }, 
        \ })
endif
au User lsp_setup call lsp#register_server({
	\ 'name': 'pyls',
	\ 'cmd': {server_info->['pyls']},
	\ 'whitelist': ['python']
	\ })


let g:SimpylFold_docstring_preview=1



" Map SLIM
nnoremap <Leader>sl :SlimuxREPLSendLine<CR>
vnoremap <Leader>ss :SlimuxREPLSendSelection<CR>
nnoremap <leader>sb :SlimuxREPLSendBuffer<CR>
map <Leader>k :w <bar> :SlimuxShellLast<CR>
let g:slimux_select_from_current_window = 1



set encoding=utf-8



" let g:ycm_autoclose_preview_window_after_completion=1
" map <leader>g  :YcmCompleter GoToDefinitionElseDeclaration<CR>

autocmd VimEnter,BufNewFile,BufReadPost * silent! call HardMode()
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

let python_highlight_all=1
syntax on
"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
"let g:syntastic_check_on_open = 1
"let g:syntastic_python_checkers = ['pylint','pyflakes','pep8']
"let g:syntastic_check_on_wq = 0
"
" When writing a buffer (no delay).
call neomake#configure#automake('w')
" When writing a buffer (no delay), and on normal mode changes (after 750ms).
call neomake#configure#automake('nw', 750)
" When reading a buffer (after 1s), and when writing (no delay).
call neomake#configure#automake('rw', 1000)
" Full config: when writing or reading a buffer, and on changes in insert and
" normal mode (after 1s; no delay when writing).
call neomake#configure#automake('nrwi', 500)

let g:neomake_scala_enabled_makers = ['fsc','scalastyle']

let NERDTreeIgnore=['\.pyc$', '\~$'] "ignore files in NERDTree
set number
set t_Co=256
colorscheme github
set background=light
set nobackup

"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*

"let g:pymode_rope = 1
"
"" Documentation
"let g:pymode_doc = 1
"let g:pymode_doc_key = 'K'
"
""Linting
"let g:pymode_lint = 1
"let g:pymode_lint_checker = "pylint,pyflakes,pep8"
"" Auto check on save
"let g:pymode_lint_write = 1
"
"" Support virtualenv
let g:pymode_virtualenv = 1
"
"" Enable breakpoints plugin
"let g:pymode_breakpoint = 1
"
"" syntax highlighting
"let g:pymode_syntax = 1
"let g:pymode_syntax_all = 1
"let g:pymode_syntax_indent_errors = g:pymode_syntax_all
"let g:pymode_syntax_space_errors = g:pymode_syntax_all
"
"let g:pymode_python = 'python'
 let g:syntastic_debug = 1
let g:lsp_log_verbose = 1
let g:lsp_log_file = expand('/tmp/vim-lsp.log')
let g:lsp_signs_enabled = 1         " enable signs
let g:lsp_diagnostics_echo_cursor = 1 " enable echo under cursor when in normal mode
let g:lsp_async_completion = 1
" ====================================== lsp settings
nnoremap <silent> <C-]> :LspDefinition<CR>
nnoremap <silent> <Leader>rf :LspReferences<CR>
nnoremap <silent> <Leader>im :LspImplementation<CR>


autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif
" Configuration for vim-lsc
let g:lsc_enable_autocomplete = v:false
let g:lsc_auto_map = {
    \ 'GoToDefinition': 'gd',
    \}
let g:lsc_server_commands = {
  \ 'scala': 'metals-vim'
  \}

au BufRead,BufNewFile *.sbt set filetype=sbt
set tags=~/mytags

" if hidden is not set, TextEdit might fail.
set hidden

" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup

" Better display for messages
set cmdheight=2

" You will have bad experience for diagnostic messages when it's default 4000.
set updatetime=300

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
" Or use `complete_info` if your vim support it, like:
" inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"

" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight symbol under cursor on CursorHold
autocmd CursorHold * silent call CocActionAsync('highlight')

" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)

" Remap for format selected region
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap for do codeAction of current line
nmap <leader>ac  <Plug>(coc-codeaction)
" Fix autofix problem of current line
nmap <leader>qf  <Plug>(coc-fix-current)

" Create mappings for function text object, requires document symbols feature of languageserver.
xmap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap if <Plug>(coc-funcobj-i)
omap af <Plug>(coc-funcobj-a)

" Use <TAB> for select selections ranges, needs server support, like: coc-tsserver, coc-python
nmap <silent> <TAB> <Plug>(coc-range-select)
xmap <silent> <TAB> <Plug>(coc-range-select)

" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')

" Use `:Fold` to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" use `:OR` for organize import of current buffer
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add status line support, for integration with other plugin, checkout `:h coc-status`
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Using CocList
" Show all diagnostics
nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions
nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document
nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent> <space>p  :<C-u>CocListResume<CR>

autocmd Filetype htmldjango setlocal ts=2 sts=2 sw=2 expandtab

" let g:ctrlp_max_files=0
let g:ctrlp_max_depth=400
let g:ctrlp_custom_ignore = '\v[\/](bazel-bin|bazel-bsmining|bazel-out|bazel-testlogs|frontend|node_modules)|(\.(swp|ico|git|svn))$'
let g:ctrlp_working_path_mode = 'r'
let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files']

autocmd FileType html setlocal expandtab shiftwidth=2 tabstop=2
