{ stdenv, rustPlatform, fetchFromGitHub, perl, CoreServices, Security, libsodium }:

rustPlatform.buildRustPackage {
  name = "holochain-rust";

  src = fetchFromGitHub {
    owner = "holochain";
    repo = "holochain-rust";
    rev = "v0.0.42-alpha4";
    sha256 = "0c2igvnmjh4l2gr8xq1pllxjniy03c30rsgwrm4lf5qjmn14ibp4";
  };

  cargoSha256 = "1cfk2z4pbk8dli31wpplczd8a1fy8fyhwa5rsl6yz3jzw9d2kdkk";

  nativeBuildInputs = [ perl ];

  buildInputs = stdenv.lib.optionals stdenv.isDarwin [
    CoreServices
    Security
  ];

  RUST_SODIUM_LIB_DIR = "${libsodium}/lib";
  RUST_SODIUM_SHARED = "1";

  doCheck = false;
}
