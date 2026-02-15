# -----------------------------------------------------
# Version Control
# -----------------------------------------------------
# Version: 1.0 – Jorge's Git Prompt Setup
# Updated: 2025-04-19
# Comments: Initial setup 
# -----------------------------------------------------
# Version: 1.1 – Jorge's Git Prompt Setup
# Updated: 2025-04-20
# Comments: Improves project folder management and confirmation message before switching accounts. Commit tested.
# -----------------------------------------------------
# Version: 1.2 – Jorge's Git Prompt Setup
# Updated: 2026-02-15
# Comments: Adds professional navigation (Back + Stay-in-root + Exit), git-only repo detection, dirty highlighting,
#           and search-by-name in the project selector. Keeps bash_profile as main entry point.
# -----------------------------------------------------

# ----------------------------------------------------
# ❗ Important - To be on the top
# ----------------------------------------------------

# Load Git prompt helper from fallback local path
if [ -f "$HOME/.git-completion/git-prompt.sh" ]; then
  source "$HOME/.git-completion/git-prompt.sh"
fi


# ----------------------------------------------------
# 0️⃣ Welcome message
# ----------------------------------------------------
echo -e "Hello, Jorge. What a beautiful $(date +%A)!!! 🐢"


# ----------------------------------------------------
# 1️⃣ GitHub - Switching Accounts
# ----------------------------------------------------

# Default account label
export GIT_ACCOUNT=""

# Function to set personal identity and update prompt
function git_set_personal {
  git config user.name "JorgeBric" 2>/dev/null
  git config user.email "jorgeebricenom@gmail.com" 2>/dev/null
  export GIT_ACCOUNT="[PERSONAL] 🏡"
  set_git_prompt
  echo "💻 Git is now set to use your PERSONAL account."
}

# Function to set work identity and update prompt
function git_set_work {
  git config user.name "Jorge-B-AD" 2>/dev/null
  git config user.email "jorge.briceno@applydigital.com" 2>/dev/null
  export GIT_ACCOUNT="[WORK] 🏢"
  set_git_prompt
  echo "🏢 Git is now set to use your WORK account."
}



# ----------------------------------------------------
# 2️⃣ GitHub - Verify Current Account and User
# ----------------------------------------------------

function git-whoami {
  echo "👤 Current Git identity:"
  echo "   Name:  $(git config user.name)"
  echo "   Email: $(git config user.email)"
}


# ----------------------------------------------------
# 2.1 GitHub - Manual Checks
# ----------------------------------------------------
# To check the code performance
# Run:
# git config user.name
# git config user.email


# ----------------------------------------------------
# 2.2 GitHub - Pre Configuration
# ----------------------------------------------------
# In terminal run the following commands to get the SSH key (stored locally).
# After that, go to GitHub ➝ Settings ➝ SSH and GPG keys ➝ New SSH key, so the system can match them and provide access.

# [Personal]
# ssh-keygen -t ed25519 -C "jorgeebricenom@gmail.com" -f ~/.ssh/id_ed25519_personal
# Next excecute: cat ~/.ssh/id_ed25519_personal.pub copy the whole line. 

# [Work]
# ssh-keygen -t ed25519 -C "jorge.briceno@applydigital.com" -f ~/.ssh/id_ed25519_work
# Next execute: cat ~/.ssh/id_ed25519_work.pub copy the whole line into your GitHub SSH settings.


# ----------------------------------------------------
# 3️⃣ GitHub - Message on the Terminal
# ----------------------------------------------------

# ----------------------------------------------------
# 3.1 GitHub - Prompt Rendering Function 
# ----------------------------------------------------

# Dynamically builds the terminal prompt (PS1) for Git-aware context.
# Displays:
#   - GitHub account label (e.g., [WORK] 👨‍💼)
#   - Username and hostname (e.g., [LocalUserName]@[ComputerName])
#   - Current working directory (e.g., /c/COMPANIES/...)
#   - Git branch name, if inside a Git repository

