#!/bin/bash

echo "🧹 Flattening Stow-style dotfiles..."

# Loop through all directories in the current folder
for app_dir in */; do
    # Remove trailing slash
    app="${app_dir%/}"

    # Skip hidden directories like .git
    if [[ "$app" == .* ]]; then
        continue
    fi

    # Check if the deeply nested .config/app directory exists
    if [ -d "$app/.config/$app" ]; then
        echo "Flattening: $app"

        # shopt dotglob ensures we also move hidden files (like .env or .gitignore)
        shopt -s dotglob
        mv "$app"/.config/"$app"/* "$app"/ 2>/dev/null
        shopt -u dotglob

        # Clean up the empty folders
        rm -rf "$app/.config"
        echo "  ✅ Done"

    # Check if it just has a .config directory without the app name repeated
    elif [ -d "$app/.config" ]; then
        echo "Flattening: $app (from generic .config)"

        shopt -s dotglob
        mv "$app"/.config/* "$app"/ 2>/dev/null
        shopt -u dotglob

        rm -rf "$app/.config"
        echo "  ✅ Done"

    else
        echo "⏭️  Skipped: $app (already flat or no .config folder)"
    fi
done

echo "🎉 Repository is flat! You are ready to run the new install.sh."
