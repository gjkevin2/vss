#!/bin/bash
tee -a /opt/prompt_fish.sh >/dev/null <<\EOF
function _fish_collapsed_pwd() {
    local pwd="$1"
    local home="$HOME"
    local size=${#home}
    [[ $# == 0 ]] && pwd="$PWD"
    [[ -z "$pwd" ]] && return
    if [[ "$pwd" == "/" ]]; then
        echo "/"
        return
    elif [[ "$pwd" == "$home" ]]; then
        echo "~"
        return
    fi
    [[ "$pwd" == "$home/"* ]] && pwd="~${pwd:$size}"
    if [[ -n "$BASH_VERSION" ]]; then
        local IFS="/"
        local elements=($pwd)
        local length=${#elements[@]}
        for ((i=0;i<length-1;i++)); do
            local elem=${elements[$i]}
            if [[ ${#elem} -gt 1 ]]; then
                elements[$i]=${elem:0:1}
            fi
        done
    else
        local elements=("${(s:/:)pwd}")
        local length=${#elements}
        for i in {1..$((length-1))}; do
            local elem=${elements[$i]}
            if [[ ${#elem} > 1 ]]; then
                elements[$i]=${elem[1]}
            fi
        done
    fi
    local IFS="/"
    echo "${elements[*]}"
}

alias ls="ls --color"
if [ -n "$BASH_VERSION" ]; then
    if [ "$UID" -eq 0 ]; then
        export PS1='\u@\h \[\e[91m\]$(_fish_collapsed_pwd)\[\e[0m\]# '
    else
        export PS1='\u@\h \[\e[32m\]$(_fish_collapsed_pwd)\[\e[0m\]> '
    fi
else
    setopt prompt_subst
    if [ $UID -eq 0 ]; then
        export PROMPT='%f%n@%m %F{9}$(_fish_collapsed_pwd)%f# '
    else
        export PROMPT='%f%n@%m %F{2}$(_fish_collapsed_pwd)%f> '
    fi
fi
EOF

tee -a /etc/bash.bashrc >/dev/null <<-EOF
source /opt/prompt_fish.sh
EOF
echo -e "source /opt/prompt_fish.sh">>~/.bashrc
source ~/.bashrc