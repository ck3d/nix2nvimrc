{ config, lib, pkgs, nix2nvimrc, ... }:
let
  inherit (lib) types mkOption;

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
      type = types.listOf (types.either types.str types.path);
      default = [ ];
      description = "Vim expressions or files to execute";
    };
  };

  luaFunctionCallType = name: types.submodule {
    options = {
      modulePath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Module path used to function";
      };
      function = mkOption {
        type = types.str;
        default = name;
      };
      args = mkOption {
        type = types.anything;
        default = { };
        description = "Argument passed to function";
      };
    };
  };

  configType = types.submodule {
    options = {
      after = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "This configuration has to be executed after given configurations.";
      };
      setup = mkOption {
        type = types.nullOr (luaFunctionCallType "setup");
        default = null;
        description = "Lua plugin setup";
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
    // expressions;
  };

  lspconfigType = types.submodule {
    options = {
      servers = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            pkg = mkOption {
              type = types.nullOr types.package;
              description = ''
                Package to use to patch lspconfig cmd.
                Set to null if server has no cmd (e.g. for plugin null-ls).
              '';
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
        default = nix2nvimrc.luaExpr "vim.lsp.protocol.make_client_capabilities()";
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
        default = nix2nvimrc.luaExpr "function(client, bufnr) end";
      };
    };
  };
in
{
  options = {
    configs = mkOption {
      type = types.attrsOf configType;
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
    config = mkOption {
      internal = true;
      type = types.attrsOf types.anything;
    };
  };

  config =
    let
      inherit (lib) optional toposort;
      inherit (nix2nvimrc) toLuaFn toLua;

      configs =
        let
          res = toposort
            (a: b: builtins.elem a.name b.after)
            (map
              (name: config.configs.${name} // { inherit name; })
              (builtins.attrNames config.configs));
        in
          res.result or (throw "Config has a cyclic dependency");
    in
    {
      out =
        let
          vim2str = vim: if builtins.isPath vim then "source ${vim}" else vim;
          lspconfigWrapper = "lspconfigWrapper";

          lspUsed = builtins.any (c: c.lspconfig != null) configs;

          configToLua = c:
            [ "-- ${c.name} (${builtins.concatStringsSep " " (map (p: p.name) c.plugins)})" ]
            ++ (map (k: toLuaFn "vim.api.nvim_set_var" [ k c.vars.${k} ]) (builtins.attrNames c.vars))
            ++ (map (m: toLuaFn "vim.api.nvim_set_keymap" [ m.mode m.lhs m.rhs m.opts ]) c.keymaps)
            ++ (map (k: "vim.opt[${toLua k}] = ${toLua c.opts.${k}}") (builtins.attrNames c.opts))
            ++ (optional (c.setup != null)
              (toLuaFn "require'${if c.setup.modulePath != null then c.setup.modulePath else c.name}'.${c.setup.function}" [ c.setup.args ]))
            ++ c.lua
            ++ (map (v: toLuaFn "vim.cmd" [ v ]) (map vim2str c.vim))
            ++ (map
              (l: toLuaFn "vim.treesitter.require_language" [ "${l}" "${config.treesitter.grammars."tree-sitter-${l}"}/parser" ])
              c.treesitter.languages)
            ++ (optional (c.lspconfig != null) (toLuaFn lspconfigWrapper [ c.lspconfig ]))
          ;

          init_lua =
            config.beforePlugins.lua
            ++ optional lspUsed "local ${lspconfigWrapper} = ${toLua ./nix-lspconfig.lua}"
            ++ builtins.concatMap configToLua configs
          ;
        in
        pkgs.vimUtils.vimrcContent {
          customRC = "source ${pkgs.writeText "init.lua" (builtins.concatStringsSep "\n" init_lua)}";
          beforePlugins = builtins.concatStringsSep "\n" (map vim2str config.beforePlugins.vim);
          packages.nix-nvimconfig.start = builtins.foldl'
            (a: b: a ++ b.plugins)
            (optional lspUsed config.lspconfig)
            configs;
        };
      opt = builtins.foldl' (a: b: a // b.opts) { } configs;
      var = builtins.foldl' (a: b: a // b.vars) { } configs;
      config = config.configs;
    };
}
