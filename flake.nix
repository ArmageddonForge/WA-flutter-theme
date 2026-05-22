{
  description = "Flutter Linux desktop dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            clang
            cmake
            ninja
            pkg-config
            gtk3
            glib
            libepoxy
            fontconfig
          ];

          # Flutter's CMake config inspects $CXX; force clang so the Linux
          # toolchain check passes even if gcc is also on PATH.
          CXX = "clang++";
          CC = "clang";

          shellHook = ''
            export CHROME_EXECUTABLE=${pkgs.chromium}/bin/chromium
            # libflutter_linux_gtk.so has NEEDED entries for libepoxy/libfontconfig;
            # ld needs them visible at link time (indirect deps → -rpath-link/LD_LIBRARY_PATH).
            export LD_LIBRARY_PATH=${
              pkgs.lib.makeLibraryPath [ pkgs.libepoxy pkgs.fontconfig pkgs.gtk3 pkgs.glib ]
            }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
          '';
        };
      });
}
