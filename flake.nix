{
  description = "just-build-fdb — `just` + Docker wrapper around the FoundationDB Rocky 9 build container.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          name = "just-build-fdb";

          packages = with pkgs; [
            just
            docker-client
            git
            jq
            ripgrep
            libxml2
          ];

          shellHook = ''
            echo "just-build-fdb shell."
            echo "  just            — list recipes"
            echo "  just bootstrap  — clone all configured upstream repos"
            echo
            if ! docker info >/dev/null 2>&1; then
              echo "warning: docker daemon is not reachable."
              echo "  on NixOS, ensure virtualisation.docker.enable = true;"
              echo "  and that you are in the 'docker' group (or use rootless docker)."
            fi
          '';
        };
      });
}
