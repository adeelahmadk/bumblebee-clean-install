#!/bin/bash

# #################################################
# Script: 		  bumblebee_fix.sh       						#
# Version:		  0.1a				  		                #
# Author:		    codegenki		                      #
# Date:			    Jan 15, 2018				              #
# Usage:		    bumblebee_fix <driver-number>     #
# Description: 	Bash script to patch bymblebee    #
#               and nvidia driver           	    #
# Dependencies: bumblebee-nvidia nvidia-xxx       #
# Platform:     Ubuntu (test for Xenial x64)      #
# #################################################

print_usage() {
	echo "Usage: `basename $0` <driver-number>"
	echo "Try '`basename $0` --help' for more information."
}

print_help() {
	echo "Usage: `basename $0` <driver-number>"
	echo "Patches bumblebee config files for installed nvidia driver"
	echo "  <driver-number>    Number of the installed nvidia driver, e.g. 38x"
  echo
}

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;36m"
NORMAL="\033[0m"

if [[ $(id -u) -ne 0 ]]; then
  echo "root permissions required!"
  exit 1
fi

if [ "$#" -ne 1 ]; then
	print_usage
	exit 1
elif [ "$#" -eq 1 ] && [ "$1" = "--help" ]; then
	print_help
	exit 0
else
  NUM=$(echo $1 | grep -o '[1-9]\{1\}[0-9]\{1\}[0-9]\{1\}')

  if [ "$NUM" = "" ]; then
    printf "${RED}%s${NORMAL}\n" "Incorrect driver number!"
    #echo "Incorrect driver number!"
    exit 1
  fi

  printf "${YELLOW}%s${NORMAL}\n" "Nvidia Bumblebee setup for Ubuntu 16.04 LTS and variants"

  echo
  printf "${GREEN}%s${NORMAL}\n" "What's expected of you:"
  printf "${BLUE}%s${NORMAL}\n" "  - Added repos for graphics drivers and bumblebee"
  printf "${BLUE}%s${NORMAL}\n" "  - nouveau driver removed completely"
  printf "${BLUE}%s${NORMAL}\n" "  - Installed bumblebee-nvidia and nvidia-xxx"
  printf "${GREEN}%s${NORMAL}\n" "What this script will do:"
  printf "${BLUE}%s${NORMAL}\n" "  - Blacklist nouveau driver"
  printf "${BLUE}%s${NORMAL}\n" "  - Update bumblebee config"
  printf "${BLUE}%s${NORMAL}\n" "  - Interactively set GL provider"
  printf "${BLUE}%s${NORMAL}\n" "  - Disable gpu-manager"
  printf "${BLUE}%s${NORMAL}\n" "  - Rebuild bbswitch and nvidia modules"
  echo
  echo

  echo -n "Sure you want to continue? [Y|N]: "
  read choice
  if [ $choice != "y" ] || [ $choice != "Y" ]; then
  	exit 0
  fi

  printf "\n${BLUE}%s${NORMAL}\n" "> Blacklisting nouveau driver:"
  echo

  cp /etc/modprobe.d/bumblebee.conf /etc/modprobe.d/bumblebee.conf.old
  echo "" >> /etc/modprobe.d/bumblebee.conf
  echo "blacklist nvidia-$NUM" >> /etc/modprobe.d/bumblebee.conf
  echo "blacklist nvidia-$NUM-updates" >> /etc/modprobe.d/bumblebee.conf
  echo "blacklist nvidia-experimental-$NUM" >> /etc/modprobe.d/bumblebee.conf

  printf "\n${BLUE}%s${NORMAL}\n" "> Updating bumblebee config"

  cp /etc/bumblebee/bumblebee.conf /etc/bumblebee/bumblebee.conf.old
  sed -i.bak 's/^\(Driver=\).*/\1nvidia/' /etc/bumblebee/bumblebee.conf
  sed -i.bak "s/^\(KernelDriver=\).*/\1nvidia-$NUM/" /etc/bumblebee/bumblebee.conf
  sed -i.bak "s/^\(LibraryPath=\).*/\1\/usr\/lib\/nvidia-$NUM:\/usr\/lib32\/nvidia-$NUM/" /etc/bumblebee/bumblebee.conf
  sed -i.bak "s/^\(XorgModulePath=\).*/\1\/usr\/lib\/nvidia-$NUM\/xorg,\/usr\/lib\/xorg\/modules/" /etc/bumblebee/bumblebee.conf
  echo "Patched bumblebee conf"

  printf "\n${BLUE}%s${NORMAL}\n" "> Let's set GL provider:"

  echo "set i386 gl provider to mesa!"
  echo
  update-alternatives --config i386-linux-gnu_gl_conf

  echo "set egl provider to mesa!"
  echo
  update-alternatives --config x86_64-linux-gnu_egl_conf

  echo "set x86_64 gl provider to mesa!"
  echo
  update-alternatives --config x86_64-linux-gnu_gl_conf

  printf "\n${BLUE}%s${NORMAL}\n" "> Disabling gpu-manager:"
  cp /etc/default/grub /etc/default/grub.old
  sed -i.bak 's/^\(GRUB_CMDLINE_LINUX="\).*/\1nogpumanager"/' /etc/default/grub
  echo "Patched /etc/default/grub"
  echo "Updating grub:"
  echo
  update-grub

  printf "\n${BLUE}%s${NORMAL}\n" "> Rebuilding bbswitch and nvidia modules:"
  dpkg-reconfigure bbswitch-dkms
  dpkg-reconfigure "nvidia-$NUM"

  printf "\n${GREEN}%s${NORMAL}\n" "Done patching bumblebee and nvidia driver."
  printf "\n${BLUE}%s${NORMAL}\n" "Restarting computer..."

  reboot
fi
