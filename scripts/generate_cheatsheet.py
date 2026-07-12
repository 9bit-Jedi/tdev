#!/usr/bin/env python3
"""
generate_cheatsheet.py
=======================
One-shot generator for the "Terminal Dev Environment" A4-landscape cheatsheet PDF.

HOW TO MAKE FUTURE CHANGES
---------------------------
Everything you'd normally want to edit lives in the CONTENT section below:
  - COLUMNS: a list of 4 columns, each a list of BLOCKS in top-to-bottom order.
  - Each block is a dict: title, optional highlight terms, rows, optional note.
  - Each row is a (key, value) tuple. Use NEW / OLD helper functions to tag rows.

You do NOT need to touch the HTML/CSS ("RENDERING" section) for normal edits like:
  - changing text, adding/removing a row
  - adding/removing a whole block
  - reordering blocks within or across columns (just move the dict in the list)
  - re-tagging something as NEW/OLD
  - changing which category color a block's title term uses (git/shell/tmux/nvim/misc)

Only touch the RENDERING section if you want to change fonts, colors, spacing,
page size, or the number of columns.

USAGE
-----
    pip install weasyprint --break-system-packages   # one-time
    python3 generate_cheatsheet.py                    # writes cheatsheet.pdf here

Requires the DejaVu Sans / DejaVu Sans Mono fonts (present by default on most Linux
systems, including this sandbox). Output: ./cheatsheet.pdf (single A4 landscape page).
"""

import html
import subprocess
import sys
from pathlib import Path

# ============================================================================
# CONTENT  (edit this section to change what's on the cheatsheet)
# ============================================================================

OUTPUT_PDF = "cheatsheet.pdf"

TITLE = "Terminal Dev Environment: Cheatsheet"
SUBTITLE = "tmux · zsh/fzf · Neovim · git · Antigravity CLI"
LEGEND = (
    '<span class="tag old">OLD</span> pre-existing workflow &nbsp;&nbsp;'
    '<span class="tag new">NEW</span> added workflow &nbsp;&nbsp;'
    "Where multiple ways exist to do the same thing, all are listed: "
    "pick whichever fits the moment."
)

NEW = lambda text: f'{text} <span class="tag new">NEW</span>'   # noqa: E731
OLD = lambda text: f'{text} <span class="tag old">OLD</span>'   # noqa: E731
ALT = lambda text: f'<span class="alt">{text}</span>'           # noqa: E731

# Highlight colors available for block titles — pass the matching key as the
# 3rd element of a title tuple, e.g. ("Git", "aliases (existing, kept)", "git").
# Valid keys: "git", "shell", "tmux", "nvim", "misc" (see HIGHLIGHT_COLORS below).
HIGHLIGHT_COLORS = {
    "git":   ("#ffdfb8", "#7a3d00"),
    "shell": ("#c9e3ff", "#0b3d78"),
    "tmux":  ("#d9c9ff", "#4a1f8a"),
    "nvim":  ("#c6f0d8", "#12622f"),
    "misc":  ("#e6e6e6", "#333333"),
}


def block(title_parts, rows, note=None):
    """
    title_parts: list of (text, highlight_key_or_None) tuples that make up the
                 <h2> heading, rendered in order. Example:
                 [("Neovim", "nvim"), (" ", None), ("git", "git"), (": gitsigns (new)", None)]
    rows:        list of (key, value_html) tuples -> table rows.
    note:        optional italic footnote string (plain text/HTML).
    """
    return {"title_parts": title_parts, "rows": rows, "note": note}


