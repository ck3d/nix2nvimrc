{ pkgs, lib, ... }:
{
  configs = [
    {
      name = "nix";
      treesitter.languages = [ "nix" ];
      lspconfig.servers.rnix.pkg = pkgs.rnix-lsp;
    }
    {
      name = "telescope";
      plugins = with pkgs.vimPlugins; [ telescope-nvim plenary-nvim popup-nvim ];
      setup = { };
      keymaps = map (lib.toKeymap { noremap = true; silent = true; }) [
        [ "n" "<space>ff" "<Cmd>Telescope find_files<CR>" { } ]
      ];
    }
  ];
}
