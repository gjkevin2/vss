#!/bin/bash
sudo pacman -Syyu --noconfirm
# scrot is a screenshot app
sudo pacman -S --noconfirm bspwm sxhkd dmenu feh picom lightdm lightdm-gtk-greeter ranger numlockx
# if mount-mtp went wrong ,you shoud addtional install jmtpfs, use yay -S jmtpfs
sudo pacman -S --noconfirm pcmanfm-gtk3 viewnior gvfs-afc gvfs-mtp ntfs-3g cifs-utils pulseaudio-alsa pavucontrol imagemagick
# install fonts
# sudo pacman -S --noconfirm adobe-source-han-serif-cn-fonts
#auto numlock on when start
sudo sed -i "s/#greeter-setup-script=/greeter-setup-script=\/usr\/bin\/numlockx on/" /etc/lightdm/lightdm.conf
# echo "exec /usr/bin/numlockx on" >>~/.xinitrc
#kill qv2ray when logout to prevent some errors
#sudo sed -i "s/#session-cleanup-script=/session-cleanup-script=killall qv2ray/" /etc/lightdm/lightdm.conf
sudo systemctl enable lightdm.service

#configure bspwm
install -Dm755 /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/bspwmrc
install -Dm644 /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/sxhkd/sxhkdrc
sed -r -i "s/(border_width\s+)2/\11/" ~/.config/bspwm/bspwmrc
sed -r -i "s/(window_gap\s+)12/\1 2/" ~/.config/bspwm/bspwmrc
#change some themes
sed -i "/window_gap/a\bspc config focus_follows_pointer true\nbspc config ignore_ewmh_focus true\n\nbspc config focused_border_color \"#ff79c6\"\nbspc config normal_border_color \"#44475a\"\nbspc config active_border_color \"#bd93f9\"\nbspc config presel_feedback_color \"#6272a4\"" ~/.config/bspwm/bspwmrc
# vim ~/.config/sxhkd/sxhkdrc
sed -i 's/@space/d/' ~/.config/sxhkd/sxhkdrc

