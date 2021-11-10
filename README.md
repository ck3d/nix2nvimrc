Nix2NVimRc is a set of
[Nix](https://nixos.org/manual/nix/stable/) functions and Nixpkgs module specification
to generate a [Neovim](https://neovim.io/) configuration (nvimrc)
from a given module configuration.

The module provides options to configure:

- [options](https://neovim.io/doc/user/options.html)
- keymaps
- variables
- [treesitter](https://neovim.io/doc/user/treesitter.html)
- [LSP](https://neovim.io/doc/lsp/LSP) via [nvim-lspconfig plugin](https://github.com/neovim/nvim-lspconfig)
- LUA plugins via `setup`

It is also possible to specify arbitrary VIM and LUA expressions.

# Example

```sh
nix-build -E 'with import <nixpkgs> { }; writeText "nvimrc" ((import ./lib.nix).toRc pkgs ./example-config.nix)'
nvim -u ./result
```
