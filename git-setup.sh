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
	read -rp "Enter the password of git account:" gitPass

	curl -u "${gitUser}:${gitPass}" --data "{\"title\":\"$title\",\"key\":\"$key_data\"}" \
		https://api.github.com/user/keys

	local GIT_USER_DIR=~/.config/git/local
		local GIT_USER_FILE=${GIT_USER_DIR}/user
		mkdir -p ${GIT_USER_DIR} && touch ${GIT_USER_FILE}
		echo -e  "[user]\n     email = $gitMail\n     name = $gitUser" >> ${GIT_USER_FILE}
}



check_git() {
	ssh -T git@github.com 2>&1 | grep "success"
	if [[ $? -ne 0 ]] ; then
		echo "error."
	fi
}


deploy_dotfiles() {
	if [ ! -f ${HOME}/.local/dotfiles/deploy.zsh ] ; then
		git clone git@github.com:ef323j3T/dotf.git "${HOME}/.local/dotfiles"
	fi
	${HOME}/.local/dotfiles/deploy.zsh
}


clean_dotfiles () {
	if [ "$OSTYPE" -ne "darwin" ] ; then
		for files in "${MAC_ZSH_ARRAY[@]}" ; do
			rm -f "$files"
		done
	fi
}


install_packages() {
    	sudo apt-get -y install \
	    	apt-transport-https \
#			bat \
	    	build-essential \
	    	ca-certificates \
	       	dirmngr \
	       	dnsutils \
	       	fd-find \
	       	lsb-release \
	       	less \
  	     	llvm \
   	    	liblzma-dev libffi-dev libncurses5-dev libncursesw5-dev libssl-dev libbz2-dev \
   	    	libreadline-dev libsqlite3-dev libreadline-gplv2-dev libpam0g-dev \
  	     	net-tools \
  	     	make \
  	     	openssh-client \
			packagekit-command-not-found  \
    	   	perl \
    	   	python-openssl \
    	   	python3-pip \
       		silversearcher-ag \
       		software-properties-common \
       		snapd \
      	 	thefuck \
      	 	tk-dev \
      	 	tmux \
      	 	unzip \
       		vim-nox \
       		xclip \
			xsel \
   	    	xz-utils \
   	    	zlib1g-dev \
   	    	zip
}



install_more() {
	#jump
	wget https://github.com/gsamokovarov/jump/releases/download/v0.23.0/jump_0.23.0_amd64.deb
	sudo dpkg -i jump_0.23.0_amd64.deb
	rm jump_0.23.0_amd64.deb

	#cargo/rust
	export CARGO_HOME="$XDG_DATA_HOME/cargo"
	export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
	export PATH="$CARGO_HOME/bin:$PATH"
	export COMPDIR="${ZDOTDIR}/zshenv.d/completions"

	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
	#rustup completions zsh cargo > /usr/local/share/zsh-completions/_cargo
	whereis rustc
	rustup completions zsh cargo > ${COMPDIR}/_cargo
	rustup completions zsh > ${COMPDIR}/_rustup

   	cargo install exa

	wget https://github.com/sharkdp/bat/releases/download/v0.12.1/bat_0.12.1_amd64.deb
	sudo dpkg -i bat_0.12.1_amd64.deb
	rm bat_0.12.1_amd64.deb

}



function clean() {
	for f in .profile .bash_logout .bashrc .viminfo .wget-hsts .zcompdump .zshrc
		if [[ -e $f ]] ; then
			rm $f
		fi
	done
}

git_key
#check_git
deploy_dotfiles
clean_dotfiles
install_packages
install_more
clean
