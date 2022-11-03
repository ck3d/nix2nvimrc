Nix2NVimRc is a set of
[Nix](https://nixos.org/manual/nix/stable/) functions and Nixpkgs module specification
to generate a [Neovim](https://neovim.io/) configuration (nvimrc)
from a given module configuration.

The module provides options to configure following items:

| Neovim configuration item | Nix2NVimRC module option | used Neovim Lua API |
|---|---|---|
| Neovim [option](https://neovim.io/doc/user/options.html) | `opts.<name> = <value>` | `vim.opt['<name>'] = <value>`|
| Neovim keymap (see also helper function `toKeymap`)| `keymaps[]` | `vim.api.nvim_set_keymap()`|
| Neovim global variable | `vars.<name> = <value>` | `vim.api.nvim_set_var(<name>, <value>)` |
| Neovim [treesitter](https://neovim.io/doc/user/treesitter.html) | `treesitter.parsers.<name> = <path>` | `vim.treesitter.require_language(<name>, <path>)` |
| Neovim [LSP](https://neovim.io/doc/user/lsp.html) via plugin [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | `lspconfig.` | passed to [nix-lspconfig.lua](./nix-lspconfig.lua) |
| Lua plugin setup | `setup.` |`require('...').setup()`|
| Vim expression or file | `vim[]` | `vim.cmd()` |
| Lua expression or file | `lua[]` | inlined |
| Vim plugin as Nix package | `plugins[]` | handled by `nixpkgs.vimUtils.packDir` |

## Example

The file `./example-config.nix` contains a minimalistic example configuration.
To generate and use this configuration, execute following steps:

```sh
nix-build -E 'with import <nixpkgs> { }; writeText "nvimrc" ((import ./lib.nix).toRc pkgs ./example-config.nix)'
nvim -u ./result
```

To see a more sophisticated example, go to repository [ck3d-nvim-configs](https://github.com/ck3d/ck3d-nvim-configs).

## Design Goals

1. Do not wrap Neovim, just generate a configuration file for it.
2. Minimize dependency to `nixpkgs`, following functions are used:
   - `lib.`: `optional`, `evalModules`, `types`, `mkOption`, and `toposort`
   - `pkgs.`: `vimUtils.packDir`, `writeText`
3. The Nix flake has no inputs and therefor no lock file.

## Alternative Projects

- [nix2vim](https://github.com/gytis-ivaskevicius/nix2vim)
