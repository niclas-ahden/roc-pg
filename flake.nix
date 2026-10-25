{
  description = "roc-pg-insane-in-the-membrane";

  nixConfig = {
    extra-substituters = [ "https://niclas-ahden.cachix.org" ];
    extra-trusted-public-keys = [ "niclas-ahden.cachix.org-1:FdGli1vBk0cTuVJV27Tau/JvlbW+Ly3pRwFByyqdke0=" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # The Roc compiler revision, keep the `?dir=src` at the end
    roc-src.url = "github:roc-lang/roc/54283d46d5bd1741dbe677f54ef4646eee4623ff?dir=src";
    roc-nix = {
      url = "github:niclas-ahden/roc-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.roc-src.follows = "roc-src";
    };
  };

  outputs = { nixpkgs, flake-utils, roc-nix, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Builds Roc using `ReleaseFast`. roc-nix's README lists the rest of
        # the build options, patches included.
        roc = roc-nix.packages.${system}.roc;

        # The same revision built `ReleaseSafe`, to chase a suspected
        # compiler fault. A safe build checks the compiler's own invariants,
        # so a fault that would be a bare SIGSEGV names itself instead.
        rocReleaseSafe = roc-nix.lib.${system}.mkRoc { optimize = "ReleaseSafe"; };
      in
      {
        formatter = pkgs.nixpkgs-fmt;

        packages = {
          inherit roc rocReleaseSafe;
          default = roc;
        };

        devShells = {
          default = pkgs.mkShell {
            buildInputs = [
              roc
              # tests.roc boots a throwaway Postgres (initdb + pg_ctl)
              pkgs.postgresql
              pkgs.watchexec
            ];

            shellHook = ''
              export ROC_LANGUAGE_SERVER_PATH=${roc}/bin/roc
            '';
          };
        };
      });
}
