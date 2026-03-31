{
  description = "Development shell for the gmmyung.github.io Hugo site";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system:
          f (import nixpkgs {
            inherit system;
          }));
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            git
            hugo
            zsh
          ];

          shellHook = ''
            export HUGO_CACHEDIR="$PWD/.hugo_cache"
            export SHELL="${pkgs.zsh}/bin/zsh"

            if [ -n "$PS1" ] && [ -z "$ZSH_VERSION" ]; then
              echo "Hugo dev shell ready. Run: hugo server -D"
              exec "${pkgs.zsh}/bin/zsh"
            fi
          '';
        };
      });
    };
}
