local script = debug.getinfo(1, "S").source:sub(2)
local root = script:match("^(.*)/tests/") or script:match("^(.*)tests/")
if not root or root == "" then root = "." end
if root:sub(1, 1) ~= "/" then root = assert(os.getenv("PWD")) .. "/" .. root end
local function quote(value) return string.format("%q", value) end
local function put(path, value)
  local file = assert(io.open(path, "w")); assert(file:write(value)); assert(file:close())
end
local function get(path)
  local file = assert(io.open(path)); local value = file:read("*a"); file:close(); return value
end
local temp = envy.run("mktemp -d /tmp/binstall-tools-test.XXXXXX", { capture = true }).stdout:gsub("%s+$", "")
local ok, failure = pcall(function()
  local cargo = temp .. "/cargo root"
  envy.run("mkdir -p " .. quote(temp .. "/.local/bin") .. " " .. quote(temp .. "/bin") .. " " ..
    quote(temp .. "/state") .. " " .. quote(cargo .. "/bin"))
  put(temp .. "/bin/uname", [[#!/bin/sh
case "$1" in -s) printf 'Linux\n';; -m) printf '%s\n' "$TEST_ARCH";; esac
]])
  -- Model binstall's installed-version skip and origin records, not command spelling.
  put(temp .. "/.local/bin/cargo-binstall", [=[#!/usr/bin/env bash
set -euo pipefail
root= version= target= url= crate= strategies=
force=false
list=false
while (( $# )); do
    case "$1" in
        --root) root=$2; shift 2 ;;
        --version) version=${2#=}; shift 2 ;;
        --targets) target=$2; shift 2 ;;
        --pkg-url) url=$2; shift 2 ;;
        --strategies) strategies=$2; shift 2 ;;
        --pkg-fmt|--bin-dir) shift 2 ;;
        --force) force=true; shift ;;
        --list) list=true; shift ;;
        --no-confirm|--disable-telemetry) shift ;;
        *) crate=$1; shift ;;
    esac
done
if [[ -f "$HOME/list-fails" ]]; then exit 31; fi
if [[ $list == true ]]; then
    printf 'Package              Cargo Ver    Binstall Ver   Method\n'
    for record in "$HOME"/state/*; do
        [[ -f $record ]] || continue
        read -r current method < "$record"
        name=${record##*/}
        if [[ -f "$HOME/narrow" ]]; then
            printf '%s v%s [%s]\n' "$name" "$current" "$method"
        else
            printf '%-20s %-12s %-14s %s\n' "$name" "$current" '-' "$method"
        fi
    done
    exit 0
fi
current=
if [[ -f "$HOME/state/$crate" ]]; then read -r current method < "$HOME/state/$crate"; fi
version=${version:-2.0.0}
if [[ $version == "$current" && $force == false ]]; then exit 0; fi
if [[ -f "$HOME/unavailable-$crate" ]]; then
    # The real installer must fail here, never compile or use QuickInstall.
    [[ $strategies == crate-meta-data ]] || touch "$HOME/forbidden-fallback"
    exit 42
fi
arch=$TEST_ARCH
[[ $arch != arm64 ]] || arch=aarch64
expected="$arch-unknown-linux-gnu"
[[ $crate != typos-cli ]] || expected="$arch-unknown-linux-musl"
[[ $target == "$expected" ]] || exit 43
if [[ $crate == gping ]]; then
    asset_arch=$arch
    [[ $arch != aarch64 ]] || asset_arch=arm64
    [[ $url == *"gping-Linux-gnu-$asset_arch.tar.gz" ]] || exit 44
fi
binary=$crate
case "$crate" in git-delta) binary=delta;; typos-cli) binary=typos;; esac
printf '%s cargo binstall\n' "$version" > "$HOME/state/$crate"
printf '#!/bin/sh\nexit 0\n' > "$root/bin/$binary"
chmod +x "$root/bin/$binary"
printf '%s\n' "$crate" >> "$HOME/installed"
]=])
  envy.run("chmod +x " .. quote(temp .. "/bin/uname") .. " " .. quote(temp .. "/.local/bin/cargo-binstall"))
  local function run(mode, arch)
    return envy.run("env -i HOME=" .. quote(temp) .. " CARGO_HOME=" .. quote(cargo) ..
      " TEST_ARCH=" .. quote(arch or "x86_64") .. " PATH=" .. quote(temp .. "/bin:/usr/bin:/bin") ..
      " bash " .. quote(root .. "/scripts/rust-tools") .. " " .. mode,
      { capture = true, check = false })
  end
  local crates = { "diskus", "eza", "git-delta", "gping", "hexyl", "typos-cli" }
  for _, crate in ipairs(crates) do put(temp .. "/state/" .. crate, "1.0.0 cargo install\n") end
  assert(run("check").exit_code ~= 0, "source-installed tools must request migration")
  assert(run("install").exit_code == 0, "same-version migration must reinstall prebuilt binaries")
  for _, crate in ipairs(crates) do
    assert(get(temp .. "/state/" .. crate) == "1.0.0 cargo binstall\n", "setup must preserve installed versions")
  end
  assert(run("check").exit_code == 0)
  local installed = get(temp .. "/installed")
  assert(run("install").exit_code == 0)
  assert(get(temp .. "/installed") == installed, "converged setup must not reinstall")
  put(temp .. "/unavailable-diskus", "")
  local result = run("update")
  assert(result.exit_code ~= 0, "unavailable prebuilt must fail aggregate update")
  assert(get(temp .. "/state/diskus") == "1.0.0 cargo binstall\n", "failure must preserve old binary")
  assert(get(temp .. "/state/typos-cli") == "2.0.0 cargo binstall\n", "later crates must still update")
  assert(not io.open(temp .. "/forbidden-fallback"), "missing prebuilt must not invoke fallback strategies")
  os.remove(temp .. "/unavailable-diskus")
  put(temp .. "/narrow", "")
  put(temp .. "/state/eza", "2.0.0 drifted (1.0.0->2.0.0)\n")
  os.remove(cargo .. "/bin/hexyl")
  assert(run("check").exit_code ~= 0, "drifted or missing binaries must request repair")
  assert(run("install", "arm64").exit_code == 0)
  assert(run("check", "aarch64").exit_code == 0, "narrow output must converge")
  -- Force all crates through the ARM mapping, including gping and typos.
  for _, crate in ipairs(crates) do put(temp .. "/state/" .. crate, "2.0.0 cargo install\n") end
  assert(run("install", "aarch64").exit_code == 0)
  installed = get(temp .. "/installed")
  put(temp .. "/list-fails", "")
  assert(run("install").exit_code ~= 0, "failed inventory must not be treated as empty")
  assert(get(temp .. "/installed") == installed, "failed inventory must not modify tools")
end)
envy.run("rm -rf " .. quote(temp))
if not ok then error(failure) end
print("binstall tool migration checks passed")
