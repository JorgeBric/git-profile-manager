# =============================================================
# lib/setup.sh — Account settings wizard
# =============================================================
# Provides:
#   settings-menu        — main settings menu (add/edit/remove)
#   add_account_wizard   — guided step-by-step account creation
#   edit_account         — update any field of an existing account
#   remove_account_safe  — remove account from menu (no folders deleted)
# =============================================================

# ----------------------------------------------------
# settings-menu
# ----------------------------------------------------
function settings-menu {
  while true; do
    source "$GPM_CONFIG_FILE"
    local count="${ACCOUNT_COUNT:-0}"

    echo ""
    echo "───────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
    echo ""
    echo "⚙️  Account Settings  (${count} account(s) configured)"
    echo ""
    echo "  1) ➕ Add new account"
    echo "  2) ✏️  Edit account"
    echo "  3) 🗑️  Remove account  (menu only — folders are never deleted)"
    echo "  b) ⬅️  Back"
    echo " "

    read -rp "#? " choice
    choice="$(echo "$choice" | tr -d '\r' | xargs)"

    case "$choice" in
      1) add_account_wizard ;;
      2) edit_account ;;
      3) remove_account_safe ;;
      b|B|0) return 0 ;;
      *) echo "⚠️ Invalid choice. Enter 1, 2, 3, or b." ;;
    esac
  done
}

# ----------------------------------------------------
# add_account_wizard
# Step-by-step guided flow to create a new account.
# ----------------------------------------------------
function add_account_wizard {
  echo ""
  echo "───────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
  echo ""
  echo "➕ Add New Account — follow the steps below."
  echo "   Press Enter to accept the suggested value [in brackets]."
  echo ""

  # Step 1: Label
  read -rp "1️⃣  Account label (e.g. Freelance, ACME Corp): " label
  label="$(echo "$label" | tr -d '\r' | xargs)"
  if [[ -z "$label" ]]; then echo "⚠️ Label is required."; return 1; fi

  # Derive a safe ID from the label (lowercase, spaces→underscore)
  local id
  id="$(echo "$label" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')"

  # Step 2: Git username
  read -rp "2️⃣  Git username (your name as it appears in commits): " git_name
  git_name="$(echo "$git_name" | tr -d '\r' | xargs)"
  if [[ -z "$git_name" ]]; then echo "⚠️ Git username is required."; return 1; fi

  # Step 3: Git email
  read -rp "3️⃣  Git email: " git_email
  git_email="$(echo "$git_email" | tr -d '\r' | xargs)"
  if [[ -z "$git_email" ]]; then echo "⚠️ Git email is required."; return 1; fi

  # Step 4: SSH key filename
  local suggested_key="id_ed25519_${id}"
  read -rp "4️⃣  SSH key filename [$suggested_key]: " ssh_key
  ssh_key="$(echo "$ssh_key" | tr -d '\r' | xargs)"
  [[ -z "$ssh_key" ]] && ssh_key="$suggested_key"

  # Step 5: GitHub root path
  read -rp "5️⃣  GitHub root folder path (e.g. /a/COMPANIES/ACME/GITHUB): " github_root
  github_root="$(echo "$github_root" | tr -d '\r' | xargs)"
  if [[ -z "$github_root" ]]; then echo "⚠️ GitHub root path is required."; return 1; fi

  # Step 6: Optionally generate SSH key
  echo ""
  echo "6️⃣  Generate SSH key now?"
  read -rp "   [y/N]: " gen_key
  gen_key="$(echo "$gen_key" | tr -d '\r' | xargs | tr '[:upper:]' '[:lower:]')"

  if [[ "$gen_key" == "y" || "$gen_key" == "yes" ]]; then
    local key_path="$HOME/.ssh/$ssh_key"
    if [[ -f "$key_path" ]]; then
      echo "⚠️ Key already exists at: $key_path"
      echo "   Skipping key generation to avoid overwriting."
    else
      echo ""
      echo "🔑 Generating SSH key: $key_path"
      ssh-keygen -t ed25519 -C "$git_email" -f "$key_path" -N ""
      echo ""
      echo "📋 Your public key (copy and paste into GitHub → Settings → SSH Keys):"
      echo "───────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
      cat "${key_path}.pub"
      echo "───────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
      echo ""
      echo "👉 Go to: https://github.com/settings/keys → New SSH key"
      echo "   Paste the key above, give it a title (e.g. \"$label\"), and click Add SSH key."
      echo ""
      read -rp "   Press Enter when done to continue..." _
    fi
  fi

  # Save to config
  source "$GPM_CONFIG_FILE"
  local new_n=$(( ${ACCOUNT_COUNT:-0} + 1 ))

  save_account "$new_n" "$id" "$label" "$git_name" "$git_email" "$ssh_key" "$github_root"

  echo ""
  echo "✅ Account '$label' saved as account #${new_n}."
  echo "   It will appear in the menu next time you open account-menu."
  echo ""
}

