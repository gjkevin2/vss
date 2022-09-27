#!/bin/bash
function getlink(){
    attr=`curl https://gitee.com/gjkevin/dfiles/releases/|grep /$1|awk -F '"' '{print $2}'`
    echo "https://gitee.com"$attr
}

cd ~
wget $(getlink sublime_text_4)
sudo rm -rf /opt/sublime_text
sudo tar xJf sublime_text_4.tar.xz -C /opt
sudo tee /usr/bin/subl<<\EOF
#!/bin/sh
exec /opt/sublime_text/sublime_text --fwdargv0 "$0" "$@"
EOF
sudo chmod +x /usr/bin/subl
rm -f sublime_text_4.tar.xz

#set hosts
grep "packagecontrol.io" /etc/hosts ||echo "50.116.34.243 packagecontrol.io"|sudo tee -a /etc/hosts
grep "sublime.wbond.net" /etc/hosts ||echo "50.116.34.243 sublime.wbond.net"|sudo tee -a /etc/hosts

#font
fc-list|grep "Inconsolata"||(
sudo wget -P /usr/share/fonts/TTF https://gitee.com/gjkevin/dfiles/attach_files/811409/download/Inconsolata-Regular.ttf
sudo fc-cache -fv
)

# license file
#wget -P ~/.config/sublime-text/Local/ https://gitee.com/gjkevin/dfiles/attach_files/824858/download/License.sublime_license

#config
pip install flake8 yapf
wget $(getlink sublime-text-conf)
sudo rm -rf ~/.config/sublime-text
tar xJf sublime-text-conf.tar.xz -C ~/.config
rm -rf sublime-text-conf.tar.xz

# this is the license for sublimetext
echo '----- BEGIN LICENSE -----
TwitterInc
200 User License
EA7E-890007
1D77F72E 390CDD93 4DCBA022 FAF60790
61AA12C0 A37081C5 D0316412 4584D136
94D7F7D4 95BC8C1C 527DA828 560BB037
D1EDDD8C AE7B379F 50C9D69D B35179EF
2FE898C4 8E4277A8 555CE714 E1FB0E43
D5D52613 C3D12E98 BC49967F 7652EED2
9D2D2E61 67610860 6D338B72 5CF95C69
E36B85CC 84991F19 7575D828 470A92AB
------ END LICENSE ------
'>~/sublime-license.txt