# ---- Column 1 --------------------------------------------------------------
col1 = [
    block(
        [("Git", "git"), (" aliases (existing, kept)", None)],
        [
            ("gs", "status"),
            ("gl", "pull"),
            ("ga", "add"),
            ('gc "msg"', "commit -m"),
            ("gp", "push"),
            ("gamend", "commit --amend --no-edit"),
            ("gsw / gsm", "switch / switch master"),
            ("gb", "branch"),
            ("gco / gcm", "checkout / checkout main"),
            ("gcl", "clone"),
            ("glog", "log --oneline --graph --all"),
            ("gd", "diff"),
            ("gundo", "reset --soft HEAD~1"),
        ],
    ),
    block(
        [("Git", "git"), (" aliases (new)", None)],
        [
            ("gwl", "worktree list"),
            ("gwa", "worktree add"),
            ("gwr", "worktree remove"),
            ("gcp", "cherry-pick"),
            ("gst / gstp", "stash / stash pop"),
            ("grb main", "rebase -i main"),
            ("grbc / grba", "rebase --continue / --abort"),
        ],
        note="gwt() function (left) is the fast path vs manual gwa+cd.",
    ),
    block(
        [("Git", "git"), (" lazygit (lg)", None)],
        [
            ("1..5", "switch panel"),
            ("Space", "stage/unstage file or hunk"),
            ("a", "stage all"),
            ("c", "commit"),
            ("P / p", "push / pull"),
            ("d", "discard (careful)"),
            ("e", "edit file in $EDITOR"),
            ("Space (conflict)", "pick ours/theirs/both"),
            ("M", "external merge tool"),
        ],
        note="Alt for staging/commit vs gitsigns hunk-stage in Neovim.",
    ),
    block(
        [("Shell", "shell"), (" fzf-git.sh (Ctrl-g \u2026)", None)],
        [
            ("Ctrl-g Ctrl-f", "files"),
            ("Ctrl-g Ctrl-b", "branches"),
            ("Ctrl-g Ctrl-t", "tags"),
            ("Ctrl-g Ctrl-r", "remotes"),
            ("Ctrl-g Ctrl-h", "commit hashes"),
            ("Ctrl-g Ctrl-s", "stash entries"),
            ("Ctrl-g Ctrl-l", "reflog"),
        ],
        note="All-NEW. Inserts token at cursor with live preview.",
    ),
]

# ---- Column 2 --------------------------------------------------------------
col2 = [
    block(
        [("tmux", "tmux"), (' prefix <span style="font-weight:400">Ctrl-a</span>', None)],
        [
            ('" / %', "split horizontal / vertical"),
            ("h j k l", NEW("move between panes")),
            ("o", OLD("next pane (arrow-key style)")),
            ("H J K L", NEW("resize pane")),
            ("Ctrl+arrow", OLD("resize pane")),
            ("x", "kill pane"),
            ("c", "new window"),
            ("[num]", "go to window [num]"),
            ("n / p", "next / prev window"),
            (",", "rename window"),
            ("&amp;", "kill window"),
            ("s / w", "choose session / window from list"),
            ("f", NEW("tmux-sessionizer (new window)")),
            ("F", NEW("tmux-fzf menu (sess/win/pane)")),
            ("A", NEW("launch Antigravity CLI window")),
            ("d", "detach"),
            ("r", NEW("reload tmux.conf")),
            ("q", "show pane numbers"),
            ("?", "show all keybindings"),
            (":", "command prompt"),
        ],
    ),
    block(
        [("Neovim", "nvim"), (" ", None), ("git", "git"), (": diffview / fugitive (new)", None)],
        [
            ("leader gv / gV", "Diffview open / close"),
            ("leader gh / gH", "file history: file / repo"),
            ("leader gl", "Flog: git log graph"),
            (":Git", "fugitive status window (s/u stage)"),
            (":Git blame", "full-file blame (A cycle, Enter open)"),
            (":Git commit/push", "git commands in-editor"),
        ],
    ),
    block(
        [("Neovim", "nvim"), (" merge conflicts (new)", None)],
        [
            ("]x / [x", "next / prev conflict (diffview)"),
            ("leader co", "choose ours"),
            ("leader ct", "choose theirs"),
            ("leader cb", "choose base"),
            ("leader ca", "choose all"),
            (":diffget //2 //3", f'theirs / ours {ALT("(native, no plugin)")}'),
        ],
    ),
    block(
        [("Two ways to do it", "misc"), (": quick map", None)],
        [
            ("Find a file", "Ctrl-t (shell) · leader ff (nvim) · fcd/z (dirs)"),
            ("Switch branch", "gco/gsw (manual) · gcof (fuzzy) · lazygit panel"),
            ("View a diff", "gd/gdiff (shell) · leader gv (nvim) · lg (lazygit)"),
            ("Stage changes", "ga . (manual) · leader gs (hunk, nvim) · lg Space (lazygit)"),
            ("Resolve conflict", "leader co/ct (diffview) · :diffget //2/3 (native) · lg Space"),
            ("New project session", "tn (manual) · ts/tm (fuzzy)"),
            ("Jump panes", "o (cycle) · h j k l (directional)"),
            ("Kill a process", "kill -9 &lt;pid&gt; (manual) · fkill (fuzzy)"),
            ("Work on 2 branches", "git stash + checkout (manual) · gwt/worktree (parallel dirs)"),
            ("AI help", "claudecode.nvim (in-file) · agy (repo-wide/async)"),
        ],
    ),
]

