# =============================================================
# lib/projects.sh — Project selector
# =============================================================
# Provides:
#   select_project [GITHUB_ROOT]
#
# Controls:
#   [number]  — open repo and trigger branch selector
#   /text     — filter repos by name
#   /         — clear filter
#   b         — back to account menu (return 99)
#   r         — stay in GitHub root
#   c         — create new repo folder
#   0         — exit selector
#
# Return codes:
#   0  = done (repo selected / stayed in root / exit)
#   99 = back to account menu
# =============================================================

function select_project {
  local GITHUB_ROOT="${1:-$PWD}"

  local C_RED="\033[31m"
  local C_GRN="\033[32m"
  local C_YLW="\033[33m"
  local C_CYN="\033[36m"
  local C_RST="\033[0m"

  # --------------------------------------------------
  # Helper: warn about uncommitted changes before leaving
  # --------------------------------------------------
  _commit_reminder_if_dirty() {
    if git rev-parse --is-inside-work-tree &>/dev/null; then
      if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
        echo ""
        echo -e "${C_YLW}⚠️  Commit reminder:${C_RST} Your CURRENT repo has uncommitted changes:"
        git status -sb
        echo ""
        echo "💡 To commit now:"
        echo "   git add -A"
        echo "   git commit -m \"<message>\""
        echo ""
        echo "✅ Commits are local — only 'git push' needs GitHub/SSH."
        echo ""
      fi
    fi
  }

  # --------------------------------------------------
  # Helpers: branch name + dirty file count
  # --------------------------------------------------
  _repo_branch() {
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

  # Collect only actual git repos (folders with .git)
  shopt -s nullglob
  local project_dirs=("$GITHUB_ROOT"/*/)
  shopt -u nullglob

  local repos=()
  local dir
  for dir in "${project_dirs[@]}"; do
    [[ -d "$dir/.git" ]] && repos+=("$(basename "$dir")")
  done

  echo "📁 Base folder: $GITHUB_ROOT"
  echo ""
  echo "───────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
  echo ""
  echo "🧭 Controls: [number]=open  /text=search  /=clear  b=back  r=root  c=create  0=exit"
  echo ""

  # No repos found — minimal menu
  if [[ ${#repos[@]} -eq 0 ]]; then
    echo "⚠️ No Git repositories found here (no .git folders)."
    printf " %b b) ⬅️  Back to Account Menu%b\n" "$C_CYN" "$C_RST"
    printf " %b r) 📂 Stay in GitHub root%b\n" "$C_YLW" "$C_RST"
    printf " %b 0) 🚪 Exit selector%b\n" "$C_RED" "$C_RST"
    while true; do
      echo " "
      read -rp "Enter your choice: " REPLY
      case "$REPLY" in
        0) _commit_reminder_if_dirty; echo "🌄 Exiting."; return 0 ;;
        b|B) _commit_reminder_if_dirty; echo "⬅️ Back to Account Menu..."; return 99 ;;
        r|R) _commit_reminder_if_dirty; cd "$GITHUB_ROOT" || echo "⚠️ Could not cd to root."; return 0 ;;
        *) echo "⚠️ Invalid input. Use b, r, or 0." ;;
      esac
    done
  fi

  local filter=""

  while true; do
    # Build filtered list
    local shown=()
    local r
    for r in "${repos[@]}"; do
      if [[ -z "$filter" || "${r,,}" == *"${filter,,}"* ]]; then
        shown+=("$r")
      fi
    done

    [[ -n "$filter" ]] && echo -e "🔎 Filter: ${C_CYN}${filter}${C_RST}  (type / to clear)"

    if [[ ${#shown[@]} -eq 0 ]]; then
      echo "⚠️ No matches. Try another /search or type / to clear."
    else
      local i=1
      for r in "${shown[@]}"; do
        local repo_path="$GITHUB_ROOT/$r"
        local branch dirty_count
        branch="$(_repo_branch "$repo_path")"
        dirty_count="$(_repo_dirty_count "$repo_path")"
        if [[ "$dirty_count" != "0" ]]; then
          printf " %2d) 💽  %b%-30s%b  (%s)  🔴 dirty (%s)\n" "$i" "$C_RED" "$r" "$C_RST" "$branch" "$dirty_count"
        else
          printf " %2d) 💽  %b%-30s%b  (%s)  🟢 clean\n" "$i" "$C_GRN" "$r" "$C_RST" "$branch"
        fi
        ((i++))
      done
    fi

    printf " %b b) ⬅️  Back to Account Menu%b\n" "$C_CYN" "$C_RST"
    printf " %b r) 📂 Stay in GitHub root%b\n" "$C_YLW" "$C_RST"
    printf " %b c) ➕ Create new repo folder%b\n" "$C_GRN" "$C_RST"
    printf " %b 0) 🚪 Exit selector%b\n" "$C_RED" "$C_RST"

    echo " "
    read -rp "Enter your choice: " REPLY

    case "$REPLY" in
      0)
        _commit_reminder_if_dirty; echo "✅ Exiting selector."; echo " "; return 0 ;;
      b|B)
        _commit_reminder_if_dirty; echo "⬅️ Back to Account Menu..."; return 99 ;;
      r|R)
        _commit_reminder_if_dirty
        cd "$GITHUB_ROOT" || echo "⚠️ Could not cd to root."
        echo "📂 Staying in: $(pwd)"; return 0 ;;
      c|C)
        read -rp "📁 New folder name: " newproj
        if [[ -n "$newproj" ]]; then
          mkdir -p "$GITHUB_ROOT/$newproj"
          echo "✅ Created: $GITHUB_ROOT/$newproj"
        else
          echo "⚠️ No name entered."
        fi
        continue ;;
      /)
        filter=""; continue ;;
      /*)
        filter="${REPLY#/}"; continue ;;
      *)
        if [[ "$REPLY" =~ ^[0-9]+$ ]]; then
          local idx=$(( REPLY - 1 ))
          if [[ $idx -ge 0 && $idx -lt ${#shown[@]} ]]; then
            local selected_repo="${shown[$idx]}"
            cd "$GITHUB_ROOT/$selected_repo" || { echo "❌ Failed to switch."; continue; }
            echo "📂 Switched to: $selected_repo"
            # Offer branch actions after opening repo
            select_branch
            return 0
          else
            echo "⚠️ Invalid number."
          fi
        else
          echo "⚠️ Invalid input. Use a number, /text, b, r, c, or 0."
        fi
        ;;
    esac
  done
}
