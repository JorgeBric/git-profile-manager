# =============================================================
# lib/prompt.sh — Terminal prompt rendering
# =============================================================
# Provides:
#   render_prompt   — builds PS1 with account label + git branch
#   set_git_prompt  — activates render_prompt via PROMPT_COMMAND
#
# Prompt format:
#   [ACCOUNT_LABEL] user@host /current/dir (branch)
#   $
#
# Colors:
#   Green  = user@host
#   Purple = working directory
#   Cyan   = git branch
# =============================================================

# Load git-prompt.sh helper if available (provides __git_ps1)
if [ -f "$HOME/.git-completion/git-prompt.sh" ]; then
  source "$HOME/.git-completion/git-prompt.sh"
fi

function render_prompt {
  if type __git_ps1 &>/dev/null; then
    if git rev-parse --is-inside-work-tree &>/dev/null; then
      PS1="${GIT_ACCOUNT} \[\033[32m\]\u@\h \[\033[35m\]\w \[\033[36m\]$(__git_ps1 '(%s)' 2>/dev/null)\[\033[00m\]\n\$ "
    else
      PS1="${GIT_ACCOUNT} \[\033[32m\]\u@\h \[\033[35m\]\w\[\033[00m\]\n\$ "
    fi
  else
    PS1="${GIT_ACCOUNT} \[\033[32m\]\u@\h \[\033[35m\]\w\[\033[00m\]\n\$ "
  fi
}

function set_git_prompt {
  PROMPT_COMMAND=render_prompt
}
