#!/bin/bash
cp prompt_fish.sh /opt
tee -a /etc/bash.bashrc >/dev/null <<-EOF
source /opt/prompt_fish.sh
EOF
echo -e "source /opt/prompt_fish.sh">>~/.bashrc
source ~/.bashrc