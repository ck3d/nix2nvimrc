Nix2NVimRc is a set of
[Nix](https://nixos.org/manual/nix/stable/) functions and Nixpkgs module specification
to generate a [Neovim](https://neovim.io/) configuration (nvimrc)
from a given module configuration.

The module provides options to configure following items:

| Neovim configuration item | Nix2NVimRC module option | used Neovim Lua API |
|---|---|---|
| Neovim [option](https://neovim.io/doc/user/options.html) | `opts.<name> = <value>` | `vim.opt['<name>'] = <value>`|
| Neovim keymap (see also helper function `toKeymap`)| `keymaps[]` | [`vim.keymap.set()`](https://neovim.io/doc/user/lua.html#vim.keymap.set()) |
| Neovim global variable | `vars.<name> = <value>` | `vim.api.nvim_set_var(<name>, <value>)` |
| Neovim [treesitter](https://neovim.io/doc/user/treesitter.html) | `treesitter.parsers.<name> = <path>` | `vim.treesitter.language.require_language(<name>, <path>)` |
| Neovim [LSP](https://neovim.io/doc/user/lsp.html) via plugin [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | `lspconfig.` | passed to [nix-lspconfig.lua](./nix-lspconfig.lua) |
| Lua plugin setup | `setup.` |`require('...').setup()`|
| Vim expression or file | `vim[]` | `vim.cmd()` |
| Lua expression or file | `lua[]` | inlined |
| Vim plugin as Nix package | `plugins[]` | handled by `nixpkgs.vimUtils.packDir` |

## Example

The file `./example-config.nix` contains a minimalistic example configuration.
To generate and use this configuration, execute following steps:

```sh
nix-build -E 'with import <nixpkgs> { }; writeText "init.lua" ((import ./lib.nix).toRc pkgs ./example-config.nix)'
nvim -u NORC --cmd "luafile ./result"
```

To see a more sophisticated example, go to repository [ck3d-nvim-configs](https://github.com/ck3d/ck3d-nvim-configs).

## Design Goals

1. Output only Lua code for NVim
2. Keep dependency to `nixpkgs` as small as possible:
   - `lib.`: `optional`, `optionals`, `evalModules`, `types`, `mkOption`, and `toposort`
   - `pkgs.`: `vimUtils.packDir`
3. No dependency in the Nix Flake to avoid a lock file

## Alternative Projects

- [nix2vim](https://github.com/gytis-ivaskevicius/nix2vim)
