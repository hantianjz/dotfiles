# Octo.nvim Usage Guide

## Localleader Key
- **Localleader**: `/` (forward slash)
- Note: Default keybindings are disabled in this config

## Common Commands

### Issues
```vim
:Octo issue list [repo]          " List issues
:Octo issue create               " Create new issue
:Octo issue edit <number>        " Edit issue
:Octo issue close <number>       " Close issue
```

### Pull Requests
```vim
:Octo pr list [repo]             " List PRs
:Octo pr create                  " Create new PR
:Octo pr edit <number>           " Edit PR
:Octo pr checkout <number>       " Checkout PR locally
:Octo pr merge <number> [method] " Merge PR (merge/squash/rebase)
:Octo pr diff [number]           " Show PR diff
```

### Reviews
```vim
:Octo review start               " Start code review
:Octo review resume              " Resume pending review
:Octo review submit              " Submit review
:Octo review comments            " View review comments
:Octo review close               " Close review tab
:Octo review discard             " Discard pending review
```

### Utility
```vim
:Octo actions                    " Open command picker
:Octo repo view                  " View repo info
:Octo repo browser               " Open in browser
```

## PR Review Mode Actions

When in PR review mode (after running `:Octo review start`), you have access to these actions:

### Review Session Management (Default Keybindings - Currently Disabled)
- `/vs` - Start a review for the current PR
- `/vr` - Resume a pending review for the current PR

### Review Submission (In Submit Window)
- `<C-a>` - Approve review
- `<C-m>` - Comment review (no approval/rejection)
- `<C-r>` - Request changes
- `<C-c>` - Close review tab

### Adding Comments & Suggestions
- `/ca` - Add review comment (works in normal/visual mode)
- `/sa` - Add review suggestion (works in normal/visual mode)
- `/cd` - Delete comment

### Thread Navigation
- `]c` / `[c` - Next/previous comment
- `]t` / `[t` - Next/previous thread
- `/rt` - Resolve PR thread
- `/rT` - Unresolve PR thread

### File Navigation
- `]q` / `[q` - Next/previous changed file
- `]Q` / `[Q` - Jump to first/last changed file
- `]u` / `[u` - Next/previous unviewed file

### Panel Management
- `/e` - Shift focus to changed file panel
- `/b` - Toggle file panel visibility
- `/<space>` - Toggle viewed state indicator

### Workflow
1. Run `:Octo review start` to enter review mode
2. Navigate changed files with `]q` / `[q`
3. Add comments with `/ca` or suggestions with `/sa` (on single or multiple visual-selected lines)
4. Submit review with `<C-a>` (approve), `<C-m>` (comment), or `<C-r>` (request changes)

**Note**: All keybindings listed above are currently disabled. Use commands via `:Octo` or enable keybindings by setting `mappings_disable_default = false`.

## Telescope Integration
Use `<leader>o` (currently `;o`) to search for Octo commands in Telescope.

## Buffer Actions
When editing issues/PRs in Octo buffers:
- `:w` or `:write` - Save changes to GitHub
- `:e!` - Reload from GitHub
- `<C-x><C-o>` - Autocomplete @mentions and #issues

## Default Keybindings (Reference Only - Currently Disabled)

### Issue/PR Buffer Actions (using `/` localleader)
- `/ic` - Close issue
- `/ir` - Reopen issue
- `/aa` - Add assignee
- `/ar` - Remove assignee
- `/la` - Add label
- `/lr` - Remove label
- `/ca` - Create comment
- `/cd` - Delete comment

### PR-Specific Actions
- `/pm` - Merge PR
- `/pp` - Squash and merge
- `/pb` - Rebase and merge
- `/pd` - Show PR diff
- `/pc` - List commits
- `/pf` - List changed files
- `/pr` - Mark ready for review

### Review Diff Buffer
- `/ca` - Add comment
- `/sa` - Add suggestion
- `/vs` - Submit review
- `]q` / `[q` - Next/previous changed file
- `]u` / `[u` - Next/previous unviewed file

### Telescope Picker Actions
- `<C-b>` - Open in browser
- `<C-y>` - Copy URL
- `<C-e>` - Copy commit SHA
- `<C-o>` - Checkout PR

**Note**: To enable these keybindings, set `mappings_disable_default = false` in the plugin configuration.

## Prerequisites

Before using octo.nvim, authenticate with GitHub CLI:

```bash
# Basic authentication
gh auth login

# For GitHub Projects v2 support (optional)
gh auth refresh -s read:project
```

## Verification Steps

1. Restart Neovim or run `:Lazy sync`
2. Run `:Octo actions` to load the plugin
3. Test with `:Octo issue list` or `:Octo pr list`
