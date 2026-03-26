{
  description = "P4lang packages development shell";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system} = {
        default = pkgs.mkShell {
          packages = [
            pkgs.dput-ng
            pkgs.debian-devscripts
            pkgs.dpkg
            pkgs.quilt
            pkgs.python3Packages.osc
          ];
        };
      };
    };
}
