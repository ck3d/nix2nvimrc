Nix2NVimRc is a set of
[Nix](https://nixos.org/manual/nix/stable/) functions and Nixpkgs module specification
to generate a [Neovim](https://neovim.io/) configuration (nvimrc)
from a given module configuration.

The module provides options to configure following items:

| Neovim configuration item | Nix2NVimRC module option |
|---|---|
| Neovim [option](https://neovim.io/doc/user/options.html) | `opts{}` |
| Neovim keymap (see also helper function `toKeymap`)| `keymaps[]` |
| Neovim global variable | `vars{}` |
| Neovim [treesitter](https://neovim.io/doc/user/treesitter.html) | `treesitter.languages[]` |
| Neovim [LSP](https://neovim.io/doc/user/lsp.html) via plugin [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | `lspconfig.` |
| Lua plugin setup | `setup.` |
| Vim expression or file | `vim[]` |
| Lua expression | `lua[]` |
| Vim plugin as Nix package | `plugins[]` |

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
2. Minimize dependency to `nixpkgs`, only following library functions are used:
   `optional`, `evalModules`, `types`, `mkOption`, and `toposort`
3. The Nix flake has no inputs and therefor no lock file.

## Alternative Projects

- [nix2vim](https://github.com/gytis-ivaskevicius/nix2vim)
