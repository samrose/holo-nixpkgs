{ lib, ... }:

{
  imports = [ ../. ];

  services.nginx = {
    recommendedOptimisation = lib.mkDefault true;
    recommendedProxySettings = lib.mkDefault true;
    recommendedTlsSettings = lib.mkDefault true;
  };

  users.mutableUsers = lib.mkDefault false;
}
