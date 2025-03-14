{
  config,
  lib,
  pkgs,
  nix2nvimrc,
  ...
}:
let
  inherit (lib) types mkOption;

  # copy from
  # https://github.com/NixOS/nixpkgs/blob/63aa55f6f54c1ebd9fdf5746bdbe39fe229c74ff/pkgs/applications/editors/vim/plugins/vim-utils.nix#L171
  vimFarm =
    prefix: name: drvs:
    let
      mkEntryFromDrv = drv: {
        name = "${prefix}/${lib.getName drv}";
        path = drv;
      };
    in
    pkgs.linkFarm name (map mkEntryFromDrv drvs);

  exprType = types.submodule {
    options = {
      type = mkOption { type = types.enum [ "lua" ]; };
      expression = mkOption { type = types.str; };
    };
  };

  keymapType = types.submodule {
    options = {
      mode = mkOption { type = types.either types.str (types.listOf types.str); };
      lhs = mkOption { type = types.str; };
      rhs = mkOption { type = types.either types.str exprType; };
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

  luaFunctionCallType =
    name:
    types.submodule {
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
      treesitter.parsers = mkOption {
        type = types.attrsOf types.path;
        default = { };
        description = "Attribute set where name is the language and the the value a path to the parser.";
      };
      lspconfig = mkOption {
        type = types.nullOr lspconfigType;
        default = null;
      };
    } // expressions;
  };

  lspconfigType = types.submodule {
    options = {
      servers = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              config = mkOption {
                type = types.attrs;
                default = { };
              };
            };
          }
        );
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

    enableFns = mkOption {
      type = types.listOf (types.functionTo types.bool);
      default = [ ];
      description = "Enable functions for a configuration module";
    };

    out = mkOption {
      internal = true;
      type = types.str;
    };
    packPath = mkOption {
      internal = true;
      type = types.path;
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
      inherit (lib) optional optionals toposort;
      inherit (nix2nvimrc) toLuaFn toLua;

      configs =
        let
          res = toposort (a: b: builtins.elem a.name b.after) (
            map (name: config.configs.${name} // { inherit name; }) (
              builtins.filter (
                name:
                builtins.foldl' (last: enableFn: last && (enableFn config.configs.${name})) true config.enableFns
              ) (builtins.attrNames config.configs)
            )
          );
        in
        res.result or (throw "Config has a cyclic dependency");

      packages = builtins.foldl' (a: b: a ++ b.plugins) [ ] configs;

      packdirFolder = "pack/nix-nvimconfig/start";
    in
    {
      packPath = vimFarm packdirFolder "packdir-start" packages;

      out =
        let
          vim2str = vim: if builtins.isPath vim then "source ${vim}" else vim;
          lspconfigWrapper = "lspconfigWrapper";

          lspUsed = builtins.any (c: c.lspconfig != null) configs;

          configToLua =
            c:
            [ "-- ${c.name} (${builtins.concatStringsSep " " (map (p: p.name) c.plugins)})" ]
            ++ (map (
              k:
              toLuaFn "vim.api.nvim_set_var" [
                k
                c.vars.${k}
              ]
            ) (builtins.attrNames c.vars))
            ++ (map (
              m:
              toLuaFn "vim.keymap.set" [
                m.mode
                m.lhs
                m.rhs
                m.opts
              ]
            ) c.keymaps)
            ++ (map (k: "vim.opt[${toLua k}] = ${toLua c.opts.${k}}") (builtins.attrNames c.opts))
            ++ (optional (c.setup != null) (
              toLuaFn "require'${
                if c.setup.modulePath != null then c.setup.modulePath else c.name
              }'.${c.setup.function}" [ c.setup.args ]
            ))
            ++ c.lua
            ++ (map (v: toLuaFn "vim.cmd" [ v ]) (map vim2str c.vim))
            ++ (map (
              l:
              toLuaFn "vim.treesitter.language.add" [
                l
                { path = c.treesitter.parsers.${l}; }
              ]
            ) (builtins.attrNames c.treesitter.parsers))
            ++ (optional (c.lspconfig != null) (toLuaFn lspconfigWrapper [ c.lspconfig ]));

          init_lua =
            [ "-- generated by nix2nvimrc" ]
            ++ optionals (packages != [ ]) [
              "vim.opt.packpath:append('${config.packPath}')"
              "vim.opt.runtimepath:append('${config.packPath}')"
            ]
            ++ optional lspUsed "local ${lspconfigWrapper} = ${toLua ./nix-lspconfig.lua}"
            ++ builtins.concatMap (
              c:
              let
                lua = configToLua c;
              in
              if builtins.length lua <= 1 && c.plugins == [ ] then
                builtins.trace "Warning: configuration '${c.name}' has no configuration" [ ]
              else
                lua
            ) configs
            ++ [ "-- vim: set filetype=lua:" ];
        in
        builtins.concatStringsSep "\n" init_lua;

      opt = builtins.foldl' (a: b: a // b.opts) { } configs;
      var = builtins.foldl' (a: b: a // b.vars) { } configs;
      config = config.configs;

      _module.args.nix2nvimrc = import ./lib.nix;
    };
}
