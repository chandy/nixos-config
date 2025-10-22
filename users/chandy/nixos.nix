{ pkgs, inputs, ... }:

{
  # https://github.com/nix-community/home-manager/pull/2408
  environment.pathsToLink = [ "/share/fish" ];

  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

  # Since we're using fish as our shell
  programs.fish.enable = true;

  users.users.chandy = {
    isNormalUser = true;
    home = "/home/chandy";
    extraGroups = [ "docker" "lxd" "wheel" ];
    shell = pkgs.fish;
    hashedPassword = "$y$j9T$vaWFu8fjXQUhMomuYD3zN1$SnhtIDxRauogUhIO/0kLsf8WmzV1XruRkXZtu7Zqil0";
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHMBwHW5dkl+SGLp5cILG2nfQ+6qw2Y01Emnir8QgObM chrisjhandy@gmail.com" ];
  };
}