# ---- Column 3 --------------------------------------------------------------
col3 = [
    block(
        [("tmux", "tmux"), (" Copy Mode (vi keys)", None)],
        [
            ("[", "enter copy mode"),
            ("]", "paste buffer"),
            ("v", NEW("begin selection")),
            ("Space", OLD("begin selection") + " (legacy)"),
            ("y", NEW("copy \u2192 system clipboard")),
            ("Enter", OLD("copy selection") + " (legacy)"),
            ("r", NEW("toggle rectangle select")),
            ("q", "exit copy mode"),
        ],
    ),
    block(
        [("Neovim", "nvim"), (" navigation (new)", None)],
        [
            ("s", "Flash jump (any visible loc)"),
            ("S", "Flash treesitter node jump"),
            ("/ then Enter", f'native search {ALT("(still works)")}'),
            ("C-h/j/k/l", "cross Neovim splits AND tmux panes"),
        ],
    ),
    block(
        [("Neovim", "nvim"), (" leader = Space (existing)", None)],
        [
            (",s", "w (save)"),
            ("space e", "diagnostic float"),
            ("[d / ]d", "prev/next diagnostic"),
            ("space q", "diagnostics loclist"),
            ("gd / gi / K", "definition / impl / hover"),
            ("space t / rn", "type def / rename"),
            ("-", "Oil: parent dir"),
            ("^", "Oil: open cwd"),
            ("; / m", "Arrow bookmarks (global/buffer)"),
            ("{ / }", "Aerial prev/next symbol"),
            ("leader a", f'Aerial toggle {ALT("(overloaded w/ Claude grp)")}'),
            ("C-K (insert)", "expand snippet"),
            ("leader se/sa", "edit / add snippet"),
            ("leader ss/sl/sd", "session save/load/delete"),
            ("leader ,", "copy filename to clipboard"),
            ("leader y / wy", "yank sel/word to system clip"),
            (",s / ,d", "vsplit / split"),
        ],
    ),
    block(
        [("Neovim", "nvim"), (" worktrees &amp; diagnostics (new)", None)],
        [
            ("leader gwc", "create worktree"),
            ("leader gwl", "list/switch worktree"),
            ("leader xx", "Trouble: workspace diagnostics"),
            ("leader xd", "Trouble: buffer diagnostics"),
            ("leader xr", "Trouble: LSP references"),
            ("leader xq", "Trouble: quickfix list"),
        ],
    ),
    block(
        [("Antigravity CLI", "misc"), (": agy (new)", None)],
        [
            ("agy", "launch interactive TUI"),
            ('agy -p "\u2026"', "one-shot headless prompt"),
            ('agy -p "\u2026" --output-format json', "structured output for piping"),
            ('/agent "\u2026"', "dispatch async background subagent"),
            ("Ctrl-I", "command mode (inline, from TUI)"),
            ("/usage", "check quota (subagents run in parallel)"),
            ("/logout", "clear saved credentials"),
            ("ag / agp / agy?", "shell aliases \u2192 agy / agy -p / agy -p"),
            ("tmux prefix A", "open in dedicated tmux window"),
        ],
        note="Use in-editor claudecode.nvim for scoped in-file review; agy for repo-wide/async tasks.",
    ),
]

