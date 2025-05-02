#!/bin/bash

# Get the directory this script resides in (assumes it is inside the repo)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BUNDLE_FILE="$REPO_DIR/brew/new/Brewfile"
LOG_FILE="$REPO_DIR/cron_brew_backup.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# -------------------------
# Step 1: Dump Homebrew bundle
# -------------------------
mkdir -p "$(dirname "$BUNDLE_FILE")"
brew bundle dump --file="$BUNDLE_FILE"

# -------------------------
# Step 2: Git commit and push
# -------------------------
cd "$REPO_DIR" || exit 1
git add "$BUNDLE_FILE"
git commit -m "Daily brew backup: $DATE" >> "$LOG_FILE" 2>&1
git push origin main >> "$LOG_FILE" 2>&1

# -------------------------
# Step 3: Ensure cron job exists
# -------------------------
CRON_JOB="30 6 * * * $REPO_DIR/setup_brew_backup.sh"
( crontab -l 2>/dev/null | grep -F "$REPO_DIR/setup_brew_backup.sh" ) >/dev/null

# shellcheck disable=SC2181
if [ $? -ne 0 ]; then
  (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
  echo "[$DATE] Cron job added." >> "$LOG_FILE"
else
  echo "[$DATE] Cron job already exists." >> "$LOG_FILE"
fi