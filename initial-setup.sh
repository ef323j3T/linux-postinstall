#!/bin/bash
set -e

TIMESTAMP=$(date +%d/%m/%y-%T)

LOGDIR=/var/log/custom
LOGFILE=${LOGDIR}/sysinit.log

if [ -f ${LOGFILE} ] ; then
	source ${LOGFILE}
fi

# https://github.com/jasonheecs/ubuntu-server-
# setup/blob/3e02daa9420f2ef0c24ccc560aa28df32
# 2e314d0/setupLibrary.sh

function print_status() { echo "$1" ; }

function addUserAccount() {
# Add the new user account. Args: 'Username', 'password'. Flag to determine if user account is added silently. (With / Without GECOS prompt)
    	local username="${1}"
    	local password="${2}"
    	local silent_mode="${3}"
    	if [[ ${silent_mode} == "true" ]]; then
        	sudo adduser --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password --gecos '' "${username}"
    	else
        	sudo adduser --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password "${username}"
    	fi
    	echo "${username}:${password}" | sudo chpasswd
    	sudo usermod -aG sudo "${username}" ; }

function addSSHKey() {
# Add the local machine public SSH Key for the new user account. Args: 'username', 'public ssh key'
	local username="${1}"
    	local sshKey="${2}"
    	local gitMail="${3}"
    	execAsUser "${username}" "mkdir -p ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys"
    	execAsUser "${username}" "echo \"${sshKey}\" | sudo tee -a ~/.ssh/authorized_keys"
    	execAsUser "${username}" "chmod 600 ~/.ssh/authorized_keys"
    	execAsUser "${username}" "ssh-keygen -t rsa -b 4096 -C '${gitMail}' -N '' -f ~/.ssh/id_rsa" ; }

function execAsUser() {
# Execute a command as a certain user. Args: 'username', 'command to be executed'
    	local username="${1}"
    	local exec_command="${2}"
    	sudo -u "${username}" -H bash -c "${exec_command}" ; }

function disableSudoPassword() {
# Disables the sudo password prompt for a user account by editing /etc/sudoers. Args: 'username'
    	local username="${1}"
    	sudo cp /etc/sudoers /etc/sudoers.bak
    	sudo bash -c "echo '${1} ALL=(ALL) NOPASSWD: ALL' | (EDITOR='tee -a' visudo)" ; }

function revertSudoers() {
# Reverts the original /etc/sudoers file before this script is ran
	sudo cp /etc/sudoers.bak /etc/sudoers
    	sudo rm -rf /etc/sudoers.bak ; }

function logTimestamp() {
	sed -i 's|'${1}'=.*|'${1}'='${TIMESTAMP}'|g' $LOGFILE ; }

function setTimezone() {
# Set the machines timezone. Args: 'tz data times'
    local timezone="${1}"
    echo "${1}" | sudo tee /etc/timezone
    sudo ln -fs "/usr/share/zoneinfo/${timezone}" /etc/localtime # https://bugs.launchpad.net/ubuntu/+source/tzdata/+bug/1554806
    sudo dpkg-reconfigure -f noninteractive tzdata ; }

function setupTimezone() {
# Set the machine's timezone. Args: 'tz data timezone'
    timezone="Australia/Sydney"
    setTimezone "${timezone}" ; }

function promptForPassword() {
#Keep prompting for the password and password confirmation
   PASSWORDS_MATCH=0
   while [ "${PASSWORDS_MATCH}" -eq "0" ] ; do
       read -s -rp "Enter new UNIX password:" password
       printf "\n"
       read -s -rp "Retype new UNIX password:" password_confirmation
       printf "\n"

       if [[ "${password}" != "${password_confirmation}" ]] ; then
           echo "Passwords do not match! Please try again."
       else
           PASSWORDS_MATCH=1
       fi
   done ; }



set_log() {
	if [ ! -d ${LOGDIR} ] ; then
		mkdir ${LOGDIR}
		chmod -R 755 ${LOGDIR}
	fi
	touch ${LOGFILE}
	chmod 755 ${LOGFILE}
	echo -e "SETLOGTS='foo'\nUPDATETS='foo'\nINSTALLTS='foo'\nMAINTS='foo'\nTIMETS='foo'\nCLEANTS='foo'\nFIXTS='foo'" > ${LOGFILE}
	logTimestamp "SETLOGTS" ; }


update_ubuntu(){
        #clear
        print_status "Updating Ubuntu"
        apt-get -y update
        apt-get -y update --fix-missing
        apt-get -y upgrade
        apt-get -y dist-upgrade
	logTimestamp "UPDATETS" ; }


install_tools(){
        clear
        print_status "Install Tools"
        apt-get -y  install build-essential git ntp vim nano make perl gcc curl wget net-tools zsh
	logTimestamp "INSTALLTS" ; }


run_main() {
    	read -rp "Enter the username of the new user account:" username
    	promptForPassword
    	read -rp "Enter the mail of git account:" gitmail
    	
	addUserAccount "${username}" "${password}"
	
   	read -rp $'Paste in the public SSH key for the new user:\n' sshKey
    	echo 'Running setup script...'
	
    	disableSudoPassword "${username}"
    	addSSHKey "${username}" "${sshKey}" "${gitmail}"
	logTimestamp "MAINTS" ; }


run_time() {
    	timezone="Australia/Sydney"
    	setTimezone "${timezone}"
	logTimestamp "TIMETS" ; }


run_clean() {
	sudo service ssh restart
   	echo "Setup Done!"
	apt-get clean
        apt-get autoclean
        apt-get -y autoremove
	for f in .bash* .wget* .profile* .vim* ; do
	        if [ -f ${f} ] ; then
			rm $f
		fi
	done
	logTimestamp "CLEANTS" ; }


run_fix(){
	#if $username var isn't defined run prompt
        if [ -z "${username}" ] ; then
	        read -rp "Enter the username of the new user account:" username
        fi

	#add $username to sudo
	adduser ${username} sudo

	#check git-setup.sh exists in $username home folder
        if [ ! -f /home/${username}/git-setup.sh ] ; then
		execAsUser ${username} "wget https://github.com/ef323j3T/linux-postinstall/raw/master/git-setup.sh -P /home/${username} && chmod +x /home/${username}/git-setup.sh"
        fi

	#change default shell
	usermod -s /usr/bin/zsh ${username}
        execAsUser ${username} "chsh -s $(which zsh)"

	#change to user
	cd /home/${username}
	touch /home/${username}/.zshrc

	logTimestamp "FIXTS"

	su ${username} ; }


set_log
update_ubuntu
install_tools
run_main
run_time
run_clean
run_fix

