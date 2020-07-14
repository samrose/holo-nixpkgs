{ stdenv, rustPlatform, fetchFromGitHub, perl, CoreServices, Security, libsodium }:

rustPlatform.buildRustPackage {
  name = "holochain-rust";

  src = fetchFromGitHub {
    owner = "holochain";
    repo = "holochain-rust";
    rev = "v0.0.50-alpha4";
    sha256 = "03rdn82p605hh55367xwgrg0lxqdpg4xm9fc1n5nlili9fs7554l";
  };

  cargoSha256 = "1rb2fkpz2l0xdhkiim9wzr7bxl2gwm6n2j37nmr1rgpbl182mivx";

  nativeBuildInputs = [ perl ];

  buildInputs = stdenv.lib.optionals stdenv.isDarwin [
    CoreServices
    Security
  ];

  RUST_SODIUM_LIB_DIR = "${libsodium}/lib";
  RUST_SODIUM_SHARED = "1";

  doCheck = false;
}
