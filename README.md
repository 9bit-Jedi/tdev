# tdev

Keyboard-only terminal dev environment: **zsh** (antidote + Powerlevel10k) + **tmux** + **Neovim** + **fzf** + **git**. Every config here is symlinked into place by `install.sh` — nothing is copied, so edits in this repo take effect immediately after a shell/tmux/nvim restart.

## Install

```bash
git clone https://github.com/9bit-Jedi/tdev.git ~/tdev
~/tdev/install.sh
```

Prompts per tool (zsh, tmux, nvim, aliases, fzf, bin) so you can skip what you don't want. Pass `-y` to accept everything non-interactively. Anything already in your `$HOME` gets backed up to `~/.tdev-backup-<timestamp>/` before being replaced.

## Structure

| Folder | Contents |
|---|---|
| `zsh/` | `.zshrc`, OS-specific `zshrc.linux`/`zshrc.macos`, antidote plugin list, `p10k/.p10k.zsh` |
| `tmux/` | `tmux.conf` (TPM-managed plugins) |
| `nvim/` | `init.lua`, `lazy-lock.json`, snippets |
| `aliases/` | `.aliases` — git/docker/shell aliases + functions (`fkill`, `fcd`, `gwt`, `gcof`, `gdiff`, ...) |
| `bin/` | `tmux-sessionizer` — fuzzy project → tmux session launcher |
| `scripts/` | `generate_cheatsheet.py` — regenerates `cheatsheet.pdf` |

See `cheatsheet.pdf` for the full reference; essentials below.

## Leader keys

| Tool | Leader |
|---|---|
| tmux | `Ctrl-a` (prefix) |
| Neovim | `Space` |
| fzf-git.sh | `Ctrl-g` |
| Antigravity CLI | `agy` / `agp` (aliases), tmux `prefix A` for a dedicated window |

## Core workflows

**tmux** (after `prefix`)
| Key | Action |
|---|---|
| `"` / `%` | split pane vertical / horizontal |
| `h j k l` | move between panes |
| `H J K L` | resize pane |
| `c` | new window |
| `s` / `w` / `q` | choose session / window / show pane numbers (tmux defaults) |
| `r` | reload `tmux.conf` |
| `[` then `v` / `y` | copy-mode: begin selection / copy to clipboard |

**Shell**
| Command | Action |
|---|---|
| `tm` / `ts` | tmux-sessionizer — fuzzy pick a project, bootstrap edit/shell/run/agent windows |
| `Ctrl-t` / `Ctrl-r` / `Alt-c` | fzf: insert file path / search history / cd into dir |
| `fkill`, `fcd`, `fdocker`, `fdlogs` | fuzzy-pick a process / dir / container to act on |
| `gwt <branch>` | create or attach a sibling git worktree for `<branch>` |
| `gcof`, `gdiff` | fuzzy git checkout / fuzzy diff review |

**Git aliases**
| Alias | Action |
|---|---|
| `gs` `ga` `gc "msg"` `gp` `gl` | status / add / commit / push / pull |
| `gb` `gco` `gsw` `glog` `gd` | branch / checkout / switch / log graph / diff |
| `gundo` | soft-reset last commit, keep changes staged |
| `gw` `gwl` `gwa` `gwr` | git worktree / list / add / remove |

**Neovim**
| Key | Action |
|---|---|
| `space e` | file explorer (oil.nvim) |
| `space ff` / `fg` / `fb` | Telescope: find files / grep / buffers |
