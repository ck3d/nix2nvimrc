{ pkgs, config, lib, ... }:
{
  configs = [
    {
      name = "lang-nix";
      treesitter.languages = [ "nix" ];
    }
    {
      name = "treesitter";
      plugins = [ pkgs.vimPlugins.nvim-treesitter ];
      modulePath = "nvim-treesitter.configs";
      setup.highlight.enable = true;
    }
    {
      name = "telescope";
      plugins = with pkgs.vimPlugins; [ telescope-nvim plenary-nvim popup-nvim ];
      setup = { };
      keymaps = map (lib.toKeymap { noremap = true; silent = true; }) [
        [ "n" "<space>ff" "<Cmd>Telescope find_files<CR>" { } ]
      ];
    }
    {
      name = "lsp";
      lspconfig.servers = lib.optionalAttrs
        (config.config ? "lang-nix")
        { rnix.pkg = pkgs.rnix-lsp; };
      vim = [ ./test/init.vim ];
    }
  ];
}
