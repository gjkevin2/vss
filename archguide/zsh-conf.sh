#!/bin/bash
cd /opt
if [ ! -e "prompt_fish.sh" ];then
    sudo wget https://gitee.com/gjkevin/dfiles/raw/master/prompt_fish.sh
fi
sudo pacman -S --noconfirm zsh
if [ ! -e ~/pwd ];then
    chsh -s /usr/bin/zsh
else
    echo $(cat ~/pwd)|chsh -s /usr/bin/zsh
fi
# prompt
echo -e "source /opt/prompt_fish.sh"|sudo tee -a /etc/zsh/zshrc >/dev/null

#comments
echo -e "setopt INTERACTIVE_COMMENTS"|sudo tee -a /etc/zsh/zshrc >/dev/null

#plugins
sudo pacman -S --noconfirm zsh-syntax-highlighting
echo -e "source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"|sudo tee -a /etc/zsh/zshrc >/dev/null
sudo pacman -S --noconfirm zsh-autosuggestions
echo -e "source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"|sudo tee -a /etc/zsh/zshrc >/dev/null

#some wrong keys
sudo tee -a /etc/zsh/zshrc>/dev/null<<-EOF
# key bindings
bindkey "\e[1~" beginning-of-line
bindkey "\e[4~" end-of-line
bindkey "\e[5~" beginning-of-history
bindkey "\e[6~" end-of-history
bindkey "\e[3~" delete-char
bindkey "\e[2~" quoted-insert
bindkey "\e[5C" forward-word
bindkey "\eOc" emacs-forward-word
bindkey "\e[5D" backward-word
bindkey "\eOd" emacs-backward-word
bindkey "\ee[C" forward-word
bindkey "\ee[D" backward-word
bindkey "^H" backward-delete-word
# for rxvt
bindkey "\e[8~" end-of-line
bindkey "\e[7~" beginning-of-line
# for non RH/Debian xterm, can't hurt for RH/DEbian xterm
bindkey "\eOH" beginning-of-line
bindkey "\eOF" end-of-line
# for freebsd console
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line
# completion in the middle of a line
bindkey '^i' expand-or-complete-prefix
EOF