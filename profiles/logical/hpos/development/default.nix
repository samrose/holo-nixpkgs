# TODO: remove this once switch to modules/profiles/* is complete

{
  imports = [ ../. ];

  profiles.development = {
    enable = true;
    features.overrideConductorConfig = true;
  };
}
