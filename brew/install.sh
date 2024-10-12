#!/bin/bash

FORMULA_FILE="macbook_brew_packages.txt"
CASK_FILE="macbook_brew_casks.txt"
TAPS_FILE="macbook_brew_taps.txt"

# Function to handle retries for failed installations
retry_install() {
  local package_name=$1
  echo "Retrying installation of $package_name..."
  brew install "$package_name"
}

# Install Homebrew taps from taps file
if [[ -f "$TAPS_FILE" ]]; then
  echo "Tapping repositories from $TAPS_FILE..."
  while IFS= read -r tap; do
    if ! brew tap | grep -q "$tap"; then
      echo "Tapping $tap..."
      brew tap "$tap"
    else
      echo "$tap already tapped."
    fi
  done < "$TAPS_FILE"
else
  echo "No taps file found."
fi

# Install formulas from formula file
if [[ -f "$FORMULA_FILE" ]]; then
  echo "Installing formulas from $FORMULA_FILE..."
  while IFS= read -r line; do
    package_name=$(echo "$line" | awk '{print $1}')
    version=$(echo "$line" | awk '{print $2}')

    echo "Installing $package_name (ignoring version $version)..."
    if ! brew install "$package_name"; then
      echo "Failed to install $package_name. Marking for retry."
      retry_install "$package_name"
    fi
  done < "$FORMULA_FILE"
else
  echo "No formula file found."
fi

# Install casks from cask file
if [[ -f "$CASK_FILE" ]]; then
  echo "Installing casks from $CASK_FILE..."
  while IFS= read -r cask; do
    echo "Installing cask $cask..."
    if ! brew install --cask "$cask"; then
      echo "Failed to install cask $cask. Marking for retry."
      retry_install "$cask"
    fi
  done < "$CASK_FILE"
else
  echo "No cask file found."
fi

# Update Homebrew
echo "Updating Homebrew..."
brew update

# Clean up
echo "Cleaning up Homebrew..."
brew cleanup

echo "All installations complete."
