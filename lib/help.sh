# =============================================================
# lib/help.sh — Git command reference menu
# =============================================================
# Provides:
#   help-menu   — interactive categorized git command reference
# =============================================================

function help-menu {
  while true; do
    echo ""
    echo "───────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
    echo ""
    echo "❓ Git Command Reference"
    echo ""
    echo "  1) 📋 Status & Info"
    echo "  2) 💾 Stage & Commit"
    echo "  3) 🌿 Branches"
    echo "  4) 🔄 Sync  (push / pull / fetch)"
    echo "  5) 🕐 History & Undo"
    echo "  6) 🔐 SSH & Identity"
    echo "  b) ⬅️  Back"
    echo " "

    read -rp "#? " choice
    choice="$(echo "$choice" | tr -d '\r' | xargs)"

    case "$choice" in
      1) _help_status ;;
      2) _help_commit ;;
      3) _help_branches ;;
      4) _help_sync ;;
      5) _help_history ;;
      6) _help_ssh ;;
      b|B|0) return 0 ;;
      *) echo "⚠️ Enter 1–6 or b." ;;
    esac
  done
}

# --------------------------------------------------
# 1) Status & Info
# --------------------------------------------------
function _help_status {
  cat <<'EOF'

📋 STATUS & INFO
───────────────────────────────────────────────────────────────────────────────
  git status              Show changed / staged / untracked files
  git status -sb          Compact version (branch + short status)
  git diff                Changes not yet staged
  git diff --staged       Changes staged and ready to commit
  git diff HEAD           All changes since last commit
  git log                 Full commit history
  git log --oneline       One-line commit summary
  git log --oneline -10   Last 10 commits
  git show <hash>         Details of a specific commit
  git stash list          List saved stashes
───────────────────────────────────────────────────────────────────────────────

EOF
}

# --------------------------------------------------
# 2) Stage & Commit
# --------------------------------------------------
function _help_commit {
  cat <<'EOF'

💾 STAGE & COMMIT
───────────────────────────────────────────────────────────────────────────────
  git add <file>          Stage a specific file
  git add -A              Stage ALL changes (new + modified + deleted)
  git add .               Stage changes in current directory
  git restore --staged <file>   Unstage a file (keep changes)
  git commit -m "msg"     Commit staged changes with a message
  git commit --amend      Edit the last commit message (before pushing)
  git stash               Save uncommitted changes temporarily
  git stash pop           Restore last stash
  git stash drop          Delete last stash without applying
───────────────────────────────────────────────────────────────────────────────
💡 Tip: Commits are LOCAL until you run git push.
        It's safe to commit often without internet.
───────────────────────────────────────────────────────────────────────────────

EOF
}

# --------------------------------------------------
# 3) Branches
# --------------------------------------------------
function _help_branches {
  cat <<'EOF'

🌿 BRANCHES
───────────────────────────────────────────────────────────────────────────────
  git branch              List local branches (* = current)
  git branch -a           List local + remote branches
  git branch <name>       Create a branch (stay on current)
  git checkout <name>     Switch to an existing branch
  git checkout -b <name>  Create AND switch to a new branch
  git branch -d <name>    Delete a branch (safe — only if merged)
  git branch -D <name>    Force delete a branch (even if not merged)
  git merge <name>        Merge branch into current branch
  git rebase <branch>     Rebase current branch onto another
───────────────────────────────────────────────────────────────────────────────
💡 Tip: Use 'select_branch' in this menu to switch branches interactively.
───────────────────────────────────────────────────────────────────────────────

EOF
}

# --------------------------------------------------
# 4) Sync
# --------------------------------------------------
function _help_sync {
  cat <<'EOF'

🔄 SYNC  (push / pull / fetch)
───────────────────────────────────────────────────────────────────────────────
  git fetch               Download remote changes (don't merge yet)
  git pull                Fetch + merge remote changes into current branch
  git pull --rebase       Fetch + rebase instead of merge (cleaner history)
  git push                Push current branch to remote
  git push -u origin main Set upstream and push (first push of a branch)
  git push origin <name>  Push a specific branch
  git remote -v           Show remote URLs
  git remote add origin <url>   Link local repo to a remote
───────────────────────────────────────────────────────────────────────────────
💡 Tip: 'git push' needs SSH to be loaded. Run 'am' to reload your profile.
───────────────────────────────────────────────────────────────────────────────

EOF
}

# --------------------------------------------------
# 5) History & Undo
# --------------------------------------------------
function _help_history {
  cat <<'EOF'

🕐 HISTORY & UNDO
───────────────────────────────────────────────────────────────────────────────
  git log --oneline           Compact commit history
  git log --oneline --graph   Visual branch history
  git diff <hash1> <hash2>    Compare two commits
  git revert <hash>           Create a new commit that undoes a commit
  git reset --soft HEAD~1     Undo last commit, keep changes staged
  git reset --mixed HEAD~1    Undo last commit, keep changes unstaged
  git reset --hard HEAD~1     ⚠️ Undo last commit AND discard changes
  git restore <file>          Discard unstaged changes in a file
  git checkout <hash> -- <f>  Restore a file from a specific commit
───────────────────────────────────────────────────────────────────────────────
⚠️  WARNING: 'reset --hard' and 'restore' permanently discard changes.
             Only use them if you're sure you don't need those changes.
───────────────────────────────────────────────────────────────────────────────

EOF
}

# --------------------------------------------------
# 6) SSH & Identity
# --------------------------------------------------
function _help_ssh {
  cat <<'EOF'

🔐 SSH & IDENTITY
───────────────────────────────────────────────────────────────────────────────
  git config user.name              Show name for current repo
  git config user.email             Show email for current repo
  git config --global user.name     Show global default name
  git-whoami                        Show current GPM identity (this tool)

  ssh-add -l                        List loaded SSH keys
  ssh-add ~/.ssh/id_ed25519_work    Load a specific SSH key manually
  ssh -T git@github.com             Test SSH connection to GitHub

  Generating a new SSH key:
    ssh-keygen -t ed25519 -C "you@email.com" -f ~/.ssh/id_ed25519_name
    cat ~/.ssh/id_ed25519_name.pub   (copy this → GitHub SSH settings)

  Fixing CRLF issues in git-prompt.sh:
    dos2unix ~/.git-completion/git-prompt.sh

  Switching profiles:
    am              Open account menu
    gpm-enable      Enable autorun on terminal open
    gpm-disable     Disable autorun on terminal open
───────────────────────────────────────────────────────────────────────────────

EOF
}
