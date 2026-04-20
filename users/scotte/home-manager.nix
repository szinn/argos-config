{ inputs, ... }:

{ config, lib, pkgs, ... }:

let
  sources = import ../../nix/sources.nix;
  isLinux = pkgs.stdenv.isLinux;

  # For our MANPAGER env var
  # https://github.com/sharkdp/bat/issues/1145
  manpager = (pkgs.writeShellScriptBin "manpager" ''
    cat "$1" | col -bx | bat --language man --style plain
  '');
in {
  # Home-manager 22.11 requires this be set. We never set it so we have
  # to use the old state version.
  home.stateVersion = "24.11";

  # Disabled for now since we mismatch our versions. See flake.nix for details.
  home.enableNixpkgsReleaseCheck = false;

  # We manage our own Nushell config via Chezmoi
  home.shell.enableNushellIntegration = false;

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages I always want installed. Most packages I install using
  # per-project flakes sourced with direnv and nix-shell, so this is
  # not a huge list.
  home.packages = [
    pkgs._1password-cli
    pkgs.argc
    pkgs.atuin
    pkgs.bat
    pkgs.bacon
    inputs.bacon-ls.defaultPackage.${pkgs.system}
    pkgs.chezmoi
    pkgs.clang
    pkgs.claude-code
    pkgs.delta
    pkgs.eza
    pkgs.fd
    pkgs.firefox
    pkgs.fzf
    pkgs.gh
    pkgs.ghostty
    pkgs.git
    pkgs.go
    pkgs.gopls
    pkgs.gum
    pkgs.htop
    pkgs.jq
    pkgs.nettools
    pkgs.nodePackages.bash-language-server
    pkgs.ripgrep
    pkgs.rofi
    pkgs.rust-analyzer
    pkgs.sesh
    pkgs.sops
    pkgs.starship
    pkgs.tmux
    pkgs.tree
    pkgs.watch
    pkgs.vscode-langservers-extracted
    pkgs.yaml-language-server
    pkgs.zoxide
  ];

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    MANPAGER = "${manpager}/bin/manpager";
  };

  xdg.configFile = {
    "rofi/config.rasi".text = builtins.readFile ./rofi;
  };

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs.gpg.enable = true;

  programs.direnv= {
    enable = true;
  };

  programs.jujutsu = {
    enable = true;
  };

  programs.neovim = {
    enable = true;
    package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
  };

  services.gpg-agent = {
    enable = isLinux;
    pinentry.package = pkgs.pinentry-tty;

    # cache the keys forever so we don't get asked for a password
    defaultCacheTtl = 31536000;
    maxCacheTtl = 31536000;
  };

  xresources.extraConfig = builtins.readFile ./Xresources;

  # Make cursor not tiny on HiDPI screens
  home.pointerCursor = lib.mkIf isLinux {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
    x11.enable = true;
  };
}
