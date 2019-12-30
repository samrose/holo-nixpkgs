{ pkgs ? import ./. {} }:

with pkgs;

mkJobsets {
  owner = "Holo-Host";
  repo = "holo-nixpkgs";
  branches = [ "develop" "master" ];
  pullRequests = <holo-nixpkgs-pull-requests>;
}
