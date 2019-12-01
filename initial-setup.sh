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
        apt-get -y  install build-essential git vim nano make perl gcc curl wget net-tools zsh ; }


function addUserAccount() {
# Add the new user account. Args: 'Username', 'password'. Flag to determine if user account is added silently. (With / Without GECOS prompt)
    	local username=${1}
    	local password=${2}
    	local silent_mode=${3}
    	if [[ ${silent_mode} == "true" ]]; then
        	sudo adduser  --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password --gecos '' "${username}"
    	else
        	sudo adduser  --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password "${username}"
    	fi
    	echo "${username}:${password}" | sudo chpasswd
    	sudo usermod -aG sudo "${username}" ; }


function addSSHKey() {
# Add the local machine public SSH Key for the new user account. Args: 'username', 'public ssh key'
	local username=${1}
    	local sshKey=${2}
    	local GITMAIL=${3}
	local GITUSER=${4}
	local GITPASS=${5}

    	execAsUser "${username}" "mkdir -p ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys"
    	execAsUser "${username}" "echo \"${sshKey}\" | sudo tee -a ~/.ssh/authorized_keys"
    	execAsUser "${username}" "chmod 600 ~/.ssh/authorized_keys"
    	execAsUser "${username}" "ssh-keygen -t rsa -b 4096 -C '${GITMAIL}' -N '' -f ~/.ssh/id_rsa" ; }


function execAsUser() {
# Execute a command as a certain user. Args: 'username', 'command to be executed'
    	local username=${1}
    	local exec_command=${2}
    	sudo -u "${username}" -H bash -c "${exec_command}" ; }


function setTimezone() {
# Set the machines timezone. Args: 'tz data timezone'
    	local timezone=${1}
    	echo "${1}" | sudo tee /etc/timezone
    	sudo ln -fs "/usr/share/zoneinfo/${timezone}" /etc/localtime
    	sudo dpkg-reconfigure -f noninteractive tzdata ; }
       
       
function configureNTP() { 
# Configure Network Time Protocol
    	sudo apt-get update
    	sudo apt-get --assume-yes install ntp ; }


function disableSudoPassword() { 
# Disables the sudo password prompt for a user account by editing /etc/sudoers. Args: 'username'
    	local username="${1}"
    	sudo cp /etc/sudoers /etc/sudoers.bak
    	sudo bash -c "echo '${1} ALL=(ALL) NOPASSWD: ALL' | (EDITOR='tee -a' visudo)" ; }


function revertSudoers() {
# Reverts the original /etc/sudoers file before this script is ran
    	sudo cp /etc/sudoers.bak /etc/sudoers
    	sudo rm -rf /etc/sudoers.bak ; }


function cleanup() {
    if [[ -f "/etc/sudoers.bak" ]]; then
        revertSudoers
    fi ; }

function logTimestamp() {
    local filename=${1}
    {
        echo "==================="
        echo "Log generated on $(date)"
        echo "==================="
    } >>"${filename}" 2>&1 ; }


function setupTimezone() {
    timezone="Australia/Sydney"
    setTimezone "${timezone}"
    echo "Timezone is set to $(cat /etc/timezone)" >&3 ; }


function promptForPassword() {
#Keep prompting for the password and password confirmation
   PASSWORDS_MATCH=0
   while [ "${PASSWORDS_MATCH}" -eq "0" ]; do
       read -s -rp "Enter new UNIX password:" password
       printf "\n"
       read -s -rp "Retype new UNIX password:" password_confirmation
       printf "\n"
       if [[ "${password}" != "${password_confirmation}" ]]; then
           echo "Passwords do not match! Please try again."
       else
           PASSWORDS_MATCH=1
       fi
   done ; }


run_main() {
    	read -rp "Enter the username of the new user account:" username
    	promptForPassword
    	read -rp "Enter the mail of git account:" gitmail

    	addUserAccount "${username}" "${password}"

   	read -rp $'Paste in the public SSH key for the new user:\n' sshKey
    	echo 'Running setup script...'
    	logTimestamp "${output_file}"

    	exec 3>&1 >>"${output_file}" 2>&1
    	disableSudoPassword "${username}"
    	addSSHKey "${username}" "${sshKey}" ; }

run_time() {
    	setupTimezone
 	echo "Installing Network Time Protocol... " >&3
    	configureNTP ; }

run_clean() {
	sudo service ssh restart
   	cleanup
   	echo "Setup Done!"
	rm $output_file ; }


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
	
	#changee default shell
	usermod -s /usr/bin/zsh ${username}
        execAsUser ${username} "chsh -s $(which zsh)"
        
	cd /home/${username}
	touch /home/${username}/.zshrc

	su ${username} ; }


update_ubuntu
install_tools
run_main
run_time
run_clean
run_fix

