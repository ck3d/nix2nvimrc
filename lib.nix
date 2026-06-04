let
  inherit (builtins)
    isString
    isBool
    isInt
    isFloat
    isPath
    isAttrs
    isList
    concatStringsSep
    attrNames
    toJSON
    elemAt
    ;

  toLua =
    val:
    if val == null then
      "nil"
    else if isString val || isBool val || isInt val || isFloat val then
      toJSON val
    else if isPath val then
      "assert(loadfile('${val}'))()"
    else if isList val then
      "{" + (concatStringsSep "," (map toLua val)) + "}"
    else if isAttrs val then
      if val.type or null == "derivation" then
        toJSON (toString val)
      else if val.type or null == "lua" then
        val.expression
      else
        "{" + (concatStringsSep "," (map (k: "[${toLua k}]=" + (toLua val.${k})) (attrNames val))) + "}"
    else
      throw "type conversion is not implemented";

  modules = pkgs: [
    { _module.args = { inherit pkgs; }; }
    ./module.nix
  ];
in
{
  inherit toLua modules;

  luaExpr = lua: {
    type = "lua";
    expression = lua;
  };

  toLuaFn = fn: args: "${fn}(${concatStringsSep "," (map toLua args)})";

  toKeymap =
    def_opts: args:
    let
      at = elemAt args;
    in
    {
      mode = at 0;
      lhs = at 1;
      rhs = at 2;
      opts = def_opts // at 3;
    };

  toRc =
    pkgs: config:
    (pkgs.lib.evalModules {
      modules = modules pkgs ++ [ config ];
    }).config.out;
}
