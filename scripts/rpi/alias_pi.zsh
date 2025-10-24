# aliases for th RPI. Use the commamd to copy to the custom dir. 
# cp alias_pi.zsh ~/.oh-my-zsh/custom/alias_pi.zsh 
#

alias up='sudo apt update && sudo apt upgrade -y'
alias h='cd ~'
alias vim="nvim"
alias vi="nvim"
alias v='vifm .'
alias mv="mv-iv"
alias cp="cp -riv"
alias mkdir="mkdir -vp"

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."



# Network analysis
alias myip="curl ifconfig.me"
alias ports="sudo netstat -tulpen"
alias speedtest="speedtest-cli"
alias pingg="ping -c 5 google.com"



