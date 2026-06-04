let
  toLua =
    with builtins;
    val:
    if val == null then
      "nil"
    else if isString val || isBool val || isInt val || isFloat val then
      toJSON val
    else if isPath val then
      "assert(loadfile('${val}'))()"
    else if isAttrs val then
      if val ? type && val.type == "derivation" then
        toLua "${val}"
      else if val ? type && val.type == "lua" then
        val.expression
      else
        "{" + (concatStringsSep "," (map (k: "[${toLua k}]=" + (toLua val.${k})) (attrNames val))) + "}"
    else if isList val then
      "{" + (concatStringsSep "," (map toLua val)) + "}"
    else
      throw "type convertion is not implemented";

  modules = pkgs: [
    {
      _module.args = {
        inherit pkgs;
      };
    }
    ./module.nix
  ];
in
{
  inherit toLua modules;

  luaExpr = lua: {
    type = "lua";
    expression = lua;
  };

  toLuaFn = fn: args: "${fn}(${builtins.concatStringsSep "," (map toLua args)})";

  toKeymap = def_opts: args: {
    mode = builtins.elemAt args 0;
    lhs = builtins.elemAt args 1;
    rhs = builtins.elemAt args 2;
    opts = def_opts // builtins.elemAt args 3;
  };

  toRc = pkgs: config: (pkgs.lib.evalModules { modules = (modules pkgs) ++ [ config ]; }).config.out;
}
