
# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin:$HOME/.local/bin"
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="robbyrussell"
#ZSH_THEME="agnoster"
plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

data_raw=`pass gossamer3/https:/fssfed.ge.com/fss|jq -r '.Data'`
data=`echo $data_raw|base64 -d`
user=`echo $data|jq -r '.Username'`
pass=`echo $data|jq -r '.Secret'`

bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char

alias tg='terragrunt'
alias tf='terraform'
alias aws='aws --profile'
alias ll='ls -al'
# alias ssh9='/usr/local/bin/ssh'

function awslogin() {
  for i in $@;do
    echo "login into $i;"
    gossamer3 login -a $i --username=$user --password=$pass --skip-prompt --force
#     if [[ $i=="ami-global" ]];then
#       aws "$i" sso login --sso-session "$i"
#     else
#       gossamer3 login -a $i --username=$user --password=$pass --skip-prompt --force
#     fi
  done
}

function awslg() {
        /usr/bin/gossamer3 bulk-login -a default --username=$user --password=$pass --skip-prompt ~/poweruser-roles.yaml
        # switch_profile
}
source ~/.zsh/func.sh

#export PYTHONSTARTUP=~/.pythonrc


# export PYENV_ROOT="$HOME/.pyenv"
# command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"
# source <(kubectl completion zsh)
# export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# flutter
# export PATH="$PATH:$HOME/tools/flutter/bin"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# __conda_setup="$('/home/fuin/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then
#     eval "$__conda_setup"
# else
#     if [ -f "/home/fuin/miniconda3/etc/profile.d/conda.sh" ]; then
#         . "/home/fuin/miniconda3/etc/profile.d/conda.sh"
#     else
#         export PATH="/home/fuin/miniconda3/bin:$PATH"
#     fi
# fi
# unset __conda_setup
# <<< conda initialize <<<

# export OLLAMA_MODELS="/mnt/e/models"
# export HF_HOME=/mnt/e/huggingface/cache/
# export HF_ENDPOINT=https://hf-mirror.com
#
# . "$HOME/.asdf/asdf.sh"
# # append completions to fpath
# fpath=(${ASDF_DIR}/completions $fpath)
# # initialise completions with ZSH's compinit
# autoload -Uz compinit && compinit

#export TERRAGRUNT_PROVIDER_CACHE_DIR=$HOME/.terraform.d/plugin-cache
#export TERRAGRUNT_PROVIDER_CACHE_DIR=$HOME/.terraform.d/plugins