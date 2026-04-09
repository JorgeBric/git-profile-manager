# =============================================================
# Git Profile Manager — v2.0
# =============================================================
# Version: 2.0
# Updated: 2026-04-09
# Changes: Config-driven multi-account system. All account data
#          moved to ~/.git-profile-manager/config.sh. Modular
#          lib/ architecture. Added: branch selector, settings
#          wizard (add/edit/remove accounts), help reference,
#          autorun toggle (gpm-enable / gpm-disable).
#
# Original single-file version archived as: bash_profile_v1.sh
# =============================================================
#
# To activate: add this line to your ~/.bash_profile
#   source "/a/COMPANIES/JBRIC CONSULTING/GITHUB/git-profile-manager/bash_profile"
#
# Quick commands (available after sourcing):
#   am            — open account menu
#   gpm-enable    — enable autorun on terminal open
#   gpm-disable   — disable autorun on terminal open
#   git-whoami    — show current git identity
#   select_branch — open branch switcher for current repo
# =============================================================

# Resolve the directory this file lives in, regardless of where it's sourced from
GPM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ----------------------------------------------------
# Source lib modules (order matters: prompt + config first)
# ----------------------------------------------------
source "$GPM_DIR/lib/prompt.sh"
source "$GPM_DIR/lib/config.sh"
source "$GPM_DIR/lib/accounts.sh"
source "$GPM_DIR/lib/projects.sh"
source "$GPM_DIR/lib/branches.sh"
source "$GPM_DIR/lib/setup.sh"
source "$GPM_DIR/lib/help.sh"

# ----------------------------------------------------
# Load user config
# Auto-generates ~/.git-profile-manager/config.sh on first run
# (migrates the two original hardcoded accounts automatically)
# ----------------------------------------------------
load_config

# ----------------------------------------------------
# GCP SDK paths
# ----------------------------------------------------
export CLOUD_SDK_HOME="/c/GCP_SDK/google-cloud-sdk"
export CLOUDSDK_PYTHON="$CLOUD_SDK_HOME/platform/bundledpython/python.exe"
export PATH="$CLOUD_SDK_HOME/bin:$PATH"

bq() {
  "$CLOUDSDK_PYTHON" "$CLOUD_SDK_HOME/platform/bq/bq.py" "$@"
}

# ----------------------------------------------------
# SSH agent — starts once, cleans up on shell exit
# ----------------------------------------------------
eval "$(ssh-agent -s)" > /dev/null 2>&1
trap 'kill $SSH_AGENT_PID' EXIT

# ----------------------------------------------------
# Welcome message + dynamic prompt
# ----------------------------------------------------
echo -e "Hello, Jorge. What a beautiful $(date +%A)!!! 🐢"
set_git_prompt

# ----------------------------------------------------
# Launch account menu for interactive shells only
# Respects the autorun toggle (gpm-disable / gpm-enable)
# ----------------------------------------------------
case $- in
  *i*)
    if [[ -z "${__GIT_PROFILE_MENU_STARTED:-}" ]]; then
      export __GIT_PROFILE_MENU_STARTED=1
      if [[ ! -f "$HOME/.git-profile-manager/autorun.disabled" ]]; then
        account-menu
      else
        echo "ℹ️  Git Profile Manager autorun is disabled. Type 'am' to launch manually."
      fi
    fi
    ;;
esac
