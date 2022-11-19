{ pkgs, config, lib, nix2nvimrc, ... }:
let
  parsers = lib.mapAttrs'
    (n: v: lib.nameValuePair
      # remove prefix "tree-sitter-" from attribute names
      # https://github.com/NixOS/nixpkgs/pull/198606
      (lib.removePrefix "tree-sitter-" n)
      "${v}/parser")
    pkgs.tree-sitter.builtGrammars;
in
{
  configs = {
    treesitter = {
      treesitter.parsers = { inherit (parsers) nix; };
      plugins = [ pkgs.vimPlugins.nvim-treesitter ];
      setup.modulePath = "nvim-treesitter.configs";
      setup.args.highlight.enable = true;
    };
    telescope = {
      plugins = with pkgs.vimPlugins; [ telescope-nvim plenary-nvim popup-nvim ];
      setup.args = { };
      keymaps = map (nix2nvimrc.toKeymap { silent = true; }) [
        [ "n" "<space>ff" "<Cmd>Telescope find_files<CR>" { } ]
        [ "n" "<space>fg" (nix2nvimrc.luaExpr "require'telescope.builtin'.live_grep") { } ]
      ];
    };
    lsp = {
      after = [ "telescope" ];
      lspconfig.servers = lib.optionalAttrs
        (config.config ? "lang-nix")
        { rnix.pkg = pkgs.rnix-lsp; };
      vim = [ ./test/init.vim ];
    };
  };
}
