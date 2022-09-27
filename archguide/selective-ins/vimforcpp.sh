#!/bin/bash
sudo pacman -S --noconfirm npm clang bear

# del vimrc
rm -rf ~/.vimrc >/dev/null 2>&1

# install prepration
mkdir -p ~/.vim/pack/{plugins,colors,syntax} >/dev/null 2>&1
cd ~/.vim/pack/
if [ ! -d .git ];then
    git init
fi

# install extension
install(){
    a=$1
    b=${a#*/}
    c=${b%.*}
    echo "========installing $c==========="
    if [ ! -d $2/start/$c ]; then
        if  [ 0$3 != 0 ];then
            git submodule add -b $3 https://ghproxy.com/https://github.com/$1 $2/start/$c
        else
            git submodule add https://ghproxy.com/https://github.com/$1 $2/start/$c
        fi
        vim +"helptags $2/start/$c/doc" +q
    else
        git submodule update
    fi
} 

# list of extensions
mkdir ~/.config/coc >/dev/null 2>&1 # coc-extensions folder needed when you run vim +"command" to install
install neoclide/coc.nvim plugins release
install rakr/vim-one colors
install scrooloose/nerdtree plugins
install scrooloose/nerdcommenter plugins
install Xuyuanp/nerdtree-git-plugin plugins
install skywind3000/asyncrun.vim plugins
install Yggdroot/indentLine colors
install luochen1990/rainbow colors
install rust-lang/rust.vim syntax

# Install extensions
mkdir -p ~/.config/coc/extensions
cd ~/.config/coc/extensions
if [ ! -f package.json ]
then
  echo '{"dependencies":{}}'> package.json
fi
# Change extension names to the extensions you need
npm install coc-json coc-clangd --global-style --ignore-scripts --no-bin-links --no-package-lock --only=prod

cat >~/.vimrc<<\EOF
set nocompatible    " 避免vi的兼容性bug
set nu              " 显示行号
set showcmd         " 显示命令
set lz              " 当运行宏时，在命令执行完成之前，不重绘屏幕
set hid             " 可以在没有保存的情况下切换buffer
set backspace=2     " ssh下方向键修复
set whichwrap+=<,>,h,l " 退格键和方向键可以换行
set incsearch       " 增量式搜索
set hlsearch        " 搜索时，高亮显示匹配结果。
" set ignorecase      " 搜索时忽略大小写
set magic           " 额，自己:h magic吧，一行很难解释
set showmatch       " 光标遇到圆括号、方括号、大括号时，自动高亮对应的另一个圆括号、方括号和大括号。
set nobackup        " 关闭备份
set nowb
set noswapfile      " 不使用swp文件，注意，错误退出后无法恢复
set lbr             " 在breakat字符处而不是最后一个字符处断行
set ai              " 自动缩进
set si              " 智能缩进
set cindent         " C/C++风格缩进

" 背景设置与主题设置
if has('termguicolors')
    set termguicolors
endif
colorscheme one
set background=dark

" 设置字符集编码，默认使用utf8
set encoding=utf8
set fileencodings=utf8,gb2312,gb18030,ucs-bom,latin1
" 开启文件类型侦测
filetype on
" 根据侦测到的不同类型加载对应的插件
filetype plugin on  " 文件类型插件
filetype indent on
autocmd BufEnter * :syntax sync fromstart

" 比较习惯用;作为命令前缀，右手小拇指直接能按到
let mapleader = ";"

"命令模式下，底部操作指令按下 Tab 键自动补全。第一次按下 Tab，会显示所有匹配的操作指令的清单；第二次按下 Tab，会依次选择各个指令。
set wildmenu
set wildmode=longest:list,full

set nofen
set fdl=10
" tab转化为4个字符
set expandtab
set smarttab
set shiftwidth=4
set tabstop=4
" 不使用beep或flash
set vb t_vb=
" 启用256色
set t_Co=256
set t_ut=n

set history=500  " vim记住的历史操作的数量，默认的是20
set autoread     " 当文件在外部被修改时，自动重新读取
set mouse=a      " 在所有模式下都允许使用鼠标，还可以是n,v,i,c等

" 行首、尾快捷键
nmap LH 0
nmap LT $
" 折叠代码
set foldmethod=manual

" 总是显示状态栏
set laststatus=2
set statusline=%1*%F%m%r%h%w%=\ %2*\ %Y\ %3*%{\"\".(\"\"?&enc:&fenc).((exists(\"+bomb\")\ &&\ &bomb)?\"+\":\"\").\"\"}\ %4*[%l,%v]\ %5*%p%%\ \|\ %6*%LL

" 获取当前路径，将$HOME转化为~
function! CurDir()
    let curdir = substitute(getcwd(), $HOME, "~", "g")
    return curdir
endfunction

" 根据给定方向搜索当前光标下的单词，结合下面两个绑定使用
function! VisualSearch(direction) range
    let l:saved_reg = @"
    execute "normal! vgvy"
    let l:pattern = escape(@", '\\/.*$^~[]')
    let l:pattern = substitute(l:pattern, "\n{1}quot;, "", "")
    if a:direction == 'b'
        execute "normal ?" . l:pattern . "<cr>"
    else
        execute "normal /" . l:pattern . "<cr>"
    endif
    let @/ = l:pattern
    let @" = l:saved_reg
endfunction

" 用 */# 向 前/后 搜索光标下的单词
vnoremap <silent> * :call VisualSearch('f')<CR>
vnoremap <silent> # :call VisualSearch('b')<CR>

" 在文件名上按gf时，在新的tab中打开
map gf :tabnew <cfile><cr>

" 用c-j,k在buffer之间切换
nn <C-J> :bn<cr>
nn <C-K> :bp<cr>
nn <C-H> :b1<cr>

" 删除buffer时不关闭窗口
command! Bclose call <SID>BufcloseCloseIt()
function! <SID>BufcloseCloseIt()
    let l:currentBufNum = bufnr("%")
    let l:alternateBufNum = bufnr("#")
    if buflisted(l:alternateBufNum)
        buffer #
    else
        bnext
    endif
    if bufnr("%") == l:currentBufNum
        new
    endif
    if buflisted(l:currentBufNum)
        execute("bdelete! ".l:currentBufNum)
    endif
endfunction

" 快捷输入
" 自动完成括号和引号
inoremap ( ()<esc>:let leavechar=")"<cr>i
inoremap [ []<esc>:let leavechar="]"<cr>i
inoremap { {}<esc>:let leavechar="}"<cr>i
"inoremap {} {<esc>o}<esc>:let leavechar="}"<cr>O
"inoremap < <><esc>:let leavechar='>'<cr>i
inoremap ' ''<esc>:let leavechar="'"<cr>i
inoremap " ""<esc>:let leavechar='"'<cr>i

" 插件窗口的宽度，如TagList,NERD_tree等，自己设置
let s:PlugWinSize = 30

"内置终端设在底部
set splitbelow

"如果行尾有多余的空格(包括 Tab 键),该配置将让这些空格显示成可见的小方块
set listchars=tab:»■,trail:■
set list

"----------------------------------------------------
"                    rust.vim
"----------------------------------------------------
syntax enable
filetype plugin indent on
" 保存时代码自动格式化
let g:rustfmt_autosave = 1

"----------------------------------------------------
"                    indentLine
"----------------------------------------------------
let g:indentLine_enabled = 1
let g:indent_guides_guide_size            = 1  " 指定对齐线的尺寸
let g:indent_guides_start_level           = 2  " 从第二层开始可视化显示缩进
autocmd FileType json,markdown let g:indentLine_conceallevel = 0  "json文件显示双引号

"----------------------------------------------------
"                    nerdtree
"----------------------------------------------------
"autocmd VimEnter * NERDTree | wincmd p
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() |
    \ quit | endif
let NERDTreeShowHidden = 1
let NERDTreeWinPos = "left"
let NERDTreeWinSize = s:PlugWinSize
nmap <leader>n :NERDTreeToggle<cr>

"----------------------------------------------------
"                    nerdcommenter
"----------------------------------------------------
" Toggle单行注释/“性感”注释/注释到行尾/取消注释
map <leader>cc ,c<space>
map <leader>cs ,cs
map <leader>c$ ,c$
map <leader>cu ,cu

"----------------------------------------------------
"                    Rainbow
"----------------------------------------------------
let g:rainbow_active = 1
let g:rainbow_conf = {
\   'guifgs': ['darkorange3', 'seagreen3', 'royalblue3', 'firebrick'],
\   'ctermfgs': ['lightyellow', 'lightcyan','lightblue', 'lightmagenta'],
\   'operators': '_,_',
\   'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
\   'separately': {
\       '*': {},
\       'tex': {
\           'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/'],
\       },
\       'lisp': {
\           'guifgs': ['darkorange3', 'seagreen3', 'royalblue3', 'firebrick'],
\       },
\       'vim': {
\           'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/', 'start=/{/ end=/}/ fold', 'start=/(/ end=/)/ containedin=vimFuncBody', 'start=/\[/ end=/\]/ containedin=vimFuncBody', 'start=/{/ end=/}/ fold containedin=vimFuncBody'],
\       },
\       'html': {
\           'parentheses': ['start=/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'|[^ '."'".'"><=`]*))?)*\>/ end=#</\z1># fold'],
\       },
\       'css': 0,
\   }
\}

"------------------------------------------------------------------------
"                  about language server protocol(coc.nvim)
"------------------------------------------------------------------------
" TextEdit might fail if hidden is not set.
set hidden

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" Give more space for displaying messages.
set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
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
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Mappings for CoCList
" Show all diagnostics.
nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions.
nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
" Show commands.
nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document.
nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols.
nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list.
nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>

"------------------------------------------------------------------------
"                  asyncrun
"------------------------------------------------------------------------
let g:asyncrun_open = 6     " 自动打开 quickfix window ，高度为 6
let g:asyncrun_bell = 1     " 任务结束时候响铃提醒
let g:asyncrun_encs='gbk'   " quickfix chinese display
"设置 F10 打开/关闭 Quickfix 窗口
nnoremap <F10> :call asyncrun#quickfix_toggle(6)<cr> 
"F9 编译单个文件
"insert mode编译
func Compileccpp()
    exec "w"
    if &filetype == "cpp"
            exec 'AsyncRun g++ -Wall -O2 "$(VIM_FILEPATH)" -o "$(VIM_FILEDIR)/$(VIM_FILENOEXT)"'
    elseif &filetype == "c"
            exec 'AsyncRun gcc -Wall -O2 "$(VIM_FILEPATH)" -o "$(VIM_FILEDIR)/$(VIM_FILENOEXT)"'
    elseif &filetype == "rs"
            exec 'AsyncRun rustc "$(VIM_FILEPATH)" -o "$(VIM_FILEDIR)/$(VIM_FILENOEXT)"'
    endif
endfunc
inoremap <silent> <F9> <ESC> :call Compileccpp() <cr>
"normal mode 编译
nnoremap <silent> <F9> :call Compileccpp() <cr>
"autocmd FileType c nnoremap <buffer> <F9> :AsyncRun gcc -Wall -O2 "$(VIM_FILEPATH)" -o "$(VIM_FILEDIR)/$(VIM_FILENOEXT)" <cr>
"F5 运行
nnoremap <silent> <F5> :AsyncRun -raw -cwd=$(VIM_FILEDIR) "$(VIM_FILEDIR)/$(VIM_FILENOEXT)" <cr>
"人机交互；使用内置term，(-mode=term -pos=bottom -rows=10)
nnoremap <silent> <C-F5> :AsyncRun -raw -cwd=$(VIM_FILEDIR) -mode=term -pos=bottom -rows=10 "$(VIM_FILEDIR)/$(VIM_FILENOEXT)" <cr>
"接下来是项目的编译,注意项目根目录里要有如下后缀文件，没有则放一个空的 .root 文件到你的项目目录下就行了
let g:asyncrun_rootmarks = ['.svn', '.git', '.root', '_darcs', 'build.xml']
"F7 编译整个项目
func Buildmore()
    exec "w"
    if &filetype == "cpp"
            exec 'AsyncRun -cwd=<root> make'
    elseif &filetype == "c"
            exec 'AsyncRun -cwd=<root> make'
    elseif &filetype == "rs"
            exec 'AsyncRun -cwd=<root> cargo build'
    endif    
endfunc
nnoremap <silent> <F7> <ESC> :call Buildmore() <cr>
"F8 运行当前项目
func Runmore()
    exec "w"
    if &filetype == "cpp"
            exec 'AsyncRun -cwd=<root> -raw make run'
    elseif &filetype == "c"
            exec 'AsyncRun -cwd=<root> -raw make run'
    elseif &filetype == "rs"
            exec 'AsyncRun -cwd=<root> cargo run'
    endif
endfunc
nnoremap <silent> <F8> <ESC> :call Runmore() <cr>
"人机交互；使用内置term，(-mode=term -pos=bottom -rows=10)
nnoremap <silent> <C-F8> :AsyncRun -cwd=<root> -raw -mode=term -pos=bottom -rows=10 make run <cr>
"当然，你的 makefile 中需要定义怎么 run ，接着按 F6 执行测试
nnoremap <silent> <F6> :AsyncRun -cwd=<root> -raw make test <cr>
"cmake 的话，还可以照葫芦画瓢，定义 F4 为更新 Makefile 文件
nnoremap <silent> <F4> :AsyncRun -cwd=<root> cmake . <cr>
"想实时看到 printf 输出的话需要 fflush(stdout) 一下

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"            新文件标题
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""定义函数SetTitle，自动插入文件头 
function SetTitle() 
	"如果文件类型为.sh文件 
	if &filetype == 'sh' 
		call setline(1, "##########################################################################") 
		call append(line("."), "# File Name: ".expand("%")) 
		call append(line(".")+1, "# Author: kevin") 
		call append(line(".")+2, "# mail: gjkevin@163.com") 
		call append(line(".")+3, "# Created Time: ".strftime("%c")) 
		call append(line(".")+4, "#########################################################################") 
		call append(line(".")+5, "#!/bin/zsh")
		call append(line(".")+6, "PATH=/home/edison/bin:/home/edison/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/work/tools/gcc-3.4.5-glibc-2.3.6/bin")
		call append(line(".")+7, "export PATH")
		call append(line(".")+8, "")
	else 
		call setline(1, "/*************************************************************************") 
		call append(line("."), "	* File Name: ".expand("%")) 
		call append(line(".")+1, "	* Author: kevin") 
		call append(line(".")+2, "	* Mail: gjkevin@163.com ") 
		call append(line(".")+3, "	* Created Time: ".strftime("%c")) 
		call append(line(".")+4, " ************************************************************************/") 
		call append(line(".")+5, "")
	endif
	if &filetype == 'cpp'
		call append(line(".")+6, "#include<iostream>")
    	call append(line(".")+7, "using namespace std;")
		call append(line(".")+8, "")
	endif
	if &filetype == 'c'
		call append(line(".")+6, "#include<stdio.h>")
		call append(line(".")+7, "")
	endif
	"	if &filetype == 'java'
	"		call append(line(".")+6,"public class ".expand("%"))
	"		call append(line(".")+7,"")
	"	endif
	"新建文件后，自动定位到文件末尾
	" autocmd BufNewFile * normal G
    normal G
endfunction
"新建.c,.h,.sh,.java文件，自动插入文件头 
autocmd BufNewFile *.cpp,*.[ch],*.sh,*.java exec ":call SetTitle()" 
EOF
