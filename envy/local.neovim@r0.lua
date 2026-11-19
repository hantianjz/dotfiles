-- @envy schema "1"
IDENTITY = "local.neovim@r0"
USER_MANAGED = true
PLATFORMS = { "linux-x86_64", "linux-arm64" }

DEPENDENCIES = {
  { spec = "local.system_packages@r0", setup = { "packages" }, needed_by = "check" },
}

local function release_script()
  assert(envy.PLATFORM == "linux", "Neovim release requires Linux")
  assert(envy.ARCH == "x86_64" or envy.ARCH == "arm64", "unsupported Neovim release architecture")
  return "set -euo pipefail\narch=" .. string.format("%q", envy.ARCH) .. "\n" .. [=[
name="nvim-linux-$arch"
root="$HOME/.local/share/neovim"
destination="$HOME/.local/bin/nvim"
metadata=$(curl --proto '=https' --tlsv1.2 -fsSL --connect-timeout 10 --max-time 120 \
  https://api.github.com/repos/neovim/neovim/releases/latest)
release=$(printf '%s' "$metadata" | jq -er --arg name "$name.tar.gz" '
  select(.draft == false and .prerelease == false)
  | .tag_name as $tag
  | select($tag | test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))
  | [.assets[] | select(.name == $name and .state == "uploaded")]
  | select(length == 1) | .[0]
  | select(.digest | strings | test("^sha256:[0-9a-f]{64}$"))
  | [$tag, (.digest | ltrimstr("sha256:"))] | @tsv')
IFS=$'\t' read -r version checksum <<< "$release"
managed() {
  target=$(readlink "$destination") || return 1
  case "$target" in
    "$root"/v*-"$arch".*/"$name"/bin/nvim) ;;
    *) return 1 ;;
  esac
  bundle="${target%/bin/nvim}"
  test -f "$bundle/.envy-neovim"
}
]=]
end

SETUP = { editor = {
  CHECK = function()
    return envy.run(release_script() .. [=[
test -L "$destination" && managed &&
test "$(cat "$bundle/.envy-neovim")" = "$version $checksum" &&
test -f "$bundle/share/nvim/runtime/doc/help.txt" &&
installed=$("$destination" --version) &&
test "${installed%%$'\n'*}" = "NVIM $version"
]=], { capture = true, quiet = true, check = false }).exit_code == 0
  end,
  INSTALL = function()
    return release_script() .. [=[
if test -e "$destination" || test -L "$destination"; then
  if ! managed; then
    printf 'Refusing to replace unrelated Neovim installation: %s\n' "$destination" >&2
    exit 1
  fi
fi
mkdir -p "$root" "$HOME/.local/bin"
work=$(mktemp -d "$root/$version-$arch.XXXXXX")
trap 'if test -n "$work"; then rm -rf "$work"; fi' EXIT
curl --proto '=https' --tlsv1.2 -fsSL --connect-timeout 10 --max-time 300 \
  "https://github.com/neovim/neovim/releases/download/$version/$name.tar.gz" -o "$work/archive.tar.gz"
# GitHub publishes the official archive SHA-256 in the release asset metadata.
(cd "$work"; printf '%s  archive.tar.gz\n' "$checksum" | sha256sum --check --status)
tar -xzf "$work/archive.tar.gz" -C "$work"
test -f "$work/$name/share/nvim/runtime/doc/help.txt"
installed=$("$work/$name/bin/nvim" --version)
test "${installed%%$'\n'*}" = "NVIM $version"
printf '%s %s\n' "$version" "$checksum" > "$work/$name/.envy-neovim"
rm "$work/archive.tar.gz"
ln -s "$work/$name/bin/nvim" "$work/nvim"
# Switch only after verification; retain older trees for running editors and rollback.
mv -Tf "$work/nvim" "$destination"
work=""
]=]
  end,
} }
