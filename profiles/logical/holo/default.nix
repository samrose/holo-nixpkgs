{ lib, ... }:

{
  imports = [
    ../.
    ../binary-cache.nix
    ../self-aware.nix
  ];

  time.timeZone = "UTC";

  # Anyone in this list is in a position to poison binary cache, commit active
  # MITM attack on hosting traffic, maliciously change client assets to capture
  # users' keys during generation, etc. Please don't add anyone to this list
  # unless absolutely required. Once U2F support in SSH stabilizes, we will
  # require that everyone on this list uses it along with a hardware token. We
  # also should set up sudo_pair <https://github.com/square/sudo_pair>.
  users.users.root.openssh.authorizedKeys.keys = lib.mkForce [
    # Sam Rose
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDZjtunUHW+Zd7UEzWQ2myqjgmIDTU+lo9lqhkhKW9LGY8yjcdhlgHwhmYUEWkmLbwrQz7vGzACFkhJ4R/2FHPleja+xrWebABWoabcPtFUrGUtSYZM0Ui2VYzhKX7Rxd4qbbF9bejdYeUMSox8RVuBlToyHC1+UgIpkfjm2Y7MTh46ILzpavWvSaHAhvcQi1qQ7kUaVGSdi3+wouMC8R6cjGo/7rCuobIH8cEA+L2IlMox8QE7gnBlP1YvFLSKGn65Jk1490uP7ZRpDphu8yy0mG4K4VjJ48k75L9gZPrFlF/1nRGELUBRdYAdoushYCMP/Kmg1yKsvRJt3UeOkbphiQLUNO3w2qSNiz+RMzM3HCtz2quENyD7UVVyF8kt5z5TMYjj847xCRJKUoDCzGAMCKm1hzrDMGARgpJDPNWSlXC+Hz3/LCwVZXiJy7xunAjJfRv/o4Oo3wbPm7u/AAP6+bIHsji9Nl4y3NuYJHZfs9DHTPONjyEorqLGfLqqzcD93OVo/f6tCMSC5gDyeLUT2/8UXTkMijPNOIJGnfLo6MjU1uGkhN64P1imm57qDILbpG71IJZZf7kX3K0EKPb82i5q5LYepLuWeYqmy+bOqyLBN1v8kFD/Pps4x7nCa4dviH4sy+lJslJizZP9ZFKg4jCVOfCK1zhycofYgKqlKQ=="
    # Yegor Timoshenko
    ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHLGgzH3ROvo65cnvkXmuz7Qc9bPvU+L2SrafQh0bMrK''
  ];
}
