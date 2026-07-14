# ~/.zshrc — general-purpose zsh config: Powerlevel10k + antidote + fzf + zoxide.
# Source lives in tdev/zsh/ — re-run tdev/install.sh after editing there.

# Enable Powerlevel10k instant prompt. Must stay near the top of this file.
# Anything that reads user input (password prompts, [y/n] confirmations, etc.)
# must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ---- Basic shell init ----
autoload -Uz compinit && compinit
autoload -Uz select-word-style && select-word-style bash

# ---- Antidote plugin manager ----
if [[ -f "$HOME/.antidote/antidote.zsh" ]]; then
  source "$HOME/.antidote/antidote.zsh"
  antidote load "$HOME/.zsh_plugins.txt"
fi

# ---- fzf ----
if command -v fzf >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --strip-cwd-prefix --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fdfind --type d --hidden --strip-cwd-prefix --exclude .git'
  export FZF_DEFAULT_OPTS='--height 60% --layout=reverse --border --preview-window=right:60%'
  command -v bat >/dev/null 2>&1 && export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :200 {}'"
  command -v eza >/dev/null 2>&1 && export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always {}'"

  # fzf >=0.48 ships its own shell integration; fall back to distro-shipped
  # paths (Arch/Debian differ) or the official installer's ~/.fzf.zsh.
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  else
    for f in /usr/share/fzf/key-bindings.zsh /usr/share/doc/fzf/examples/key-bindings.zsh; do
      [[ -f "$f" ]] && { source "$f"; break; }
    done
    for f in /usr/share/fzf/completion.zsh /usr/share/doc/fzf/examples/completion.zsh; do
      [[ -f "$f" ]] && { source "$f"; break; }
    done
    [[ -f "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"
  fi

  [[ -f "$HOME/.local/share/fzf-git/fzf-git.sh" ]] && source "$HOME/.local/share/fzf-git/fzf-git.sh"
fi

# ---- zoxide (after fzf) ----
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
  alias cd='z'   # `command cd` still works as an escape hatch
fi

# ---- History ----
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

# ---- Zsh options ----
setopt AUTO_CD              # cd by typing a directory name
setopt HIST_IGNORE_DUPS     # don't record duplicate commands
setopt SHARE_HISTORY        # share history between sessions
setopt APPEND_HISTORY       # append to history file

# ---- Defaults ----
export EDITOR=nvim
export LANG='en_US.UTF-8'

# ---- Aliases & functions ----
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# ---- Keybindings ----
bindkey -e
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[5D' backward-word
bindkey '^[[5C' forward-word

# ---- PATH ----
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ---- OS-specific config ----
case "$(uname -s)" in
  Linux*)  [[ -f "$HOME/.zshrc.linux" ]] && source "$HOME/.zshrc.linux" ;;
  Darwin*) [[ -f "$HOME/.zshrc.macos" ]] && source "$HOME/.zshrc.macos" ;;
esac

# ---- Powerlevel10k prompt ----
# Run `p10k configure` any time to regenerate ~/.p10k.zsh
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# ---- Version managers (each is a no-op if not installed) ----
if command -v pyenv >/dev/null 2>&1; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

if [[ -x "$HOME/miniconda3/bin/conda" ]]; then
  __conda_setup="$("$HOME/miniconda3/bin/conda" shell.zsh hook 2>/dev/null)"
  if [[ $? -eq 0 ]]; then
    eval "$__conda_setup"
  elif [[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]]; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
  else
    export PATH="$HOME/miniconda3/bin:$PATH"
  fi
  unset __conda_setup
fi

# bun completions
[ -s "/home/utsah/.bun/_bun" ] && source "/home/utsah/.bun/_bun"
