# FIDO2 HID Bridge

This repository contains sources for a Linux virtual USB-HID
FIDO2 device.

This device will receive FIDO2 CTAP2.1 commands, and forward them
to an attached PC/SC authenticator.

This allows using authenticators over PC/SC from applications
that only support USB-HID, such as Firefox; with this program running
you can use NFC authenticators or Smartcards.

Note that this is a very early-stage application, but it does work with
Chrome and Firefox.

## NixOS Module

Add this repo as a flake input, and enable the `fido2-hid-bridge` service.
Now you can use your smart card for 2fa in your browser!

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    fido2-hid-bridge.url = "github:arilotter/fido2-hid-bridge";
  };

  outputs = { fido2-hid-bridge, ... }: {
    nixosConfigurations = {
      "hostname_here" = nixpkgs.lib.nixosSystem {
        modules = [
          inputs.fido2-hid-bridge.nixosModule
          {
            services = {
                pcscd.enable = true;
                fido2-hid-bridge.enable = true;
            };
          }
        ];
      };
    };
  };
}
```

If you're using an ACR122U, you might also need to blacklist the NFC kernel modules, and add the ACSCCID plugin for pcscd.

```nix
    # disable modules that conflict w/ smart card reader.
    boot.blacklistedKernelModules = [ "nfc" "pn533" "pn533_usb" ];
    services.pcscd = {
        enable = true;
        plugins = [ pkgs.acsccid ];
    };
```

## Running It

You'll need to install dependencies:

```shell
poetry install
```

And then launch the application in the created virtualenv. You might need to be root
or otherwise get access to raw HID devices (permissions on `/dev/uhid`):

```shell
sudo -E ./.venv/bin/python bridge.py
```

If you use `nix`, you can simply

```shell
nix develop
python3 ./bridge.py
```

## Implementation Details

This uses the Linux kernel UHID device facility, and the `python-fido2` library.
It relays USB-HID packets to PC/SC.

Nothing more to it than that.
