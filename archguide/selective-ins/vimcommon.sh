#!/bin/bash
sudo tee -a /etc/vimrc >/dev/null <<\EOF
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
inoremap < <><esc>:let leavechar='>'<cr>i
inoremap ' ''<esc>:let leavechar="'"<cr>i
inoremap " ""<esc>:let leavechar='"'<cr>i

"内置终端设在底部
set splitbelow

"如果行尾有多余的空格(包括 Tab 键),该配置将让这些空格显示成可见的小方块
set listchars=tab:»■,trail:■
set list
EOF