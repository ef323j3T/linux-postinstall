
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
    https://api.github.com/user/keys
}


check_git() {
    ssh -T git@github.com 2>&1 | grep "success"
    if [[ $? -ne 0 ]] ; then
        echo "error. "
    fi
}


git_key
check_git
