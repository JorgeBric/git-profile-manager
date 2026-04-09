# =============================================================
# lib/config.sh — Account config read/write helpers
# =============================================================
# Config file location: ~/.git-profile-manager/config.sh
#
# Format (KEY=value, sourced directly by bash):
#   ACCOUNT_COUNT=2
#   ACCOUNT_1_ID="personal"
#   ACCOUNT_1_LABEL="🏡 PERSONAL"
#   ACCOUNT_1_GIT_NAME="JorgeBric"
#   ACCOUNT_1_GIT_EMAIL="jorgeebricenom@gmail.com"
#   ACCOUNT_1_SSH_KEY="id_ed25519_personal"
#   ACCOUNT_1_GITHUB_ROOT="/a/COMPANIES/JBRIC CONSULTING/GITHUB"
#
# Provides:
#   load_config          — load (or auto-migrate) config from file
#   save_account N       — write/update a single account block
#   remove_account N     — remove an account block and renumber
#   get_account_field N FIELD — return one field for account N
# =============================================================

GPM_CONFIG_DIR="$HOME/.git-profile-manager"
GPM_CONFIG_FILE="$GPM_CONFIG_DIR/config.sh"

# ----------------------------------------------------
# load_config
# Sources the config file. If it doesn't exist, runs
# auto-migration from the legacy hardcoded values so
# the first run after upgrading never breaks.
# ----------------------------------------------------
function load_config {
  mkdir -p "$GPM_CONFIG_DIR"

  if [[ ! -f "$GPM_CONFIG_FILE" ]]; then
    _migrate_legacy_config
  fi

  source "$GPM_CONFIG_FILE"
}

# ----------------------------------------------------
# _migrate_legacy_config
# Called once on first run. Writes the two original
# hardcoded accounts into the new config file format.
# ----------------------------------------------------
function _migrate_legacy_config {
  cat > "$GPM_CONFIG_FILE" <<'EOF'
# Git Profile Manager — Account Config
# Generated automatically on first run (migrated from v1).
# Edit via the Settings menu (s) in the account menu,
# or add/remove accounts with the guided wizard.

ACCOUNT_COUNT=2

ACCOUNT_1_ID="personal"
ACCOUNT_1_LABEL="🏡 PERSONAL"
ACCOUNT_1_GIT_NAME="JorgeBric"
ACCOUNT_1_GIT_EMAIL="jorgeebricenom@gmail.com"
ACCOUNT_1_SSH_KEY="id_ed25519_personal"
ACCOUNT_1_GITHUB_ROOT="/a/COMPANIES/JBRIC CONSULTING/GITHUB"

ACCOUNT_2_ID="work"
ACCOUNT_2_LABEL="🏢 WORK"
ACCOUNT_2_GIT_NAME="Jorge-B-AD"
ACCOUNT_2_GIT_EMAIL="jorge.briceno@applydigital.com"
ACCOUNT_2_SSH_KEY="id_ed25519_work"
ACCOUNT_2_GITHUB_ROOT="/a/COMPANIES/APPLY DIGITAL/GITHUB"
EOF
  echo "✅ Config file created at: $GPM_CONFIG_FILE"
}

# ----------------------------------------------------
# get_account_field N FIELD
# Returns the value of one field for account N.
# Example: get_account_field 1 LABEL  → "🏡 PERSONAL"
# ----------------------------------------------------
function get_account_field {
  local n="$1"
  local field="$2"
  local varname="ACCOUNT_${n}_${field}"
  echo "${!varname}"
}

# ----------------------------------------------------
# save_account N ID LABEL GIT_NAME GIT_EMAIL SSH_KEY GITHUB_ROOT
# Writes or replaces an account block in config.sh.
# If N > ACCOUNT_COUNT, appends a new block and increments count.
# ----------------------------------------------------
function save_account {
  local n="$1"
  local id="$2"
  local label="$3"
  local git_name="$4"
  local git_email="$5"
  local ssh_key="$6"
  local github_root="$7"

  source "$GPM_CONFIG_FILE"
  local count="${ACCOUNT_COUNT:-0}"

  # Build the replacement block
  local block
  block="ACCOUNT_${n}_ID=\"${id}\"
ACCOUNT_${n}_LABEL=\"${label}\"
ACCOUNT_${n}_GIT_NAME=\"${git_name}\"
ACCOUNT_${n}_GIT_EMAIL=\"${git_email}\"
ACCOUNT_${n}_SSH_KEY=\"${ssh_key}\"
ACCOUNT_${n}_GITHUB_ROOT=\"${github_root}\""

  if [[ $n -le $count ]]; then
    # Replace existing block: remove old lines for this account number
    local tmpfile
    tmpfile=$(mktemp)
    grep -v "^ACCOUNT_${n}_" "$GPM_CONFIG_FILE" > "$tmpfile"
    # Insert block before the blank line after the previous account (or at end)
    echo "" >> "$tmpfile"
    echo "$block" >> "$tmpfile"
    mv "$tmpfile" "$GPM_CONFIG_FILE"
  else
    # New account: append block and increment count
    echo "" >> "$GPM_CONFIG_FILE"
    echo "$block" >> "$GPM_CONFIG_FILE"
    # Update ACCOUNT_COUNT
    local tmpfile
    tmpfile=$(mktemp)
    sed "s/^ACCOUNT_COUNT=.*/ACCOUNT_COUNT=$((count + 1))/" "$GPM_CONFIG_FILE" > "$tmpfile"
    mv "$tmpfile" "$GPM_CONFIG_FILE"
  fi

  source "$GPM_CONFIG_FILE"
}

# ----------------------------------------------------
# remove_account N
# Removes the ACCOUNT_N_* block from config.sh and
# renumbers all higher accounts down by 1.
# Folders on disk are NEVER touched.
# ----------------------------------------------------
function remove_account {
  local n="$1"
  source "$GPM_CONFIG_FILE"
  local count="${ACCOUNT_COUNT:-0}"

  if [[ $n -lt 1 || $n -gt $count ]]; then
    echo "⚠️ Account $n does not exist."
    return 1
  fi

  local tmpfile
  tmpfile=$(mktemp)

  # Remove the target account's lines
  grep -v "^ACCOUNT_${n}_" "$GPM_CONFIG_FILE" > "$tmpfile"

  # Renumber all accounts above N down by 1
  local i
  for (( i = n + 1; i <= count; i++ )); do
    local new_i=$(( i - 1 ))
    sed -i "s/^ACCOUNT_${i}_/ACCOUNT_${new_i}_/g" "$tmpfile"
  done

  # Decrement ACCOUNT_COUNT
  sed -i "s/^ACCOUNT_COUNT=.*/ACCOUNT_COUNT=$((count - 1))/" "$tmpfile"

  mv "$tmpfile" "$GPM_CONFIG_FILE"
  source "$GPM_CONFIG_FILE"
}
