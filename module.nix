{ config, lib, pkgs, ... }:

with lib;

let
  keymapType = types.submodule {
    options = {
      mode = mkOption { type = types.str; };
      lhs = mkOption { type = types.str; };
      rhs = mkOption { type = types.str; };
      opts = mkOption { type = types.attrs; };
    };
  };

  expressions = {
    lua = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Lua expressions to execute";
    };
    vim = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Vim expressions to execute";
    };
  };

  configType = types.submodule {
    options = ({
      name = mkOption { type = types.str; };
      setupFn = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Argument passed to setup";
      };
      setup = mkOption {
        type = types.anything;
        default = null;
        description = "Argument passed to setup";
      };
      plugins = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Vim plugin packages";
      };
      vars = mkOption {
        type = types.attrs;
        default = { };
        description = "Vim global variables";
      };
      opts = mkOption {
        type = types.attrs;
        default = { };
        description = "Vim options";
      };
      keymaps = mkOption {
        type = types.listOf keymapType;
        default = [ ];
      };
      treesitter.languages = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
      lspconfig = mkOption {
        type = types.nullOr lspconfigType;
        default = null;
      };
    }
    // expressions);
  };

  lspconfigType = types.submodule {
    options = {
      servers = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            pkg = mkOption {
              type = types.package;
            };
            config = mkOption {
              type = types.attrs;
              default = { };
            };
          };
        });
      };
      capabilities = mkOption {
        type = types.either types.attrs types.path;
        default = luaExpr "vim.lsp.protocol.make_client_capabilities()";
      };
      keymaps = mkOption {
        type = types.listOf keymapType;
        default = [ ];
      };
      opts = mkOption {
        type = types.attrs;
        default = { };
        description = "Vim options";
      };
      on_attach = mkOption {
        type = types.either types.attrs types.path;
        default = luaExpr "function() end";
      };
    };
  };
in
{
  options = {
    configs = mkOption {
      type = types.listOf configType;
      description = "NVim configurations";
    };
    treesitter.grammars = mkOption {
      type = types.attrsOf types.package;
      default = pkgs.tree-sitter.builtGrammars;
    };
    lspconfig = mkOption {
      type = types.package;
      default = pkgs.vimPlugins.nvim-lspconfig;
    };
    beforePlugins = expressions;

    out = mkOption {
      internal = true;
      type = types.str;
    };
    opt = mkOption {
      internal = true;
      type = types.attrsOf types.anything;
    };
    var = mkOption {
      internal = true;
      type = types.attrsOf types.anything;
    };
    setup = mkOption {
      internal = true;
      type = types.attrsOf types.anything;
    };
  };

  config = {
    out =
      let
        lspconfigWrapper = "lspconfigWrapper";

        lspUsed = any (c: c.lspconfig != null) config.configs;

        configToLua = c:
          [ "-- ${c.name} (${concatStringsSep " " (map (p: p.name) c.plugins)})" ]
          ++ (map (k: toLuaFn "vim.api.nvim_set_var" [ k c.vars.${k} ]) (attrNames c.vars))
          ++ (map (m: toLuaFn "vim.api.nvim_set_keymap" [ m.mode m.lhs m.rhs m.opts ]) c.keymaps)
          ++ (map (k: "vim.opt[${toLua k}] = ${toLua c.opts.${k}}") (attrNames c.opts))
          ++ c.lua
          ++ (map (v: toLuaFn "vim.cmd" [ v ]) c.vim)
          ++ (optional (c.setup != null)
            (toLuaFn (if c.setupFn != null then c.setupFn else "require'${c.name}'.setup") [ c.setup ]))
          ++ (map
            (l: toLuaFn "vim.treesitter.require_language" [ "${l}" "${config.treesitter.grammars."tree-sitter-${l}"}/parser" ])
            c.treesitter.languages)
          ++ (optional (c.lspconfig != null) (toLuaFn lspconfigWrapper [ c.lspconfig ]))
        ;

        init_lua =
          config.beforePlugins.lua
          ++ optional lspUsed "local ${lspconfigWrapper} = ${toLua ./nix-lspconfig.lua}"
          ++ (flatten (map configToLua config.configs))
        ;
      in
      pkgs.vimUtils.vimrcContent {
        customRC = "source ${pkgs.writeText "init.lua" (concatStringsSep "\n" init_lua)}";
        beforePlugins = concatStringsSep "\n" config.beforePlugins.vim;
        packages.nix-nvimconfig.start = foldl'
          (a: b: a ++ b.plugins)
          (optional lspUsed config.lspconfig)
          config.configs;
      };
    opt = foldl' (a: b: a // b.opts) { } config.configs;
    var = foldl' (a: b: a // b.vars) { } config.configs;
    setup = foldl' (a: b: a // { ${b.name} = b.setup; }) config.configs;
  };
}
