{
  description = "Virtual USB-HID FIDO2 device that receives FIDO2 CTAP2.1 commands & and forwards them to an attached PC/SC authenticator.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, poetry2nix }:
    let system = "x86_64-linux"; in
    let
      # see https://github.com/nix-community/poetry2nix/tree/master#api for more functions and examples.
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication defaultPoetryOverrides;
    in
    {
      packages.x86_64-linux = {
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

      nixosModule = { config, lib, pkgs, ... }: with lib; let
        cfg = config.services.fido2-hid-bridge;
      in
      {
        options.services.fido2-hid-bridge = {
          enable = lib.mkEnableOption "enable the fido2-hid-bridge service";
        };

        config = lib.mkIf cfg.enable {
          systemd.services.fido2-hid-bridge = {
            description = "FIDO2 to HID bridge";
            after = [ "auditd.service" "syslog.target" "network.target" "local-fs.target" "pcscd.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "simple";
              ExecStart = "${self.packages.${system}.fido2-hid-bridge}/bin/fido2-hid-bridge";
            };
          };
        };
      };
    };
}
