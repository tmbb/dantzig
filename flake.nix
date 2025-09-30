{
  description = "Dantzig";

  # inputs = {
  #   # NixOS official package source, here using the nixos-unstable branch
  #   nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # };

  outputs = {nixpkgs, ...}: let
    pkgs = import nixpkgs {system = "x86_64-linux";};

    commandName = "dantzigFHS";

    #
    # Basic packages used in all environments
    standardPackages = ps: (with ps; [
      # Utilities
      curl
      unzip
      utillinux
      which

      # Building
      patch
      binutils

      # IDE
      code-cursor
      vscode
    ]);

    elixirPackages = ps: (with ps; [
      # When running Phoenix
      inotify-tools
      watchman

      livebook
      beam28Packages.elixir_1_18
      beam28Packages.hex
      beam28Packages.rebar3
    ]);

    targetPkgs = ps: (standardPackages ps) ++ (elixirPackages ps);

    envvars = ''
      export EXTRA_CCFLAGS="-I/usr/include"
      export FONTCONFIG_FILE=/etc/fonts/fonts.conf
      export LIBARCHIVE=${pkgs.libarchive.lib}/lib/libarchive.so
    '';

    # FHS environment package
    dantzigFHS = pkgs.buildFHSEnv {
      name = commandName;

      targetPkgs = targetPkgs;
      # multiPkgs = pkgs: (with pkgs; [ zlib ]);

      runScript = "zsh"; # default is bash
      profile = envvars;

      # Misc extras
      extraOutputsToInstall = ["man" "dev"];
    };
  in {
    defaultPackage.x86_64-linux = dantzigFHS;
    packages.x86_64-linux.dantzigFHS = dantzigFHS;
    devShells.x86_64-linux.default = dantzigFHS;

    nixpkgs.config.allowUnfree = true;
  };
}
