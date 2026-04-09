# =============================================================
# lib/accounts.sh — Dynamic account menu + identity switching
# =============================================================
# Provides:
#   account-menu      — main interactive profile selector (dynamic)
#   git_set_account N — apply git identity + SSH key for account N
#   git-whoami        — print current git identity
#   gpm-enable        — enable autorun on terminal open
#   gpm-disable       — disable autorun on terminal open
#
# Aliases:
#   am  → account-menu
# =============================================================

export GIT_ACCOUNT=""

# ----------------------------------------------------
# git_set_account N
# Sets git user.name, user.email, GIT_ACCOUNT label,
# loads the SSH key, and refreshes the prompt.
# ----------------------------------------------------
function git_set_account {
  local n="$1"
  local git_name git_email ssh_key label

  git_name="$(get_account_field "$n" GIT_NAME)"
  git_email="$(get_account_field "$n" GIT_EMAIL)"
  ssh_key="$(get_account_field "$n" SSH_KEY)"
  label="$(get_account_field "$n" LABEL)"

  git config user.name "$git_name" 2>/dev/null
  git config user.email "$git_email" 2>/dev/null
  export GIT_ACCOUNT="[$label]"
  set_git_prompt
  echo "✅ Git identity set: $git_name <$git_email>"
}

# ----------------------------------------------------
# git-whoami
# Shows the current git identity in the active repo.
# ----------------------------------------------------
function git-whoami {
  echo "👤 Current Git identity:"
  echo "   Name:  $(git config user.name 2>/dev/null || echo '(not set)')"
  echo "   Email: $(git config user.email 2>/dev/null || echo '(not set)')"
  if [[ -n "$GIT_ACCOUNT" ]]; then
    echo "   Profile: $GIT_ACCOUNT"
  fi
}

# ----------------------------------------------------
# account-menu
# Reads ACCOUNT_COUNT from config and renders the menu
# dynamically. No code changes needed to add accounts.
# ----------------------------------------------------
function account-menu {
  while true; do
    # Reload config so changes from setup wizard are reflected
    source "$GPM_CONFIG_FILE"
    local count="${ACCOUNT_COUNT:-0}"

    echo ""
    echo "───────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
    echo ""
    echo "🔐 Select GitHub Profile:"

    local i
    for (( i = 1; i <= count; i++ )); do
      local label
      label="$(get_account_field "$i" LABEL)"
      printf "  %d) %s\n" "$i" "$label"
    done

    echo "  ─────────────────────────────"
    echo "  s) ⚙️  Settings"
    echo "  h) ❓ Help"
    echo "  0) 🌄 Exit"
    echo " "

    # Flush buffered keystrokes
    while read -r -t 0; do read -r; done 2>/dev/null

    read -r -p "#? " choice
    choice="$(echo "$choice" | tr -d '\r' | xargs)"

    case "$choice" in
      0)
        echo " "; echo "✅ Exiting profile selection."; echo " "
        return 0
        ;;

      s|S)
        settings-menu
        ;;

      h|H)
        help-menu
        ;;

      *)
        # Numeric account selection
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 && $choice -le $count ]]; then
          local n="$choice"
          local ssh_key github_root label
          ssh_key="$(get_account_field "$n" SSH_KEY)"
          github_root="$(get_account_field "$n" GITHUB_ROOT)"
          label="$(get_account_field "$n" LABEL)"

          echo " "
          # Load SSH key if not already loaded
          ssh-add -l 2>/dev/null | grep -q "$ssh_key" || ssh-add "$HOME/.ssh/$ssh_key" 2>/dev/null
          echo "✅ SSH key loaded: $ssh_key"

          # Navigate to github root
          if [[ -d "$github_root" ]]; then
            cd "$github_root" || true
          else
            echo "⚠️ GitHub root not found: $github_root"
            echo "   You can update this path in Settings → Edit account."
          fi

          git_set_account "$n"

          # Open project selector; return 99 means "back to account menu"
          while true; do
            select_project "$github_root"
            local rc=$?
            if [[ $rc -eq 99 ]]; then
              break
            else
              return 0
            fi
          done
        else
          echo " "; echo "⚠️ Invalid choice. Enter a number between 1 and $count, s, h, or 0."
        fi
        ;;
    esac
  done
}

# ----------------------------------------------------
# Autorun toggle commands
# ----------------------------------------------------
function gpm-disable {
  mkdir -p "$GPM_CONFIG_DIR"
  touch "$GPM_CONFIG_DIR/autorun.disabled"
  echo "⏸️  Autorun disabled. Type 'am' to launch the menu manually."
}

function gpm-enable {
  rm -f "$GPM_CONFIG_DIR/autorun.disabled"
  echo "✅ Autorun enabled. The menu will launch on next terminal open."
}

# Convenience alias
alias am='account-menu'
