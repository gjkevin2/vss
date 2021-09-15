#!/bin/bash
check_sys(){
    local release=''
    local systemPackage=''

    if [[ -f /etc/redhat-release ]]; then
        release='centos'
        systemPackage='yum'
    elif grep -Eqi 'debian|raspbian' /etc/issue; then
        release='debian'
        systemPackage='apt'
    elif grep -Eqi 'ubuntu' /etc/issue; then
        release='ubuntu'
        systemPackage='apt'
    elif grep -Eqi 'centos|red hat|redhat' /etc/issue; then
        release='centos'
        systemPackage='yum'
    elif grep -Eqi 'debian|raspbian' /proc/version; then
        release='debian'
        systemPackage='apt'
    elif grep -Eqi 'ubuntu' /proc/version; then
        release='ubuntu'
        systemPackage='apt'
    elif grep -Eqi 'centos|red hat|redhat' /proc/version; then
        release='centos'
        systemPackage='yum'
    fi
}

check_sys
${systemPackage} install git

curldown(){
    if [ ! -f $1 ];then
       curl -fLo $1  --create-dirs $2
    fi
} 
curldown ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

cat >~/.vimrc<<\EOF
call plug#begin('~/.vim/plugged')
Plug 'Yggdroot/indentLine'
Plug 'scrooloose/nerdtree'
Plug 'scrooloose/nerdcommenter'
Plug 'sainnhe/edge'
Plug 'vim-airline/vim-airline'
call plug#end()
EOF
vim +PlugInstall +qall

cat >>~/.vimrc<<\EOF
"----------------------------------------------------
"                    indentLine
"----------------------------------------------------
let g:indentLine_enabled = 1
let g:indent_guides_guide_size            = 1  " 指定对齐线的尺寸
let g:indent_guides_start_level           = 2  " 从第二层开始可视化显示缩进

"----------------------------------------------------
"                    nerdtree
"----------------------------------------------------
"autocmd VimEnter * NERDTree | wincmd p
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() |
    \ quit | endif

" 定义快捷键到行首和行尾

nmap LH 0
nmap LT $

" 代码折叠
set foldmethod=manual

" 比较习惯用;作为命令前缀，右手小拇指直接能按到
let mapleader = ";"

"-----------------------------------------------------------------------------------------------------
" 一些实用的设置

" ssh下方向键修复
set nocompatible
set backspace=2

"colorscheme
"colorscheme codedark
"let g:airline_theme = 'codedark'
"colorscheme gruvbox
" Important!!
if has('termguicolors')
    set termguicolors
endif
let g:edge_style='aura'
let g:edge_enable_italic=0
let g:edge_disable_italic_comment=1
colorscheme edge
set background=dark
"内置终端设在底部
set splitbelow
" 设置变量重命名：批量改变变量的名称
nmap <leader>rn <Plug>(coc-rename)
" 设置编译运行 (来自 rust.vim，加命令行参数则使用 :RustRun!)
"nnoremap <C-b> :RustRun<CR>
nnoremap <C-b> :Cargo run<CR>
" 或者使用 coc-rust-analyzer 的运行方式，它会列出当前所有可执行的方式
" nnoremap <C-b> :CocCommand rust-analyzer.run<CR>
" 控制 Coc event 启用，比如需要复制内容的时候，暂时关闭代码诊断干扰
" ee: event enable; ed: event disable
nnoremap <leader>ee :CocEnable<CR>
nnoremap <leader>ed :CocDisable<CR>

" 开启文件类型侦测
filetype on
" 根据侦测到的不同类型加载对应的插件
filetype plugin on  " 文件类型插件
filetype indent on
set autoindent
autocmd BufEnter * :syntax sync fromstart

set nu              " 显示行号
set showcmd         " 显示命令
set lz              " 当运行宏时，在命令执行完成之前，不重绘屏幕
set hid             " 可以在没有保存的情况下切换buffer
set backspace=eol,start,indent
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

" 设置字符集编码，默认使用utf8
set encoding=utf8
set fileencodings=utf8,gb2312,gb18030,ucs-bom,latin1

" 总是显示状态栏
set laststatus=2
highlight StatusLine cterm=bold ctermfg=black ctermbg=yellow

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
inoremap < <><esc>:let leavechar='>'<cr>i
inoremap ' ''<esc>:let leavechar="'"<cr>i
inoremap " ""<esc>:let leavechar='"'<cr>i

" 插件窗口的宽度，如TagList,NERD_tree等，自己设置
let s:PlugWinSize = 30

" About NERD_commenter.vim
" http://www.vim.org/scripts/script.php?script_id=1218
" Toggle单行注释/“性感”注释/注释到行尾/取消注释
map <leader>cc ,c<space>
map <leader>cs ,cs
map <leader>c$ ,c$
map <leader>cu ,cu

" NERD tree
" http://www.vim.org/scripts/script.php?script_id=1658
let NERDTreeShowHidden = 1
let NERDTreeWinPos = "left"
let NERDTreeWinSize = s:PlugWinSize
nmap <leader>n :NERDTreeToggle<cr>

"--------------- multi language ---------------
set fileencodings=utf-8,gb2312,gbk,gb18030
set termencoding=utf-8
set encoding=utf-8

"如果行尾有多余的空格(包括 Tab 键),该配置将让这些空格显示成可见的小方块
"set listchars=tab:»■,trail:■
set listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:·
set list

"保留撤销历史
"set undofile
EOF
