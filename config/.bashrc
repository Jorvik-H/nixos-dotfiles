#
# ~/.bashrc
# ┌ └

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

#alias ls='ls -lh --color=auto'
alias update='git add . && git commit -m "update" && git push'
alias ls='eza -l'
alias grep='grep --color=auto'
alias nrs='nixos-rebuild switch'
alias config='cd ~/nixos-dotfiles/config && eza -l'
#PS1='[\u@\h \W]\$ '

export BROWSER='/usr/sbin/librewolf'
export EDITOR='nvim'
export VISUAL='nvim'
export BROWSER='librewolf'
echo "$(fortune | cowsay)"
#PS1='╭─$(pwd)
#╰─><>'
PS1='╭─[\[\e[94m\]$(pwd)\e[0m\]]
╰─><>'

cursor_styles="\e[?
${cursor_style_full_block};c"
