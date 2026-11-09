BUNDLES = {
  ["first-party"] = {
    identity = "envy.package-specs@r11",
    source = "https://github.com/envy-package-manager/package-specs.git",
    ref = "25274d663b916b8cb71771b1edbdfb30fd598420",
  },
}

local github = envy.loadenv_bundle("first-party", "lib.github")
local function plugin(name, repo, ref)
  return github.repo(name, repo, ref, { vendor = ".envy/tmux/" .. name })
end

PACKAGES = {
  plugin("tpm", "tmux-plugins/tpm", "e261deb1b47614eed3400089ce7197dc68acc4eb"),
  plugin("tmux", "catppuccin/tmux", "32d0a8d95d562dd064a62a09d41af136561ae659"), -- v2.3.2
  plugin("tmux-continuum", "hantianjz/tmux-continuum", "cf7c0c5d882543db65f404d78c3c9a5820c2252c"),
  plugin("tmux-sensible", "tmux-plugins/tmux-sensible", "25cb91f42d020f675bb0a2ce3fbd3a5d96119efa"),
  plugin("tmux-yank", "tmux-plugins/tmux-yank", "acfd36e4fcba99f8310a7dfb432111c242fe7392"),
  plugin("tmux-resurrect", "tmux-plugins/tmux-resurrect", "cff343cf9e81983d3da0c8562b01616f12e8d548"),
  plugin("tmux-open-nvim", "trevarj/tmux-open-nvim", "d140ac66e24f1cd26b68638da01a82717a1921bd"),
  plugin("tmux-cpu", "tmux-plugins/tmux-cpu", "bcb110d754ab2417de824c464730c412a3eb2769"),
}
