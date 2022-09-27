#!/bin/bash
sudo pacman -S --noconfirm rxvt-unicode
if [ ! -f /usr/share/fonts/TTF/iosevka-regular.ttf ];then
    # sudo wget -P /usr/share/fonts/TTF https://gitee.com/gjkevin/dfiles/attach_files/815239/download/Hack-Regular.ttf
    sudo wget -P /usr/share/fonts/TTF https://gitee.com/gjkevin/dfiles/attach_files/815483/download/iosevka-regular.ttf
    sudo fc-cache -fv
fi

cat >$HOME/.Xresources<<\EOF
URxvt.preeditType:Root
URxvt.internalBorder: 0
!!调整此处设置输入法
URxvt.inputMethod:fcitx
!!颜色设置
URxvt.depth:32
!!中括号内数表示透明度
!!URxvt.inheritPixmap:true
URxvt*background: #1c1c1c
URxvt*foreground: #eeeeec
! black
URxvt.color0  : #2e3436
URxvt.color8  : #2e3436
! red
URxvt.color1  : #cc0000
URxvt.color9  : #ef2929
! green
URxvt.color2  : #73d216
URxvt.color10 : #8ae234
! yellow
URxvt.color3  : #edd400
URxvt.color11 : #fce94f
! blue
URxvt.color4  : #3465a4
URxvt.color12 : #729fcf
! magenta
URxvt.color5  : #75507b
URxvt.color13 : #ad7fa8
! cyan
URxvt.color6  : #06989a
URxvt.color14 : #34e2e2
! white
URxvt.color7  : #d3d7cf
URxvt.color15 : #eeeeec
!!URL操作
URxvt.urlLauncher:chromium
URxvt.matcher.button:1
Urxvt.perl-ext-common:matcher
!!滚动条设置
URxvt.scrollBar:False
URxvt.scrollBar_floating:False
URxvt.scrollstyle:rxvt
!!滚屏设置
URxvt.mouseWheelScrollPage:False
URxvt.scrollTtyOutput:False
URxvt.scrollWithBuffer:True
URxvt.scrollTtyKeypress:True
!!光标闪烁
URxvt.cursorBlink:False
URxvt.saveLines:3000
!!边框
URxvt.borderLess:False
!!字体间距
URxvt.letterSpace: 0
!!URxvt.lineSpace: -2
!!字体设置
Xft.dpi:96
!!抗锯齿
Xft.antialias:true
!!URxvt.font:xft:Sarasa Fixed SC:style=Regular:size=11
URxvt.font:xft:Iosevka:style=Regular:size=11,xft:Source Han Serif SC:style=Medium:size=12
!!URxvt.font:xft:Hack:style=Regular:size=9,xft:Sarasa Fixed SC:style=Regular:pixelsize=12
!!URxvt.boldfont:xft:Iosevka:style=Regular:size=12,xft:Sarasa Fixed SC:style=Regular:size=12
EOF

#不重启则运行下面命令加载配置
#xrdb -merge $HOME/.Xresources