# ---- Column 4 --------------------------------------------------------------
col4 = [
    block(
        [("Shell", "shell"), (" functions &amp; helpers", None)],
        [
            ("fkill", "fuzzy pick+kill process"),
            ("fcd [root]", "fuzzy cd w/ tree preview"),
            ("mkcd &lt;dir&gt;", f'mkdir -pv + cd (alt: {ALT("`mkdir -pv` alias")} <span class="tag old">OLD</span>)'),
            ("extract &lt;f&gt;", "universal archive extract"),
            ("gcof", "fuzzy git checkout (local+remote)"),
            ("gdiff [ref]", "fuzzy pick changed file \u2192 diff"),
            ("gwt &lt;branch&gt;", "create/attach sibling worktree"),
            ("fdocker", "fuzzy exec into container"),
            ("fdlogs", "fuzzy follow container logs"),
        ],
        note="All-NEW additions layered on existing aliases below.",
    ),
    block(
        [("Shell", "shell"), (" fzf core", None)],
        [
            ("Ctrl-t", NEW("insert fuzzy file path")),
            ("Ctrl-r", NEW("fuzzy history search")),
            ("Alt-c", NEW("fuzzy cd")),
            ("**&lt;Tab&gt;", NEW("fuzzy-complete any arg")),
            ("z &lt;name&gt;", NEW("zoxide frecency-jump (aliased as cd)")),
            ("cdd", NEW("real `cd` escape hatch")),
        ],
    ),
    block(
        [("Neovim", "nvim"), (" Telescope (existing)", None)],
        [
            ("leader ff", "find files"),
            ("leader fg", "live grep"),
            ("leader fb", "buffers"),
        ],
        note="Same picker style as fzf-git.sh in shell: consistent UX.",
    ),
    block(
        [("Shell", "shell"), (" Sessions (", None), ("tmux", "tmux"), (")", None)],
        [
            ("tn &lt;name&gt;", OLD("new session")),
            ("ta &lt;name&gt;", OLD("attach session")),
            ("tl", OLD("list sessions")),
            ("tk / tks", OLD("kill session / server")),
            ("tm [name]", NEW("attach-or-create")),
            ("ts", NEW("tmux-sessionizer: fuzzy project \u2192 session")),
        ],
        note="ts/tm are the fast path; tn/ta/tl/tk still work for manual control.",
    ),
    block(
        [("Neovim", "nvim"), (" ", None), ("git", "git"), (": gitsigns (new)", None)],
        [
            ("]c / [c", "next / prev hunk"),
            ("leader gs", "stage hunk (v: stage selection)"),
            ("leader gr", "reset hunk"),
            ("leader gp", "preview hunk"),
            ("leader gS / gR", "stage / reset whole buffer"),
            ("leader gb", "blame line (full)"),
            ("leader gd", "diff this file"),
        ],
    ),
    block(
        [("Neovim", "nvim"), (" claudecode.nvim (existing)", None)],
        [
            ("leader ac", "toggle Claude"),
            ("leader af", "focus Claude"),
            ("leader ar / aC", "resume / continue"),
            ("leader am", "select model"),
            ("leader ab", "add current buffer"),
            ("leader as", "send selection (v) / add file (tree)"),
            ("leader aa / ad", "accept / deny diff"),
        ],
    ),
]

COLUMNS = [col1, col2, col3, col4]

# ============================================================================
# RENDERING  (only touch this section for visual/layout changes)
# ============================================================================

