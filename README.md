# fugitive-difftool.nvim

[![CI][status-png]][status]

`fugitive-difftool.nvim` is a `neovim` plugin that complete `fugitive` 
`difftool` integration. It allows you to compare two revisions of a repository 
using the quickfix list. This is useful for code reviews.

![demo](./demo.gif)

## Installation

Install the plugin with your favorite plugin manager. For nixos users, [the 
flake file](flake.nix) contains an overlay that will add 
`fugitive-difftool-nvim` to the `vimPlugins` attribute set.

## Usage

The plugin exposes lua functions that you can use to browse the quickfix list 
filled up by `fugitive` `difftool`. 

For example, one can create user commands to call them:

```lua
-- Jump to the first quickfix entry
vim.api.nvim_create_user_command('Gcfir', require('fugitive-difftool').git_cfir, {})
-- To the last
vim.api.nvim_create_user_command('Gcla', require('fugitive-difftool').git_cla, {})
-- To the next
vim.api.nvim_create_user_command('Gcn', require('fugitive-difftool').git_cn, {})
-- To the previous
vim.api.nvim_create_user_command('Gcp', require('fugitive-difftool').git_cp, {})
-- To the currently selected
vim.api.nvim_create_user_command('Gcc', require('fugitive-difftool').git_cc, {})
```

Then if you work on a feature in a branch with many commits and you want to see 
all the changes from `master`. One can do:

```
:Git! difftool --name-status master...my-feature
```

Notes about this command:
- `!` will not jump on the first entry in the quickfix list. We want to jump 
  after loading the changes with `:Gcfir`
- by default `difftool` outputs one entry per hunk, `--name-status` will output 
  only one entry per file which is better in this use case

Once the call to `difftool` is done, the quickfix list contains all the 
changes. One can navigate through it with the created user commands.

## Notes

This worked is heavily based on code and comments found in [this issue][issue].

[issue]: https://github.com/tpope/vim-fugitive/issues/132
[status-png]: https://github.com/jecaro/fugitive-difftool.nvim/workflows/CI/badge.svg
[status]: https://github.com/jecaro/fugitive-difftool.nvim/actions

