#!/bin/bash
set -e

output_file="output.log"

print_status() { echo "$1" ; }

update_ubuntu(){
        #clear
        print_status "Updating Ubuntu"
        apt-get -y update
        apt-get -y update --fix-missing
        apt-get -y upgrade
        apt-get -y dist-upgrade
        apt-get clean
        apt-get autoclean
        apt-get -y autoremove ; }


install_tools(){
        clear
        print_status "Install Tools"
        apt-get -y  install git vim nano make gcc curl wget net-tools zsh ; }
