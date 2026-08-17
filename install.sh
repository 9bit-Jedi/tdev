#!/usr/bin/env bash
# tdev installer — symlinks every config in this repo into place.
# Safe to re-run: already-correct symlinks are skipped, anything else in the
# way gets backed up first. Prompts before touching each tool so you can
# skip what you don't want.
set -uo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.tdev-backup-$(date +%Y%m%d-%H%M%S)"
YES_TO_ALL=0
[ "${1:-}" = "-y" ] && YES_TO_ALL=1

log()  { printf '  \033[36m->\033[0m %s\n' "$1"; }
ok()   { printf '  \033[32m\xe2\x9c\x93\033[0m %s\n' "$1"; }
skip() { printf '  \033[90m\xc2\xb7\033[0m %s (already linked)\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }

confirm() {
  [ "$YES_TO_ALL" = 1 ] && return 0
  printf '\033[1m%s\033[0m [Y/n] ' "$1"
  read -r reply
  [ -z "$reply" ] || [ "$reply" = "y" ] || [ "$reply" = "Y" ]
}

# link <source-in-tdev> <target-path>
link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
    skip "$dest"
    return 0
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dest" "$BACKUP_DIR/$(basename "$dest")-$(date +%s)"
    log "backed up existing $dest -> $BACKUP_DIR"
  fi

  ln -s "$src" "$dest"
  ok "$dest -> $src"
}

# clone_if_missing <url> <target-dir>
clone_if_missing() {
  local url="$1" dest="$2"
  if [ -d "$dest/.git" ]; then
    skip "$dest"
    return 0
  fi
  log "cloning $url -> $dest"
  git clone --depth 1 "$url" "$dest"
  ok "cloned $dest"
}

section() { printf '\n\033[1;35m== %s ==\033[0m\n' "$1"; }

# detect_os -> arch | debian | fedora | unknown
detect_os() {
  if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    case " ${ID:-} ${ID_LIKE:-} " in
      *arch*)   echo arch ;;
      *debian*|*ubuntu*) echo debian ;;
      *fedora*|*rhel*) echo fedora ;;
      *) echo unknown ;;
    esac
  else
    echo unknown
  fi
}
OS_FAMILY="$(detect_os)"

# install_system_pkgs <pkg> [pkg ...] — installs one at a time (per OS_FAMILY)
# so one bad/missing package name doesn't block the rest.
install_system_pkgs() {
  local pkg
  if [ "$OS_FAMILY" = debian ] && [ -z "${APT_UPDATED:-}" ]; then
    log "apt-get update"
    sudo apt-get update -qq && APT_UPDATED=1
  fi
  for pkg in "$@"; do
    case "$OS_FAMILY" in
      arch)   sudo pacman -S --needed --noconfirm "$pkg" ;;
      debian) sudo apt-get install -y "$pkg" ;;
      fedora) sudo dnf install -y "$pkg" ;;
      *) warn "unrecognized distro — install '$pkg' manually"; continue ;;
    esac || warn "failed to install '$pkg' — install it manually"
  done
}

# ---------------------------------------------------------------------------
section "system packages (used by aliases, tmux, zsh, nvim configs)"
if confirm "Install core CLI tools via your package manager ($OS_FAMILY)?"; then
  case "$OS_FAMILY" in
    arch)
      install_system_pkgs git curl unzip ripgrep base-devel fontconfig \
        neovim tmux zsh eza bat fd fzf xclip net-tools
      ;;
    debian)
      install_system_pkgs git curl unzip ripgrep build-essential fontconfig \
        neovim tmux zsh eza bat fd-find fzf xclip net-tools
      ;;
    fedora)
      install_system_pkgs git curl unzip ripgrep gcc make fontconfig \
        neovim tmux zsh eza bat fd-find fzf xclip net-tools
      ;;
    *)
      warn "Unrecognized distro — install manually: git curl unzip ripgrep a C toolchain (gcc+make) fontconfig neovim tmux zsh eza bat fd fzf xclip net-tools"
      ;;
  esac
else
  skip "system packages"
fi

