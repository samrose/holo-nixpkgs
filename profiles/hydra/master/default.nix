{ config, ... }:

{
  imports = [ ../. ../master.nix ];

  nix.buildMachines = [
    {
      hostName = "localhost";
      maxJobs = config.nix.maxJobs;
      supportedFeatures = [
        "benchmark"
        "big-parallel"
        "kvm"
        "nixos-test"
      ];
      system = "x86_64-linux";
    }
    {
      hostName = "hydra-aarch64-linux.holo.host";
      maxJobs = 96;
      sshKey = "/var/lib/hydra/queue-runner/.ssh/id_ed25519";
      sshUser = "root";
      supportedFeatures = [
        "benchmark"
        "big-parallel"
        "kvm"
        "nixos-test"
      ];
      system = "aarch64-linux";
    }
  ];

  services.postgresql.extraConfig = ''
    max_connections = 1024
  '';

  services.hydra.extraConfig = ''
    binary_cache_public_uri = https://cache.holo.host
    log_prefix = https://holo.s3.wasabisys.com/
    max_output_size = 17179869184
    server_store_uri = https://holo.s3.wasabisys.com?local-nar-cache=/var/cache/hydra/nar-cache
    store_uri = s3://holo?endpoint=s3.wasabisys.com&log-compression=br&ls-compression=br&parallel-compression=1&secret-key=/var/lib/hydra/queue-runner/keys/cache.holo.host-1/secret&write-nar-listing=1
    upload_logs_to_binary_cache = true
  '';

  services.nginx = {
    # HoloPortOS points to https://cache.holo.host for binary cache. It points
    # to a domain that we control so that we have flexibility to move the bucket
    # somewhere else in the future.
    virtualHosts.binary-cache = {
      enableACME = true;
      forceSSL = true;
      globalRedirect = "holo.s3.wasabisys.com";
      serverName = "cache.holo.host";
    };

    virtualHosts.hydra.serverName = "hydra.holo.host";

    # First HoloPort/HoloPort+ batch points to Hydra-based Nix channel on
    # holoportbuild.holo.host. This has to be left here forever for reverse-
    # compatibility reasons.
    virtualHosts.hydra-legacy = {
      enableACME = true;
      forceSSL = true;
      globalRedirect = "hydra.holo.host";
      serverName = "holoportbuild.holo.host";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/cache/hydra           0755 hydra hydra -  -"
    "d /var/cache/hydra/nar-cache 0775 hydra hydra 1d -"
  ];
}