{ pkgs, config, lib, ... }:
{
  imports = [
    { configs.lang-nix.treesitter.languages = [ "nix" ]; }
  ];
  configs = {
    treesitter = {
      plugins = [ pkgs.vimPlugins.nvim-treesitter ];
      modulePath = "nvim-treesitter.configs";
      setup.highlight.enable = true;
    };
    telescope = {
      plugins = with pkgs.vimPlugins; [ telescope-nvim plenary-nvim popup-nvim ];
      setup = { };
      keymaps = map (lib.toKeymap { noremap = true; silent = true; }) [
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
