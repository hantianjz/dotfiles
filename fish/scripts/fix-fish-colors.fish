#!/usr/bin/env fish
# Fix corrupted fish colors after upgrade
# Clears bad color variables and reapplies Catppuccin Mocha theme

set -e fish_color_command
set -e fish_color_error
set -e fish_color_valid_path

fish_config theme choose "Catppuccin Mocha"
yes | fish_config theme save "Catppuccin Mocha"

echo "Fish colors fixed and saved."