# ----------------------------------------------------
# edit_account
# Shows all accounts, user picks one, then edits fields.
# ----------------------------------------------------
function edit_account {
  source "$GPM_CONFIG_FILE"
  local count="${ACCOUNT_COUNT:-0}"

  if [[ $count -eq 0 ]]; then
    echo "⚠️ No accounts configured yet. Use 'Add new account' first."
    return
  fi

  echo ""
  echo "✏️  Which account would you like to edit?"
  echo ""

  local i
  for (( i = 1; i <= count; i++ )); do
    local label
    label="$(get_account_field "$i" LABEL)"
    printf "  %d) %s\n" "$i" "$label"
  done
  echo "  b) Back"
  echo " "

  read -rp "#? " choice
  choice="$(echo "$choice" | tr -d '\r' | xargs)"

  if [[ "$choice" == "b" || "$choice" == "B" ]]; then return; fi

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || [[ $choice -lt 1 || $choice -gt $count ]]; then
    echo "⚠️ Invalid choice."; return
  fi

  local n="$choice"

  # Load current values
  local cur_id cur_label cur_git_name cur_git_email cur_ssh_key cur_github_root
  cur_id="$(get_account_field "$n" ID)"
  cur_label="$(get_account_field "$n" LABEL)"
  cur_git_name="$(get_account_field "$n" GIT_NAME)"
  cur_git_email="$(get_account_field "$n" GIT_EMAIL)"
  cur_ssh_key="$(get_account_field "$n" SSH_KEY)"
  cur_github_root="$(get_account_field "$n" GITHUB_ROOT)"

  echo ""
  echo "✏️  Editing: $cur_label  (press Enter to keep current value)"
  echo ""

  read -rp "1️⃣  Label         [$cur_label]: " new_label
  new_label="$(echo "$new_label" | tr -d '\r' | xargs)"
  [[ -z "$new_label" ]] && new_label="$cur_label"

  read -rp "2️⃣  Git name      [$cur_git_name]: " new_git_name
  new_git_name="$(echo "$new_git_name" | tr -d '\r' | xargs)"
  [[ -z "$new_git_name" ]] && new_git_name="$cur_git_name"

  read -rp "3️⃣  Git email     [$cur_git_email]: " new_git_email
  new_git_email="$(echo "$new_git_email" | tr -d '\r' | xargs)"
  [[ -z "$new_git_email" ]] && new_git_email="$cur_git_email"

  read -rp "4️⃣  SSH key       [$cur_ssh_key]: " new_ssh_key
  new_ssh_key="$(echo "$new_ssh_key" | tr -d '\r' | xargs)"
  [[ -z "$new_ssh_key" ]] && new_ssh_key="$cur_ssh_key"

  read -rp "5️⃣  GitHub root   [$cur_github_root]: " new_github_root
  new_github_root="$(echo "$new_github_root" | tr -d '\r' | xargs)"
  [[ -z "$new_github_root" ]] && new_github_root="$cur_github_root"

  echo ""
  echo "📋 Summary of changes:"
  printf "   Label:       %s → %s\n" "$cur_label"       "$new_label"
  printf "   Git name:    %s → %s\n" "$cur_git_name"    "$new_git_name"
  printf "   Git email:   %s → %s\n" "$cur_git_email"   "$new_git_email"
  printf "   SSH key:     %s → %s\n" "$cur_ssh_key"     "$new_ssh_key"
  printf "   GitHub root: %s → %s\n" "$cur_github_root" "$new_github_root"
  echo ""

  read -rp "Save changes? [Y/n]: " confirm
  confirm="$(echo "$confirm" | tr -d '\r' | xargs | tr '[:upper:]' '[:lower:]')"

  if [[ "$confirm" == "n" || "$confirm" == "no" ]]; then
    echo "❌ Changes discarded."
    return
  fi

  # Derive new ID from new label
  local new_id
  new_id="$(echo "$new_label" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')"

  save_account "$n" "$new_id" "$new_label" "$new_git_name" "$new_git_email" "$new_ssh_key" "$new_github_root"
  echo "✅ Account #${n} updated."
}

# ----------------------------------------------------
# remove_account_safe
# Removes account from menu only. Folders are untouched.
# ----------------------------------------------------
function remove_account_safe {
  source "$GPM_CONFIG_FILE"
  local count="${ACCOUNT_COUNT:-0}"

  if [[ $count -eq 0 ]]; then
    echo "⚠️ No accounts configured."
    return
  fi

  echo ""
  echo "🗑️  Which account would you like to remove?"
  echo ""

  local i
  for (( i = 1; i <= count; i++ )); do
    local label github_root
    label="$(get_account_field "$i" LABEL)"
    github_root="$(get_account_field "$i" GITHUB_ROOT)"
    printf "  %d) %s  →  %s\n" "$i" "$label" "$github_root"
  done
  echo "  b) Back"
  echo " "

  read -rp "#? " choice
  choice="$(echo "$choice" | tr -d '\r' | xargs)"

  if [[ "$choice" == "b" || "$choice" == "B" ]]; then return; fi

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || [[ $choice -lt 1 || $choice -gt $count ]]; then
    echo "⚠️ Invalid choice."; return
  fi

  local n="$choice"
  local label github_root
  label="$(get_account_field "$n" LABEL)"
  github_root="$(get_account_field "$n" GITHUB_ROOT)"

  echo ""
  echo "⚠️  You are about to remove: $label"
  echo "   GitHub root: $github_root"
  echo ""
  echo "   ✅ Folders on disk will NOT be deleted."
  echo "   ❌ This account will no longer appear in the menu."
  echo ""
  read -rp "Confirm removal? [y/N]: " confirm
  confirm="$(echo "$confirm" | tr -d '\r' | xargs | tr '[:upper:]' '[:lower:]')"

  if [[ "$confirm" != "y" && "$confirm" != "yes" ]]; then
    echo "❌ Cancelled. Account not removed."
    return
  fi

  remove_account "$n"
  echo "✅ Account '$label' removed from the menu."
  echo "   Your folders at '$github_root' are untouched."
}
