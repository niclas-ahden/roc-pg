{
  description = "roc-pg";

  # The Roc compiler this flake pins is built from source, which takes half an
  # hour, so it is served from a binary cache instead. Push a new one with:
  #
  #   nix build .#roc --no-link --print-out-paths | cachix push niclas-ahden
  #
  # after changing flake.lock or the roc derivation below.
  nixConfig = {
    extra-substituters = [ "https://niclas-ahden.cachix.org" ];
    extra-trusted-public-keys = [ "niclas-ahden.cachix.org-1:FdGli1vBk0cTuVJV27Tau/JvlbW+Ly3pRwFByyqdke0=" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    roc-src = {
      url = "github:roc-lang/roc/94cbed386c51a8739ced3be76e7ab7b84dd22852";
      flake = false;
    };
  };

  outputs = { nixpkgs, flake-utils, roc-src, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) lib;

        version = roc-src.shortRev or "dirty";

        zig = pkgs.zig_0_16;

        vendored = pkgs.callPackage "${roc-src}/build.zig.zon.nix" { inherit zig; };

        bootstrapBase = "https://github.com/roc-lang/roc-bootstrap/releases/download/zig-0.16.0-binaryen";
        hostBootstrap = {
          "x86_64-linux" = { pkgHash = "N-V-__8AAGJLMhhn8pu3uyxtKTIlha8CxCjE6TNpLYvvj-cz"; file = "x86_64-linux-musl.tar.xz"; sha256 = "sha256-rvj4CqOfLibgPjdxDDFl9Rspwr9NOqQDNuqZqCmdiiQ="; };
          "aarch64-linux" = { pkgHash = "N-V-__8AACK4KheKSiltX0PPURTNh0CvJhsopNXzcXpvq9pS"; file = "aarch64-linux-musl.tar.xz"; sha256 = "sha256-Uienx53sFqoov9R3r1Rl8MOOuevyDfRFTTQdEy1FLxw="; };
          "x86_64-darwin" = { pkgHash = "N-V-__8AAJrG0hG7ZWMT8yxRBa17ivn77bWqDpseO904PYT7"; file = "x86_64-macos-none.tar.xz"; sha256 = "sha256-itVlXxuYFxdOSYm2dasTI0NXgzi5vCIu9k7otvLLd2s="; };
          "aarch64-darwin" = { pkgHash = "N-V-__8AAKS-VRH7JXsaDHpnFPSd-B5fSdtnDbh0XrfnncWc"; file = "aarch64-macos-none.tar.xz"; sha256 = "sha256-SDwhz/eUhlhEJght1kX5ng0Z6JiFNWIk30H3rgpxUyw="; };
        }.${system};

        hostBootstrapPkg = pkgs.runCommand "roc-host-bootstrap-${system}"
          {
            src = pkgs.fetchurl {
              url = "${bootstrapBase}/${hostBootstrap.file}";
              hash = hostBootstrap.sha256;
            };
          } ''
          mkdir -p "$out/${hostBootstrap.pkgHash}"
          tar -xf "$src" -C "$out/${hostBootstrap.pkgHash}" --strip-components=1
        '';

        roc-deps = pkgs.symlinkJoin {
          name = "roc-zig-packages";
          paths = [ vendored hostBootstrapPkg ];
        };

        roc = pkgs.stdenv.mkDerivation {
          pname = "roc";
          inherit version;
          src = roc-src;

          # roc-lang/roc#10562, rebased onto the pin (the PR branches off an
          # older main and conflicts there, but the only conflicts were the
          # serialized-layout version bump and its golden hash, both taken
          # from the PR). It fixes the exponential specialization of open Try
          # chains (#10529), which otherwise makes builds take minutes. Drop
          # this once the PR is merged and the pin moves past it.
          patches = [ ./nix/roc-pr-10562.patch ];

          nativeBuildInputs = [ zig ];

          dontConfigure = true;

          buildPhase = ''
            export HOME=$TMPDIR

            # `--system` points Zig at the prevendored package set (looked up by
            # bare hash), so the build never touches the network. Zig still
            # wants writable cache dirs, so keep those under $TMPDIR.
            zig build roc -Doptimize=ReleaseSafe \
              --system ${roc-deps} \
              --cache-dir $TMPDIR/zig-local-cache \
              --global-cache-dir $TMPDIR/zig-global-cache
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp zig-out/bin/roc $out/bin/
          '';

          meta = {
            description = "Roc";
            homepage = "https://github.com/roc-lang/roc";
            license = lib.licenses.upl;
            mainProgram = "roc";
            platforms = lib.platforms.unix;
          };
        };
      in
      {
        formatter = pkgs.nixpkgs-fmt;

        packages = {
          inherit roc roc-deps;
          default = roc;
        };

        devShells = {
          default = pkgs.mkShell {
            # tests.roc boots a throwaway Postgres (initdb + pg_ctl) for the
            # integration tests, so the dev shell provides the server binaries.
            buildInputs = [
              roc
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
