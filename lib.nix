let
  luaExpr = lua: { type = "lua"; expression = lua; };

  toLuaFn = fn: args: "${fn}(${builtins.concatStringsSep "," (map toLua args)})";

  toLua = with builtins; val:
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
        "{"
        + (concatStringsSep "," (map (k: k + "=" + (toLua val.${k})) (attrNames val)))
        + "}"
    else if isList val then
      "{"
      + (concatStringsSep "," (map toLua val))
      + "}"
    else
      throw "type convertion is not implemented";

  toKeymap = def_opts: builtins.foldl' (f: f)
    (mode: lhs: rhs: opts: { inherit mode lhs rhs; opts = def_opts // opts; });

  moduleLib = { inherit luaExpr toLua toLuaFn toKeymap; };
in
moduleLib // {
  toRc = pkgs: config: (pkgs.lib.evalModules {
    specialArgs.lib = pkgs.lib.extend (final: prev: moduleLib);
    args.pkgs = pkgs;
    modules = [ ./module.nix config ];
  }).config.out;
}