function render_prompt {
  # __git_ps1 is a Git helper function that returns the current branch name (e.g., (main)).
  # It only works inside Git repos and requires sourcing git-prompt.sh.
  # We check for it with `type` to avoid errors if it’s not loaded.
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
  # Use PROMPT_COMMAND to render the prompt dynamically before each new command. First, define a function `render_prompt` that constructs `PS1`, and then assign PROMPT_COMMAND=render_prompt to apply it.
}

# Activate the prompt initially
# The prompt is styled and initialized immediately
set_git_prompt


# ----------------------------------------------------
# 3.2 GitHub - Project Selector
# ----------------------------------------------------
# Professional selector goals:
# ✅ Back navigation to Account Menu (b)
# ✅ Stay in root without selecting a repo (r)
# ✅ Exit selector (0)
# ✅ Search by name (type /text, clear with /)
# ✅ Auto-detect only git repos (folders with .git)
# ✅ Highlight dirty repos (uncommitted changes)
# ✅ Show current branch per repo in the menu
# ✅ Auto-commit reminder when exiting/back/root (if CURRENT repo is dirty)
#
# Return codes:
#   0  = done (repo selected / stayed in root / exit selector)
#   99 = back to account menu
function select_project {
  local GITHUB_ROOT="${1:-$PWD}"  # Use current directory if no argument provided

  # ANSI colors (Git Bash-friendly)
  local C_RED="\033[31m"
  local C_GRN="\033[32m"
  local C_YLW="\033[33m"
  local C_CYN="\033[36m"
  local C_RST="\033[0m"

  # ----------------------------------------------------
  # Helper: remind to commit if CURRENT directory is a dirty git repo
  # - This triggers when you exit/back/root (i.e., leaving the selector flow)
  # - It does NOT force a commit; it just warns and shows the exact commands
  # ----------------------------------------------------
  _commit_reminder_if_dirty() {
    if git rev-parse --is-inside-work-tree &>/dev/null; then
      if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
        echo ""
        echo -e "${C_YLW}⚠️  Commit reminder:${C_RST} Your CURRENT repo has uncommitted changes:"
        git status -sb
        echo ""
        echo "💡 If you want to commit now:"
        echo "   git add -A"
        echo "   git commit -m \"<message>\""
        echo ""
        echo "✅ You can also commit later — commits are local. Only 'git push' needs GitHub/SSH."
        echo ""
      fi
    fi
  }

  # ----------------------------------------------------
  # Helper: compute repo status info (branch + dirty count)
  # ----------------------------------------------------
  _repo_branch() {
    # For normal branches: prints branch name
    # For detached HEAD: prints "DETACHED"
    local repo_path="$1"
    local b
    b=$(git -C "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null)
    [[ "$b" == "HEAD" || -z "$b" ]] && b="DETACHED"
    echo "$b"
  }

  _repo_dirty_count() {
    local repo_path="$1"
    git -C "$repo_path" status --porcelain 2>/dev/null | wc -l | tr -d ' '
  }

  # Collect subfolders under root
  shopt -s nullglob
  local project_dirs=("$GITHUB_ROOT"/*/)
  shopt -u nullglob

  # Keep only actual git repos (must have a .git folder)
  local repos=()
  local dir
  for dir in "${project_dirs[@]}"; do
    [[ -d "$dir/.git" ]] && repos+=("$(basename "$dir")")
  done

  echo "📁 Detected base GitHub folder: $GITHUB_ROOT"
  echo ""
  echo "───────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
  echo ""
  echo "🧭 Controls: [number]=open  /text=search  /=clear  b=back  r=root  c=create  0=exit"
  echo ""

  # If there are no repos, still allow "root" or "back"
  if [[ ${#repos[@]} -eq 0 ]]; then
    echo "⚠️ No Git repositories found here (no .git folders)."
    echo "b) ⬅️  Back to Account Menu"
    echo "r) 📂 Stay in GitHub root"
    echo "0) 🚪 Exit selector"
    while true; do
      echo " "
      read -rp "Enter your choice: " REPLY
      case "$REPLY" in
        0)
          _commit_reminder_if_dirty
          echo "🌄 Exiting selector."
          return 0
          ;;
        b|B)
          _commit_reminder_if_dirty
          echo "⬅️ Back to Account Menu..."
          return 99
          ;;
        r|R)
          _commit_reminder_if_dirty
          cd "$GITHUB_ROOT" || echo "⚠️ Could not cd to root."
          return 0
          ;;
        *)
          echo "⚠️ Invalid input. Use b, r, or 0."
          ;;
      esac
    done
  fi

  # Search filter; empty means "show all"
  local filter=""

  while true; do
    # Build list currently shown (filtered)
    local shown=()
    local r
    for r in "${repos[@]}"; do
      if [[ -z "$filter" || "${r,,}" == *"${filter,,}"* ]]; then
        shown+=("$r")
      fi
    done

    # Show filter banner
    if [[ -n "$filter" ]]; then
      echo -e "🔎 Filter: ${C_CYN}${filter}${C_RST}  (type / to clear)"
    fi

    # Print the numbered repo list with branch + dirty highlighting
    if [[ ${#shown[@]} -eq 0 ]]; then
      echo "⚠️ No matches. Try another /search or type / to clear."
    else
      local i=1
      for r in "${shown[@]}"; do
        local repo_path="$GITHUB_ROOT/$r"
        local branch="$(_repo_branch "$repo_path")"
        local dirty_count="$(_repo_dirty_count "$repo_path")"

        # 💻 repo icon
        # 🟢 clean = no changes
        # 🔴 dirty = has uncommitted changes
        if [[ "$dirty_count" != "0" ]]; then
          printf " %2d) 💽  %b%-30s%b  (%s)  🔴 dirty (%s)\n" \
            "$i" "$C_RED" "$r" "$C_RST" "$branch" "$dirty_count"
        else
          printf " %2d) 💽  %b%-30s%b  (%s)  🟢 clean\n" \
            "$i" "$C_GRN" "$r" "$C_RST" "$branch"
        fi
        ((i++))
      done
    fi

    # Navigation + actions (always visible)
    printf " %b b) ⬅️  Back to Account Menu%b\n" "$C_CYN" "$C_RST"
    printf " %b r) 📂 Stay in GitHub root%b\n" "$C_YLW" "$C_RST"
    printf " %b c) ➕ Create new repo folder%b\n" "$C_GRN" "$C_RST"
    printf " %b 0) 🚪 Exit selector%b\n" "$C_RED" "$C_RST"


    # Read input (we use REPLY as the raw input)
    echo " "
    read -rp "Enter your choice: " REPLY

    # Exit selector
    if [[ "$REPLY" == "0" ]]; then
      _commit_reminder_if_dirty
      echo "✅ Exiting selector."
      echo " "
      return 0
    fi

    # Back to account menu
    if [[ "$REPLY" == "b" || "$REPLY" == "B" ]]; then
      _commit_reminder_if_dirty
      echo "⬅️ Back to Account Menu..."
      return 99
    fi

    # Stay in root
    if [[ "$REPLY" == "r" || "$REPLY" == "R" ]]; then
      _commit_reminder_if_dirty
      cd "$GITHUB_ROOT" || echo "⚠️ Could not cd to root."
      echo "📂 Staying in: $(pwd)"
      return 0
    fi

    # Create new folder (repo folder scaffolding is optional; you can git init later)
    if [[ "$REPLY" == "c" || "$REPLY" == "C" ]]; then
      read -rp "📁 New folder name: " newproj
      if [[ -n "$newproj" ]]; then
        mkdir -p "$GITHUB_ROOT/$newproj"
        echo "✅ Created: $GITHUB_ROOT/$newproj"
      else
        echo "⚠️ No name entered."
      fi
      # Loop continues (menu redraw)
      continue
    fi

    # Clear filter
    if [[ "$REPLY" == "/" ]]; then
      filter=""
      continue
    fi

    # Set filter: /text
    if [[ "$REPLY" == /* ]]; then
      filter="${REPLY#/}"
      continue
    fi

    # Numeric selection -> open repo
    if [[ "$REPLY" =~ ^[0-9]+$ ]]; then
      local idx=$((REPLY - 1))
      if [[ $idx -ge 0 && $idx -lt ${#shown[@]} ]]; then
        cd "$GITHUB_ROOT/${shown[$idx]}" || { echo "❌ Failed to switch."; continue; }
        echo "📂 Switched to project: $(pwd)"
        return 0
      else
        echo "⚠️ Invalid number."
        continue
      fi
    fi

    echo "⚠️ Invalid input. Use a number, /text, b, r, c, or 0."
  done
}


# ----------------------------------------------------
# 🔍 Prompt Format Legend:
# ----------------------------------------------------
#   ${GIT_ACCOUNT}        = Custom label set by git_set_work or git_set_personal
#   \[\033[32m\]          = Green text for username@host
#   \[\033[35m\]          = Purple text for current working directory
#   \[\033[36m\]          = Cyan text for the Git branch (e.g., (main))
#   $(__git_ps1 '(%s)')   = Shows current Git branch name, e.g., (dev)
#   \[\033[00m\]          = Reset color formatting
#   \n\$                 = Newline + standard `$` prompt symbol


# ----------------------------------------------------
# 4️⃣ GitHub - Interactive Account Selection
# ----------------------------------------------------
# Professional main menu goals:
# ✅ Keep the account menu small: personal / work / exit
# ✅ Let the project selector handle: back / root / exit
# ✅ Back from project selector returns to account menu (rc = 99)

# Start the ssh-agent silently
eval "$(ssh-agent -s)" > /dev/null

# ----------------------------------------------------
# 📌 GitHub Roots
# ----------------------------------------------------
# Centralize your "home" folders so you only change them in one place.
GITHUB_ROOT_PERSONAL="/a/COMPANIES/JBRIC CONSULTING/GITHUB"
GITHUB_ROOT_WORK="/a/COMPANIES/APPLY DIGITAL/GITHUB"

function account-menu {
  while true; do
    echo ""
    echo "───────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
    echo ""
    echo "🔐 Select GitHub Profile:"
    echo " 1) 💻 personal"
    echo " 2) 🏢 work"
    echo " 0) 🌄 exit"
    echo " "

    # ✅ Flush any buffered keystrokes (prevents “double prompt” weirdness)
    while read -r -t 0; do read -r; done 2>/dev/null

    read -r -p "#? " choice
    choice="$(echo "$choice" | tr -d '\r' | xargs)"

    case "$choice" in
      0)
        echo " "
        echo "✅ Exiting profile selection."
        echo " "
        return 0
        ;;

      1)
        echo " "
        ssh-add -l | grep -q "id_ed25519_personal" || ssh-add ~/.ssh/id_ed25519_personal
        echo "✅ Personal SSH key loaded."
        cd "$GITHUB_ROOT_PERSONAL" || { echo "⚠️ Personal path not found."; continue; }
        git_set_personal

        # Open selector ONCE. If user presses b, come back here.
        while true; do
          select_project "$GITHUB_ROOT_PERSONAL"
          rc=$?
          if [[ $rc -eq 99 ]]; then
            break   # back to account menu
          else
            return 0  # done (repo selected / root / exit selector)
          fi
        done
        ;;

      2)
        echo " "
        ssh-add -l | grep -q "id_ed25519_work" || ssh-add ~/.ssh/id_ed25519_work
        echo "✅ Work SSH key loaded."
        cd "$GITHUB_ROOT_WORK" || { echo "⚠️ Work path not found."; continue; }
        git_set_work

        while true; do
          select_project "$GITHUB_ROOT_WORK"
          rc=$?
          if [[ $rc -eq 99 ]]; then
            break
          else
            return 0
          fi
        done
        ;;

      *)
        echo " "
        echo "⚠️ Please choose 0, 1, or 2."
        ;;
    esac
  done
}


# ----------------------------------------------------
# ✅ Run the account menu ONLY for interactive shells
# ----------------------------------------------------
# Why:
# - Prevents “double prompt / press twice” issues when using: source ~/.bash_profile
# - Still runs automatically when you open a new Git Bash window
# - You can always run it manually with: account-menu

case $- in
  *i*)
    if [[ -z "${__GIT_PROFILE_MENU_STARTED:-}" ]]; then
      export __GIT_PROFILE_MENU_STARTED=1
      account-menu
    fi
    ;;
esac


# -----------------------------------------------------
# 5️⃣ Git-aware Terminal Setup for Windows Git Bash
# -----------------------------------------------------

# ✅ Loads __git_ps1 helper (for showing current Git branch in prompt)
# - This function is part of Git's official helper scripts (git-prompt.sh)
# - On Git Bash for Windows, it may NOT be available by default

# 🔽 To download it manually:
#   curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh \
#     -o ~/.git-completion/git-prompt.sh

# ✅ Fixes line ending issues that cause syntax errors in Git Bash
# - git-prompt.sh may have Windows-style CRLF line endings (`\r\n`)
# - Bash expects Unix-style LF line endings (`\n`)

# ❌ If you see errors like:
#   ^M: command not found
#   bash: syntax error near unexpected token `)'

# 🔧 Then convert the file using:
#   dos2unix ~/.git-completion/git-prompt.sh

# 📌 This ensures Bash can parse the script correctly and load __git_ps1

# -----------------------------------------------------
# 💡 How to check if `dos2unix` is installed:
# -----------------------------------------------------
# Run:
#   command -v dos2unix
#
# ✅ If it returns a path (e.g., /usr/bin/dos2unix), it's installed.
# ❌ If it returns nothing, install it using:

#   pacman -S dos2unix
#   (Only works if you have Git Bash with pacman/MINGW installed)

# 🧩 Alternative installation method:
# - Reinstall Git Bash and during setup, select:
#     "Use Git and optional Unix tools from the Command Prompt"
#
# OR download a Windows-compatible binary from:
#   https://waterlan.home.xs4all.nl/dos2unix.html


# Set GCP SDK paths explicitly
export CLOUD_SDK_HOME="/c/GCP_SDK/google-cloud-sdk"
export CLOUDSDK_PYTHON="$CLOUD_SDK_HOME/platform/bundledpython/python.exe"
export PATH="$CLOUD_SDK_HOME/bin:$PATH"

# Force Git Bash to use the .cmd wrapper instead of .py
bq() {
  "$CLOUDSDK_PYTHON" "$CLOUD_SDK_HOME/platform/bq/bq.py" "$@"
}

# Open PowerShell with admin permission and paste: icacls "C:\GCP_SDK" /grant "$($env:USERNAME):(F)" /T
# This grants full access permissions to the current user on the folder C:\GCP_SDK and all its contents.


# ----------------------------------------------------
# 6️⃣ Convenience Commands
# ----------------------------------------------------
# Quick ways to open the selector manually after your shell is already open.

projects() {
  local root=""

  if [[ "$PWD" == "$GITHUB_ROOT_PERSONAL"* ]]; then
    root="$GITHUB_ROOT_PERSONAL"
  elif [[ "$PWD" == "$GITHUB_ROOT_WORK"* ]]; then
    root="$GITHUB_ROOT_WORK"
  elif [[ "$GIT_ACCOUNT" == *"PERSONAL"* ]]; then
    root="$GITHUB_ROOT_PERSONAL"
  elif [[ "$GIT_ACCOUNT" == *"WORK"* ]]; then
    root="$GITHUB_ROOT_WORK"
  else
    echo "⚠️ Not in a GitHub root and no profile selected."
    account-menu
    return
  fi

  while true; do
    select_project "$root"
    rc=$?

    if [[ $rc -eq 99 ]]; then
      # Back requested → show profile menu
      account-menu
      return
    else
      return
    fi
  done
}



alias ps='projects'

