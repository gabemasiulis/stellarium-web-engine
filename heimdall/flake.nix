{
  description = "Nocturne: Stellarium Web Engine build for the Heimdall sky";

  # Pinned to the nixpkgs that built the engine deployed on 2026-10-11
  # (emscripten 4.0.12, scons 4.10.0, python 3.13.12).
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/b6018f87da91d19d0ab4cf979885689b469cdd41";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.emscripten pkgs.scons pkgs.python3 pkgs.gnumake ];
        # The emscripten cache in the Nix store is read-only; work on a copy.
        shellHook = ''
          export EM_CACHE="''${XDG_CACHE_HOME:-$HOME/.cache}/nocturne-emscripten"
          if [ ! -d "$EM_CACHE" ]; then
            mkdir -p "$EM_CACHE"
            cp -r ${pkgs.emscripten}/share/emscripten/cache/. "$EM_CACHE"/
            chmod -R u+w "$EM_CACHE"
          fi
        '';
      };
    };
}
