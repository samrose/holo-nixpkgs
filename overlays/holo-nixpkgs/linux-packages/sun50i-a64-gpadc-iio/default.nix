{ stdenv, fetchFromGitHub, kernel }:

with stdenv.lib;

let
  inherit (stdenv.hostPlatform) system;
in

stdenv.mkDerivation (
  {
    pname = "sun50i-a64-gpadc-iio";
    version = kernel.version;

    src = fetchFromGitHub {
      owner = "Holo-Host";
      repo = "sun50i-a64-gpadc-iio";
      rev = "4db1d5b72f85968a527946a7837e8d3c9a771527";
      sha256 = "0kwzrd1kf3gzidiag2vlsyxkmsbw7xkkkvxxhzmy0ypchdiv10lx";
    };

    hardeningDisable = [ "pic" ];

    KERNELDIR = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";
    INSTALL_MOD_PATH = "\${out}";

    nativeBuildInputs = kernel.moduleBuildDependencies;

    meta.platforms = platforms.linux;
  } // optionalAttrs (stdenv.buildPlatform != stdenv.hostPlatform) {
    ARCH = {
      aarch64-linux = "arm64";
      x86_64-linux = "x86";
    }."${system}" or throw "unsupported host: ${system}";

    CROSS_COMPILE = stdenv.cc.targetPrefix;
  }
)
