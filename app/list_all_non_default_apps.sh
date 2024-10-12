#!/bin/bash

# List all apps in /Applications and ~/Applications
echo "Listing non-standard applications in /Applications and ~/Applications:"

# Find all .app bundles in common directories
find /Applications ~/Applications -iname "*.app" | while read app; do
  # Get app information
  app_name=$(basename "$app")
  bundle_id=$(defaults read "$app/Contents/Info" CFBundleIdentifier 2>/dev/null)

  # Check if the app is from Apple, if not, print it
  if [[ "$bundle_id" != *apple* ]]; then
    echo "$app_name - $bundle_id"
  fi
done