# ---------------------------------------------------------------------------
section "Nerd Font (icons for p10k, eza --icons, nvim UI plugins)"
if confirm "Install MesloLGS Nerd Font?"; then
  FONT_DIR="$HOME/.local/share/fonts/MesloNerdFont"
  if ls "$FONT_DIR"/*.ttf >/dev/null 2>&1; then
    skip "$FONT_DIR"
  else
    mkdir -p "$FONT_DIR"
    TMP_ZIP="$(mktemp)"
    log "downloading Meslo Nerd Font"
    if curl -fLo "$TMP_ZIP" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip; then
      unzip -oq "$TMP_ZIP" -d "$FONT_DIR"
      rm -f "$TMP_ZIP"
      command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$FONT_DIR" >/dev/null 2>&1
      ok "installed Meslo Nerd Font -> $FONT_DIR"
    else
      warn "font download failed — install a Nerd Font manually (https://www.nerdfonts.com)"
      rm -f "$TMP_ZIP"
    fi
  fi
  warn "Set your terminal emulator's font to 'MesloLGS NF' (or another Nerd Font) for icons to render correctly"
else
  skip "nerd font"
fi

# ---------------------------------------------------------------------------
section "zsh (antidote, p10k)"
if confirm "Install zsh config?"; then
  # Standard zsh layout: no ZDOTDIR redirect, everything lives in $HOME
  # (this is what Ubuntu/most distros assume out of the box).
  link "$BASE/zsh/.zshrc"           "$HOME/.zshrc"
  link "$BASE/zsh/zshrc.linux"      "$HOME/.zshrc.linux"
  link "$BASE/zsh/zshrc.macos"      "$HOME/.zshrc.macos"
  link "$BASE/zsh/.zsh_plugins.txt" "$HOME/.zsh_plugins.txt"
  link "$BASE/zsh/p10k/.p10k.zsh"   "$HOME/.p10k.zsh"
  clone_if_missing https://github.com/mattmc3/antidote.git "$HOME/.antidote"
  command -v zsh >/dev/null 2>&1 || warn "zsh not found on PATH — install it first"
else
  skip "zsh"
fi

# ---------------------------------------------------------------------------
section "tmux (tpm + plugins)"
if confirm "Install tmux config?"; then
  TMUX_DIR="$HOME/.config/tmux"
  mkdir -p "$TMUX_DIR"
  link "$BASE/tmux/tmux.conf" "$TMUX_DIR/tmux.conf"
  clone_if_missing https://github.com/tmux-plugins/tpm.git "$TMUX_DIR/plugins/tpm"
  if [ -x "$TMUX_DIR/plugins/tpm/bin/install_plugins" ]; then
    log "installing tmux plugins via tpm"
    "$TMUX_DIR/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 || warn "tpm plugin install failed, run prefix+I inside tmux"
    ok "tmux plugins installed"
  fi
  command -v xclip >/dev/null 2>&1 || warn "xclip not found — needed for tmux-yank clipboard support"
else
  skip "tmux"
fi

# ---------------------------------------------------------------------------
section "nvim"
if confirm "Install nvim config?"; then
  NVIM_DIR="$HOME/.config/nvim"
  mkdir -p "$NVIM_DIR"
  link "$BASE/nvim/init.lua"       "$NVIM_DIR/init.lua"
  link "$BASE/nvim/lazy-lock.json" "$NVIM_DIR/lazy-lock.json"
  link "$BASE/nvim/snippets"       "$NVIM_DIR/snippets"
  command -v nvim >/dev/null 2>&1 || warn "nvim not found on PATH — install Neovim first"
  log "lazy.nvim bootstraps itself and installs plugins on first nvim launch"
else
  skip "nvim"
fi

# ---------------------------------------------------------------------------
section "shell aliases & functions"
if confirm "Install .aliases?"; then
  link "$BASE/aliases/.aliases" "$HOME/.aliases"
  for tool in eza batcat fdfind rg fzf docker git; do
    command -v "$tool" >/dev/null 2>&1 || warn "'$tool' not found on PATH (used by .aliases)"
  done
else
  skip "aliases"
fi

# ---------------------------------------------------------------------------
section "fzf (fzf-git.sh)"
if confirm "Install fzf-git.sh?"; then
  clone_if_missing https://github.com/junegunn/fzf-git.sh.git "$HOME/.local/share/fzf-git"
  command -v fzf >/dev/null 2>&1 || warn "fzf not found on PATH — install it first"
else
  skip "fzf"
fi

# ---------------------------------------------------------------------------
# claude code and agy setups temporarily disabled — re-enable by removing
# the ": <<'DISABLED'" / "DISABLED" wrapper lines below.
: <<'DISABLED'
section "claude code (settings, statusline, commands)"
if confirm "Install Claude Code config?"; then
  link "$BASE/claude/settings.json"  "$HOME/.claude/settings.json"
  link "$BASE/claude/statusline.sh"  "$HOME/.claude/statusline.sh"
  mkdir -p "$HOME/.claude/commands"
  for f in "$BASE"/claude/commands/*.md; do
    link "$f" "$HOME/.claude/commands/$(basename "$f")"
  done
else
  skip "claude"
fi

# ---------------------------------------------------------------------------
section "agy (Antigravity CLI)"
if confirm "Install Antigravity CLI (agy) config?"; then
  link "$BASE/agy/settings.json"    "$HOME/.gemini/antigravity-cli/settings.json"
  link "$BASE/agy/keybindings.json" "$HOME/.gemini/antigravity-cli/keybindings.json"
else
  skip "agy"
fi
DISABLED

# ---------------------------------------------------------------------------
section "claude skills"
if confirm "Install Claude Code skills?"; then
  mkdir -p "$HOME/.claude/skills"
  for d in "$BASE"/skills/*/; do
    name="$(basename "$d")"
    link "$d" "$HOME/.claude/skills/$name"
  done
else
  skip "skills"
fi

# ---------------------------------------------------------------------------
section "bin (tmux-sessionizer)"
if confirm "Install bin scripts?"; then
  mkdir -p "$HOME/.local/bin"
  link "$BASE/bin/tmux-sessionizer" "$HOME/.local/bin/tmux-sessionizer"
  chmod +x "$BASE/bin/tmux-sessionizer"
else
  skip "bin"
fi

[ -d "$BACKUP_DIR" ] && printf '\n\033[1mBackups of anything replaced: %s\033[0m\n' "$BACKUP_DIR"
printf '\n\033[1;32mDone.\033[0m Restart your shell / tmux server / nvim to pick everything up.\n'
