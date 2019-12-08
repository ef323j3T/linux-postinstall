
#!/bin/bash
set -e
ZDOTDIR="$HOME/.local/dotfiles/zsh"
# http://unix.stackexchange.com/questions/136894/command-line-method-or-programmatically-add-ssh-key-to-github-com-user-account
# https://github.com/b4b4r07/ssh-keyreg/blob/master/bin/ssh-keyreg
# https://github.com/ABCanG/add-sshkey-remote

git_key() {
    local title="${USER}@${HOSTNAME}"
    local key_data="$(cat ~/.ssh/id_rsa.pub)"
    
   	read -rp "Enter the username of git account:" gitUser
   	read -s -rp "Enter the password of git account:" gitPass
    
    curl -u "${gitUser}:${gitPass}" \
    --data "{\"title\":\"$title\",\"key\":\"$key_data\"}" \
    https://api.github.com/user/keys
    
    local GIT_USER_DIR=~/.config/git/local
    local GIT_USER_FILE=${GIT_USER_DIR}/user
    mkdir -p ${GIT_USER_DIR} && touch ${GIT_USER_FILE}
    echo -e  "[user]\n     email = $gitMail\n     name = $gitUser" >> ${GIT_USER_FILE} ; }

check_git() {
    ssh -T git@github.com 2>&1 | grep "success"
    if [[ $? -ne 0 ]] ; then
        echo "error."
    fi ; }

deploy_dotfiles() {
    if [ ! -f ${HOME}/.local/dotfiles/deploy.zsh ] ; then
        git clone git@github.com:ef323j3T/dotfiles.git "${HOME}/.local/dotfiles"
    fi
    ./${HOME}.local/dotfiles/deploy.zsh ; }

clean_dotfiles () {
    if [ "$OSTYPE" -ne "darwin" ] ; then
        for files in "${MAC_ZSH_ARRAY[@]}" ; do
            rm -f "$files"
        done
    fi  ; }

install_packages() {
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
deploy_dotfiles
#clean_dotfiles
install_packages
#install_more
