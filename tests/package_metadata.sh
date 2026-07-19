#!/usr/bin/env bash
set -euo pipefail

profile=${1:?usage: package_metadata.sh macos|ubuntu|arch}
export TEST_PROFILE=$profile

while read -r kind name; do
  case "$profile:$kind" in
    macos:package) brew info --formula "$name" >/dev/null ;;
    macos:cask) brew info --cask "$name" >/dev/null ;;
    macos:tap) brew tap-info "$name" >/dev/null ;;
    ubuntu:package) apt-cache show "$name" >/dev/null ;;
    arch:package) pacman -Si "$name" >/dev/null ;;
  esac
done < <(./bin/envy lua tests/package_list.lua)
