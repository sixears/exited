{
  description = "An Exited DataType, to represent program exit better than ()";

  inputs = {
    nixpkgs.url       = github:nixos/nixpkgs/be44bf67; # nixos-22.05 2022-10-15
    build-utils.url   = github:sixears/flake-build-utils/r1.0.0.13;

    has-callstack.url = github:sixears/has-callstack/r1.0.1.18;
    monaderror-io.url = github:sixears/monaderror-io/r1.2.5.19;
    more-unicode.url  = github:sixears/more-unicode/r0.0.17.12;
  };

  outputs = { self, nixpkgs, build-utils
            , has-callstack, monaderror-io, more-unicode }:
    build-utils.lib.hOutputs self nixpkgs "exited" {
#      deps = { inherit has-callstack monaderror-io more-unicode; };
      ghc = p: p.ghc8107; # for tfmt

      callPackage = { mkDerivation, lib, mapPkg, system
                    , base, base-unicode-symbols, data-textual, mtl }:
        let
          pkg = build-utils.lib.flake-def-pkg system;
        in
          mkDerivation {
            pname = "exited";
            version = "1.0.4.22";
            src = ./.;
            libraryHaskellDepends = [
              base base-unicode-symbols data-textual mtl
            ] ++ map (p: pkg p) [ has-callstack monaderror-io more-unicode ];

            testHaskellDepends = [ base ];
            description = "An Exited DataType, to represent program exit better than ()";
            license = lib.licenses.mit;
          };
    };
}
