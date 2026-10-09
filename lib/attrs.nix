{lib, ...}: {
  attrsToValueList = attrs:
    builtins.map
    (attr: attr.value)
    (lib.attrsToList attrs);
}