# virtual use urxvt, actual use alacritty.
# you can use ( ls -1 /dev/disk/by-id/|grep "QMEU" ) to find virtual machine too
systemd-detect-virt >/dev/null 2>&1 && {
    bash <(curl https://ghproxy.com/https://raw.githubusercontent.com/gjkevin2/vss/master/archguide/urxvtins.sh)
    # virtualbox Guest Additions
    sudo pacman -S --noconfirm virtualbox-guest-utils
    sudo systemctl enable vboxservice
}||{
    sudo pacman -S --noconfirm alacritty
    sed -i "/super + Return/{N;s/urxvt/alacritty/}" ~/.config/sxhkd/sxhkdrc

    #alacritty config
    cat >~/.config/alacritty.yml<<\EOF
env:
    TERM: xterm-256color

colors:
    primary:
        foreground: '0xeeeeec'

    normal:
        black:   '0x2e3436'
        red:     '0xcc0000'
        green:   '0x73d216'
        yellow:  '0xedd400'
        blue:    '0x3465a4'
        magenta: '0x75507b'
        cyan:    '0x06989a'
        white:   '0xd3d7cf'

    bright:
        black:   '0x2e3436'
        red:     '0xef2929'
        green:   '0x8ae234'
        yellow:  '0xfce94f'
        blue:    '0x729fcf'
        magenta: '0xad7fa8'
        cyan:    '0x34e2e2'
        white:   '0xeeeeec'

window.opacity: 1.0

# 设置字体
font:
    normal:
        family: Source Code Pro
    # 字大小
    size: 11.0

scrolling:
    # 回滚缓冲区中的最大行数,指定“0”将禁用滚动。
    history: 10000
    # 滚动行数 
    multiplier: 10

# 如果为‘true’，则使用亮色变体绘制粗体文本。
draw_bold_text_with_bright_colors: true

selection:
    semantic_escape_chars: ',│`|:"'' ()[]{}<>'
    save_to_clipboard: true

live_config_reload: true

key_bindings:
    # (Windows, Linux, and BSD only)
- { key: V,         mods: Control|Shift, action: Paste                       }
- { key: C,         mods: Control|Shift, action: Copy                        }
- { key: Insert,    mods: Shift,         action: PasteSelection              }
- { key: Key0,      mods: Control,       action: ResetFontSize               }
- { key: Equals,    mods: Control,       action: IncreaseFontSize            }
- { key: Plus,      mods: Control,       action: IncreaseFontSize            }
- { key: Minus,     mods: Control,       action: DecreaseFontSize            }
- { key: F11,       mods: None,          action: ToggleFullscreen            }
- { key: Paste,     mods: None,          action: Paste                       }
- { key: Copy,      mods: None,          action: Copy                        }
- { key: L,         mods: Control,       action: ClearLogNotice              }
- { key: L,         mods: Control,       chars: "\x0c"                       }
- { key: PageUp,    mods: None,          action: ScrollPageUp,   mode: ~Alt  }
- { key: PageDown,  mods: None,          action: ScrollPageDown, mode: ~Alt  }
- { key: Home,      mods: Shift,         action: ScrollToTop,    mode: ~Alt  }
- { key: End,       mods: Shift,         action: ScrollToBottom, mode: ~Alt  }
EOF
}

yay -S --noconfirm polybar
sudo pacman -S --noconfirm ttf-font-awesome i3lock
mkdir ~/.config/polybar
cd ~/.config/polybar
cat >launch.sh<<-EOF
#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch Polybar, using default config location ~/.config/polybar/config
polybar example &

echo "Polybar launched..."
EOF
chmod +x launch.sh
curl https://ghproxy.com/https://raw.githubusercontent.com/gjkevin2/vss/master/archguide/config>./config
#mod interface
int=$(ip addr|grep "state UP"|awk -F ":" '{print $2}'|head -n1)
sed -r -i "s/(^interface\s+=)(.*)/\1$int/" ./config
#mod i3lock
wget -O i3lock.jpg https://browser9.qhimg.com/bdr/__100/t019fd908f724f51900.jpg
bash -c 'for i in *.jpg; do convert "$i" "${i%.jpg}.png"; done'
#mod bindkey
sed -i "/dmenu_run/a\\\n#shutdown" ~/.config/sxhkd/sxhkdrc
sed -i "/#shutdown/a\\super + End\n\tshutdown -h now" ~/.config/sxhkd/sxhkdrc
sed -i "/dmenu_run/a\\\n#reboot" ~/.config/sxhkd/sxhkdrc
sed -i "/#reboot/a\\super + Home\n\treboot" ~/.config/sxhkd/sxhkdrc
sed -i "/dmenu_run/a\\\n#lockscreen" ~/.config/sxhkd/sxhkdrc
sed -i "/#lockscreen/a\\super + l\n\ti3lock -i ~/.config/polybar/i3lock.png" ~/.config/sxhkd/sxhkdrc
sed -i '/bspwm hotkeys/{n;s/#/#\n\n#PrintScreen/}' ~/.config/sxhkd/sxhkdrc
sed -i "/#PrintScreen/a\\super + alt + a\n\tflameshot gui" ~/.config/sxhkd/sxhkdrc
sed -i '/bspwm hotkeys/{n;s/#/#\n\n#filemaster/}' ~/.config/sxhkd/sxhkdrc
sed -i "/#filemaster/a\\super + e\n\tpcmanfm" ~/.config/sxhkd/sxhkdrc
sed -i '/bspwm hotkeys/{n;s/#/#\n\n#chromium/}' ~/.config/sxhkd/sxhkdrc
sed -i "/#chromium/a\\super + c\n\tchromium" ~/.config/sxhkd/sxhkdrc
# {} need "" to wrap when they are used to be match
sed -i "/bspc node -"{"f,s"}" "{"west,south,north,east"}"/a\\\n# Flip layout vertically\/horizontally\nsuper + \{_,shift + \}a\n\tbspc node @\/ --flip \{vertical,horizontal\}" ~/.config/sxhkd/sxhkdrc

# semi-transparent
# sed -r -i "0,/example/{s/(^background\s+=\s+)(.*)/\1#66000000/}" ~/.config/polybar/config
# install mpd and show on polybar,if you run this on chroot
# you'd run a self-del script to enable systemd when restart, e.x. run this script in parent script
bash <(curl https://ghproxy.com/https://raw.githubusercontent.com/gjkevin2/vss/master/archguide/mpdins.sh)

mkdir ~/.config/picom
cat>~/.config/picom/picom.conf<<-EOF
inactive-opacity = 0.9;
active-opacity = 1.0;
#opacity-rule = [ "99:name *?= 'firefox'"]
#vsync = true
detect-transient = true;
detect-client-leader = true;
use-damage = true;
EOF
# real pc needs vsync
systemd-detect-virt >/dev/null 2>&1 ||{
cat>>~/.config/picom/picom.conf<<-EOF
vsync = true;
EOF
}

#polkit for mount filesystem
sudo tee /etc/polkit-1/rules.d/00-mount-internal.rules >/dev/null <<-EOF
polkit.addRule(function(action, subject) {
   if ((action.id == "org.freedesktop.udisks2.filesystem-mount-system" &&
      subject.local && subject.active && subject.isInGroup("storage")))
      {
         return polkit.Result.YES;
      }
});
EOF
#then add to storage group
sudo usermod -aG storage $(whoami)

# no need to start xdman, it will be start by the browser plugins when you want to download
#sed -i "/sxhkd/a\$HOME\/.config\/polybar\/launch.sh & fcitx5 & qv2ray &\npicom &" ~/.config/bspwm/bspwmrc
sed -i "/sxhkd/a\$HOME\/.config\/polybar\/launch.sh & fcitx5 &\npicom --experimental-backends -f &" ~/.config/bspwm/bspwmrc
echo -e "bspc rule -a xdman-Main state=floating\nbspc rule -a Pcmanfm desktop='^3'\nbspc rule -a Sublime_text desktop='^4'">>~/.config/bspwm/bspwmrc
echo -e "bspc rule -a Viewnior state=floating\nbspc rule -a Code desktop='^5'">>~/.config/bspwm/bspwmrc
# sudo pacman -S archlinux-wallpaper
cd ~
wget https://gitee.com/gjkevin/dfiles/attach_files/614579/download/wallpapers.tar.xz
sudo mkdir /usr/share/backgrounds 2>/dev/null
sudo tar xvJf wallpapers.tar.xz -C /usr/share/backgrounds
rm -rf wallpapers.tar.xz
sed -i "/picom/a\feh --randomize --bg-fill /usr/share/backgrounds/wallpapers &" ~/.config/bspwm/bspwmrc

#change grub and waiting time,wating time need to rebuild by the grub-mkconfig in the following scripts
sudo sed -r -i "s/(GRUB_TIMEOUT=)5/\11/" /etc/default/grub
tpack=Vimix-1080p
wget https://gitee.com/gjkevin/dfiles/attach_files/614780/download/vimixmod.tar.xz 
tar xvJf vimixmod.tar.xz
sudo cp -r $tpack/Vimix /boot/grub/themes
rm -rf Vimix-1080p vimixmod.tar.xz
sudo sed -i "/grub_lang=/a\GRUB_THEME=\"\/boot\/grub\/themes\/Vimix\/theme.txt\"" /etc/grub.d/00_header
sudo grub-mkconfig -o /boot/grub/grub.cfg
