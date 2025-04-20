# -----------------------------------------------------
# Version Control
# -----------------------------------------------------
# Version: 1.0 – Jorge's Git Prompt Setup
# Updated: 2025-04-19
# Comments: Initial setup 
# -----------------------------------------------------
# Version: 1.1 – Jorge's Git Prompt Setup
# Updated: 2025-04-20
# Comments: Improves project folder management and confirmation message before switching accounts
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
  echo "✅ Git is now set to use your PERSONAL account."

  # If currently in a GITHUB root, offer project selection
  if [[ "${PWD##*/}" == "GITHUB" ]]; then
    select_project
  fi
}

# Function to set work identity and update prompt
function git_set_work {
  git config user.name "Jorge-B-AD" 2>/dev/null
  git config user.email "jorge.briceno@applydigital.com" 2>/dev/null
  export GIT_ACCOUNT="[WORK] 🏢"
  set_git_prompt
  echo "✅ Git is now set to use your WORK account."

  # If currently in a GITHUB root, offer project selection
  if [[ "${PWD##*/}" == "GITHUB" ]]; then
    select_project
  fi
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

function select_project {
  local GITHUB_ROOT="${1:-$PWD}"  # Use current directory if no argument provided

  shopt -s nullglob
  local project_dirs=("$GITHUB_ROOT"/*/)
  shopt -u nullglob

  local options=()
  for dir in "${project_dirs[@]}"; do
    [[ -d "$dir" ]] && options+=("$(basename "$dir")")
  done

  # Add fallback options
  options+=("❌ No project - stay here" "➕ Create new project folder")

  echo "📁 Detected base GitHub folder: $GITHUB_ROOT"
  echo "🗃️  Let's choose a project (or skip)..."

  local PS3="Enter your choice: "
  select project in "${options[@]}"; do
    case "$project" in
      "❌ No project - stay here")
        echo "📌 You will continue without selecting a project."
        echo "💡 To choose a project later, run:"
        echo "    select_project \"$GITHUB_ROOT\""
        break
        ;;
      "➕ Create new project folder")
        read -rp "📁 Enter the name for your new project folder: " newproj
        if [[ -n "$newproj" ]]; then
          mkdir -p "$GITHUB_ROOT/$newproj"
          cd "$GITHUB_ROOT/$newproj" || echo "❌ Could not enter new project."
          echo "✅ Created and moved into: $(pwd)"
        else
          echo "⚠️ No name entered. Staying in: $(pwd)"
        fi
        break
        ;;
      "")
        echo "⚠️ Invalid selection. Try again."
        ;;
      *)
        # 🧪 Git dirty check before switching
        if git rev-parse --is-inside-work-tree &>/dev/null; then
          if [[ -n $(git status --porcelain) ]]; then
            echo "⚠️ Uncommitted changes detected in $(pwd):"
            git status -s
            read -rp "❗ Switch projects anyway? (y/n): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
              cd "$GITHUB_ROOT/$project" || echo "❌ Failed to switch."
              echo "📂 Switched to project: $(pwd)"
              break
            else
              echo "🛑 Staying in current project."
              break
            fi
          fi
        fi

        cd "$GITHUB_ROOT/$project" || echo "❌ Failed to switch."
        echo "📂 Switched to project: $(pwd)"
        break
        ;;
    esac
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

# Start the ssh-agent silently
eval "$(ssh-agent -s)" > /dev/null

# Prompt: which SSH key would you like to use this session?
echo "🔐 Which SSH key would you like to use this session?"
select ACCOUNT in "personal" "work" "none"; do
  case $ACCOUNT in
    personal)
      ssh-add -l | grep -q "id_ed25519_personal" || ssh-add ~/.ssh/id_ed25519_personal
      echo "✅ Personal SSH key loaded."
      cd "/a/COMPANIES/JBRIC CONSULTING/GITHUB" || echo "⚠️ Personal path not found."
      git_set_personal
      #select_project
      break;;
    work)
      ssh-add -l | grep -q "id_ed25519_work" || ssh-add ~/.ssh/id_ed25519_work
      echo "✅ Work SSH key loaded."
      cd "/a/COMPANIES/APPLY DIGITAL/GITHUB" || echo "⚠️ Work path not found."
      git_set_work
      #select_project
      break;;
    none)
      echo "❎ No SSH key loaded for this session."
      break;;
    *) echo "⚠️ Please choose a valid option."; continue;;
  esac
done


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


