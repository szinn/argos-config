{
  description = "NixOS systems and tools by scotte";

  inputs = {
    # Pin our primary nixpkgs repository. This is the main nixpkgs repository
    # we'll use for our configurations. Be very careful changing this because
    # it'll impact your entire system.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    # Used to get ibus 1.5.29 which has some quirks we want to test.
    nixpkgs-old-ibus.url = "github:nixos/nixpkgs/e2dd4e18cc1c7314e24154331bae07df76eb582f";

    # We use the unstable nixpkgs repo for some packages.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Master nixpkgs is used for really bleeding edge packages. Warning
    # that this is extremely unstable and shouldn't be relied on. Its
    # mostly for testing.
    nixpkgs-master.url = "github:nixos/nixpkgs";

    # snapd
    nix-snapd.url = "github:nix-community/nix-snapd";
    nix-snapd.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # I think technically you're not supposed to override the nixpkgs
    # used by neovim but recently I had failures if I didn't pin to my
    # own. We can always try to remove that anytime.
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
    };

    # Other packages
    jujutsu.url = "github:martinvonz/jj";
    zig.url = "github:mitchellh/zig-overlay";
    bacon-ls.url = "github:crisidev/bacon-ls";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: let
    # Overlays is the list of overlays we want to apply from flake inputs.
    overlays = [
      inputs.jujutsu.overlays.default
      inputs.zig.overlays.default

      (final: prev: rec {
        # xrdb was removed as a top-level package; it now lives under xorg.
        xrdb = final.xorg.xrdb;

        # gh CLI on stable has bugs.
        gh = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.gh;

        # Want the latest version of these
        claude-code = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.claude-code;
        # nushell = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.nushell;

        ibus = ibus_stable;
        ibus_stable = inputs.nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}.ibus;
        ibus_1_5_29 = inputs.nixpkgs-old-ibus.legacyPackages.${prev.stdenv.hostPlatform.system}.ibus;
        ibus_1_5_31 = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.ibus;
      })
    ];

    mkSystem = import ./lib/mksystem.nix {
      inherit overlays nixpkgs inputs;
    };
  in {
    nixosConfigurations.vm-aarch64 = mkSystem "vm-aarch64" {
      system = "aarch64-linux";
      user   = "scotte";
    };
  };
}
