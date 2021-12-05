{ pkgs, config, lib, nix2nvimrc, ... }:
{
  imports = [
    { configs.lang-nix.treesitter.languages = [ "nix" ]; }
  ];
  configs = {
    treesitter = {
      plugins = [ pkgs.vimPlugins.nvim-treesitter ];
      setup.modulePath = "nvim-treesitter.configs";
      setup.args.highlight.enable = true;
    };
    telescope = {
      plugins = with pkgs.vimPlugins; [ telescope-nvim plenary-nvim popup-nvim ];
      setup.args = { };
      keymaps = map (nix2nvimrc.toKeymap { noremap = true; silent = true; }) [
        [ "n" "<space>ff" "<Cmd>Telescope find_files<CR>" { } ]
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
