#!/bin/bash

# make changes to ssh
wget "https://raw.githubusercontent.com/LungTaS/linux_script/main/ssh_change.sh" -O "/tmp/script_ssh.sh"
chmod 744 /tmp/script_ssh.sh
bash /tmp/script_ssh.sh