CSS = """
@page { size: A4 landscape; margin: 5mm; }
* { box-sizing: border-box; }
html { height: 200mm; }
body {
  font-family: "DejaVu Sans", Arial, sans-serif;
  font-size: 6.1px;
  line-height: 1.22;
  color: #111;
  margin: 0;
  height: 200mm;
  overflow: hidden;
}
h1 { font-size: 11.5px; font-weight: 800; margin: 0 0 0.8mm 0; letter-spacing: 0.2px; }
h1 span { font-weight: 400; color: #666; font-size: 7px; }
.legend { font-size: 5.6px; color: #555; margin-bottom: 1.1mm; }
.cols { display: flex; gap: 1.6mm; align-items: flex-start; }
.col { display: flex; flex-direction: column; gap: 1.1mm; flex: 1 1 0; min-width: 0; }
.block { border: 0.6px solid #cfcfcf; border-radius: 2px; padding: 1.1mm 1.5mm 1.3mm 1.5mm; }
.block h2 {
  font-size: 6.9px; font-weight: 800; margin: 0 0 0.7mm 0; padding-bottom: 0.5mm;
  border-bottom: 0.8px solid #222; letter-spacing: 0.1px;
}
table { width: 100%; border-collapse: collapse; }
td { padding: 0.18mm 0; vertical-align: top; }
td.k {
  font-family: "DejaVu Sans Mono", monospace; font-weight: 700; white-space: nowrap;
  padding-right: 1.5mm; color: #163a7a;
}
td.v { color: #222; }
.alt { color: #8a8a8a; font-size: 5.3px; }
.note { color: #8a8a8a; font-size: 5.3px; font-style: italic; margin-top: 0.3mm; }
.tag {
  display: inline-block; font-size: 4.7px; font-weight: 700; padding: 0.1mm 0.8mm;
  border-radius: 2px; margin-left: 0.6mm; color: #fff;
}
.tag.old { background: #8f8f8f; }
.tag.new { background: #1f7a3d; }
.hl { padding: 0.2mm 1mm; border-radius: 2px; margin-right: 0.6mm; display: inline-block; }
{HIGHLIGHT_CSS}
"""


def highlight_css():
    lines = []
    for key, (bg, fg) in HIGHLIGHT_COLORS.items():
        lines.append(f".hl-{key} {{ background: {bg}; color: {fg}; }}")
    return "\n".join(lines)


def render_title(parts):
    out = []
    for text, hl_key in parts:
        if hl_key:
            out.append(f'<span class="hl hl-{hl_key}">{text}</span>')
        else:
            out.append(text)
    return "".join(out)


def render_block(b):
    rows_html = "\n".join(
        f'<tr><td class="k">{k}</td><td class="v">{v}</td></tr>' for k, v in b["rows"]
    )
    note_html = f'<div class="note">{b["note"]}</div>' if b["note"] else ""
    title_html = render_title(b["title_parts"])
    return f"""<div class="block">
<h2>{title_html}</h2>
<table>
{rows_html}
</table>
{note_html}
</div>"""


def render_column(blocks):
    inner = "\n\n".join(render_block(b) for b in blocks)
    return f'<div class="col">\n\n{inner}\n\n</div>'


def render_html():
    css = CSS.replace("{HIGHLIGHT_CSS}", highlight_css())
    cols_html = "\n\n".join(render_column(c) for c in COLUMNS)
    return f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
{css}
</style>
</head>
<body>

<h1>{html.escape(TITLE, quote=False)} <span>{html.escape(SUBTITLE, quote=False)}</span></h1>
<div class="legend">
  {LEGEND}
</div>

<div class="cols">

{cols_html}

</div>
</body>
</html>
"""


def main():
    out_dir = Path(__file__).resolve().parent
    html_path = out_dir / "cheatsheet.html"
    pdf_path = out_dir / OUTPUT_PDF

    html_content = render_html()
    html_path.write_text(html_content, encoding="utf-8")
    print(f"wrote {html_path}")

    try:
        import weasyprint  # noqa: F401
    except ImportError:
        print("weasyprint not installed. Install it with:")
        print("  pip install weasyprint --break-system-packages")
        sys.exit(1)

    result = subprocess.run(
        [sys.executable, "-m", "weasyprint", str(html_path), str(pdf_path)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(result.stdout)
        print(result.stderr, file=sys.stderr)
        sys.exit(result.returncode)

    print(f"wrote {pdf_path}")


if __name__ == "__main__":
    main()
