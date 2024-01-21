{
  description = "Application packaged using poetry2nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # see https://github.com/nix-community/poetry2nix/tree/master#api for more functions and examples.
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication defaultPoetryOverrides;
      in
      {
        packages = {
          fido2-hid-bridge = mkPoetryApplication {
            projectDir = self;
            overrides = defaultPoetryOverrides.extend
              (self: super: {
                uhid = super.uhid.overridePythonAttrs (
                  old: {
                    buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                  }
                );
              });
          };
          default = self.packages.${system}.fido2-hid-bridge;
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.fido2-hid-bridge ];
          packages = [ pkgs.poetry ];
        };
      });
}
