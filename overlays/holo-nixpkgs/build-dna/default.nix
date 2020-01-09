{ stdenv
, cargoToNix
, gitignoreSource
, npmToNix
, runCommand
, rustPlatform
, holochain-rust
, nodejs
, which
}:

{ name, src, nativeBuildInputs ? [], doCheck ? true, shell ? false }:

with stdenv.lib;

let
  this = runCommand name {} ''
    cp -r ${src} $out
    chmod +w $out
    ln -s ${holochain-rust.src} $out/holochain-rust
  '';
in

rustPlatform.buildRustPackage (
  {
    inherit name;

    nativeBuildInputs = nativeBuildInputs ++ [
      holochain-rust
      nodejs
      which
    ];

    cargoVendorDir = "vendor";
  } // optionalAttrs shell {
    shellHook = ''
      rm -f holochain-rust
      ln -s ${holochain-rust.src} holochain-rust
    '';
  } // optionalAttrs (shell == false) {
    src = this;

    preConfigure = ''
      ln -s ${cargoToNix this} vendor
    '';

    buildPhase = ''
      runHook preBuild

      hc package

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mv dist $out
      mkdir -p $out/nix-support
      echo "file binary-dist $out/${name}.dna.json" > $out/nix-support/hydra-build-products

      runHook postInstall
    '';

    meta.platforms = [ "x86_64-linux" ];
  }
)
