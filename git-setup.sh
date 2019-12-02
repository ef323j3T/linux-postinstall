
#!/bin/bash
set -e

#http://unix.stackexchange.com/questions/136894/command-line-method-or-programmatically-add-ssh-key-to-github-com-user-account
#https://github.com/b4b4r07/ssh-keyreg/blob/master/bin/ssh-keyreg
#https://github.com/ABCanG/add-sshkey-remote

git_key() {
    title="${USER}@${HOSTNAME}"
    key_data="$(cat ~/.ssh/id_rsa.pub)"
    
   	read -rp "Enter the username of git account:" gitUser
   	read -s -rp "Enter the password of git account:" gitPass
    
    curl -u "${gitUser}:${gitPass}" \
    --data "{\"title\":\"$title\",\"key\":\"$key_data\"}" \
    https://api.github.com/user/keys ; }


check_git() {
    ssh -T git@github.com 2>&1 | grep "success"
    if [[ $? -ne 0 ]] ; then
        echo "error. "
    fi ; }


clean() {
    rm ${HOME}/.bash*
    rm ${HOME}/.profile
    rm ${HOME}/.wget_hosts
    rm ${HOME}/.viminfo
    rm ${HOME}/.zcompdump
    rm ${HOME}/.zshrc ; }
    
    
deploy_dotfiles() {
    if [ ! -f ${HOME}/.local/dotfiles/deploy.zsh ] ; then
        git clone git@github.com:ef323j3T/d0tfiles.git "${HOME}/.local/dotfiles"
    fi
    echo "Deploy dotfiles?"
    select yn in "Yes" "No"; do
    case $yn in
        Yes ) ${HOME}/.local/dotfiles/deploy.zsh ;;
        No ) exit ;;
    esac
    done ; }
    
    
clean_dotfiles () {    
    if [ "$OSTYPE" -ne "darwin" ] ; then
        rm ${HOME}/.local/dotfiles/zsh/zshrc.d/aliases/chrome.zsh
        rm ${HOME}/.local/dotfiles/zsh/zshrc.d/aliases/j=jump.zsh
         rm ${HOME}/.local/dotfiles/zsh/zshrc.d/aliases/ff=find-fast.zsh
    fi  ; }


install_base_packages() {
    sudo apt-get -y install apt-transport-https ca-certificates \
        dirmngr dnsutils fd-find lsb-release less llvm liblzma-dev libffi-dev \
        libncurses5-dev libncursesw5-dev libssl-dev libbz2-dev libreadline-dev libsqlite3-dev \
        libreadline-gplv2-dev libpam0g-dev \
        "make" openssh-client perl python-openssl \
        silversearcher-ag software-properties-common snapd \
        tk-dev tmux xz-utils zlib1g-dev zip unzip ; }
        
install_more() {
    cargo install exa ; }


git_key
check_git
clean
deploy_dotfiles
clean_dotfiles
install_base_packages
install_more
