# =============================================================
# lib/branches.sh — Branch selector and switcher
# =============================================================
# Provides:
#   select_branch   — interactive branch menu for current repo
#
# Called automatically after opening a repo in projects.sh.
# Can also be called manually: select_branch
#
# Controls:
#   [number]  — switch to that branch
#   n         — create and switch to a new branch
#   b         — back (stay on current branch)
# =============================================================

function select_branch {
  # Must be inside a git repo
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    return 0
  fi

  local C_GRN="\033[32m"
  local C_CYN="\033[36m"
  local C_YLW="\033[33m"
  local C_RST="\033[0m"

  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  echo ""
  echo "───────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
  echo ""
  echo "🌿 Branch actions for: $(basename "$PWD") (current: $current_branch)"
  echo ""
  echo "  1) 🌿 Switch branch"
  echo "  2) ➕ Create new branch"
  echo "  3) ✅ Stay on $current_branch"
  echo " "

  read -rp "#? " choice
  choice="$(echo "$choice" | tr -d '\r' | xargs)"

  case "$choice" in
    1)
      _branch_switcher ;;
    2)
      _branch_create ;;
    3|"")
      echo "✅ Staying on branch: $current_branch" ;;
    *)
      echo "⚠️ Invalid choice. Staying on: $current_branch" ;;
  esac
}

# --------------------------------------------------
# _branch_switcher — list branches, let user pick one
# --------------------------------------------------
function _branch_switcher {
  local C_GRN="\033[32m"
  local C_CYN="\033[36m"
  local C_RST="\033[0m"

  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  # Get all local branches
  local branches=()
  while IFS= read -r line; do
    # Strip leading "* " from current branch marker
    branch="${line#\* }"
    branch="${branch#  }"
    branch="$(echo "$branch" | tr -d '\r' | xargs)"
    [[ -n "$branch" ]] && branches+=("$branch")
  done < <(git branch 2>/dev/null)

  if [[ ${#branches[@]} -eq 0 ]]; then
    echo "⚠️ No branches found. This repo may not have any commits yet."
    return
  fi

  echo ""
  echo "🌿 Select a branch:"
  echo ""

  local i=1
  for b in "${branches[@]}"; do
    if [[ "$b" == "$current_branch" ]]; then
      printf "  %2d) %b%-35s%b ✅ current\n" "$i" "$C_GRN" "$b" "$C_RST"
    else
      printf "  %2d) %-35s\n" "$i" "$b"
    fi
    ((i++))
  done

  printf "  %b  b) ⬅️  Back (stay on %s)%b\n" "$C_CYN" "$current_branch" "$C_RST"
  echo " "

  read -rp "Enter your choice: " REPLY
  REPLY="$(echo "$REPLY" | tr -d '\r' | xargs)"

  if [[ "$REPLY" == "b" || "$REPLY" == "B" || -z "$REPLY" ]]; then
    echo "✅ Staying on: $current_branch"
    return
  fi

  if [[ "$REPLY" =~ ^[0-9]+$ ]]; then
    local idx=$(( REPLY - 1 ))
    if [[ $idx -ge 0 && $idx -lt ${#branches[@]} ]]; then
      local target="${branches[$idx]}"
      if [[ "$target" == "$current_branch" ]]; then
        echo "✅ Already on: $target"
      else
        git checkout "$target"
        echo "✅ Switched to: $target"
      fi
    else
      echo "⚠️ Invalid number. Staying on: $current_branch"
    fi
  else
    echo "⚠️ Invalid input. Staying on: $current_branch"
  fi
}

# --------------------------------------------------
# _branch_create — prompt for name, create + switch
# --------------------------------------------------
function _branch_create {
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  echo ""
  read -rp "🌿 New branch name: " new_branch
  new_branch="$(echo "$new_branch" | tr -d '\r' | xargs)"

  if [[ -z "$new_branch" ]]; then
    echo "⚠️ No name entered. Staying on: $current_branch"
    return
  fi

  # Validate: no spaces, no special chars except - and /
  if [[ ! "$new_branch" =~ ^[a-zA-Z0-9/_-]+$ ]]; then
    echo "⚠️ Branch name can only contain letters, numbers, /, -, _"
    echo "   Staying on: $current_branch"
    return
  fi

  git checkout -b "$new_branch"
  echo "✅ Created and switched to: $new_branch"
}
