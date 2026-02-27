export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="bureau"

export PATH="/usr/lib/qt6/bin:$PATH"
export MPD_HOST="$HOME/.config/mpd/socket"

plugins=(
  git
  sudo
  colored-man-pages
  command-not-found
  history-substring-search
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

HISTSIZE=50000
SAVEHIST=50000
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

alias man='qman'
alias yay='paru'
alias vim='nvim'
alias vi='nvim'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -pv'
alias df='df -h'
alias du='du -h'
alias free='free -h'

nvdots() {
  command nvim +"lua vim.schedule(function()
    local keys = vim.api.nvim_replace_termcodes('<Space>e', true, false, true)
    vim.api.nvim_feedkeys(keys, 'm', false)
  end)" ~/dotfiles/archlinux/home.nix
}
alias dfn='nvdots'

alias hms='home-manager switch --flake ~/dotfiles/archlinux'
alias ncdum='sudo ncdu --exclude /mnt /'

y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

if command -v fzf >/dev/null 2>&1; then
    source /usr/share/fzf/key-bindings.zsh
    source /usr/share/fzf/completion.zsh
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

export EDITOR=nvim
export VISUAL=nvim

setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

export PATH="$HOME/.local/bin:$PATH"
export PATH=$PATH:/home/drama/.spicetify
export PATH="$HOME/.local/share/npm-global/bin:$HOME/.local/bin:$PATH"
