#!/bin/bash

FORMULA_FILE="macbook_brew_packages.txt"
CASK_FILE="macbook_brew_casks.txt"
TAPS_FILE="macbook_brew_taps.txt"

# Arrays to store failed installations
failed_taps=()
failed_formulas=()
failed_casks=()

# Function to handle retries for failed taps
retry_tap() {
  local tap=$1
  echo "Retrying tap $tap..."
  if ! brew tap "$tap"; then
    echo "Retry failed for tap $tap. Marking as failed."
    failed_taps+=("$tap")
  fi
}

# Function to handle retries for failed formula installations
retry_formula() {
  local formula=$1
  echo "Retrying formula $formula..."
  if ! brew install "$formula"; then
    echo "Retry failed for formula $formula. Marking as failed."
    failed_formulas+=("$formula")
  fi
}

# Function to handle retries for failed cask installations
retry_cask() {
  local cask=$1
  echo "Retrying cask $cask..."
  if ! brew install --cask "$cask"; then
    echo "Retry failed for cask $cask. Marking as failed."
    failed_casks+=("$cask")
  fi
}

# Install Homebrew taps from taps file
if [[ -f "$TAPS_FILE" ]]; then
  echo "Tapping repositories from $TAPS_FILE..."
  while IFS= read -r tap; do
    if ! brew tap | grep -q "$tap"; then
      echo "Tapping $tap..."
      if ! brew tap "$tap"; then
        echo "Failed to tap $tap. Marking for retry."
        retry_tap "$tap"
      fi
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
      retry_formula "$package_name"
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
      retry_cask "$cask"
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

# Report failed installations
if [[ ${#failed_taps[@]} -ne 0 ]]; then
  echo "The following taps failed to install:"
  for tap in "${failed_taps[@]}"; do
    echo "$tap"
  done
else
  echo "All taps installed successfully."
fi

if [[ ${#failed_formulas[@]} -ne 0 ]]; then
  echo "The following formulas failed to install:"
  for formula in "${failed_formulas[@]}"; do
    echo "$formula"
  done
else
  echo "All formulas installed successfully."
fi

if [[ ${#failed_casks[@]} -ne 0 ]]; then
  echo "The following casks failed to install:"
  for cask in "${failed_casks[@]}"; do
    echo "$cask"
  done
else
  echo "All casks installed successfully."
fi