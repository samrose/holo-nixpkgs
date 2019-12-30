{ buildPythonApplication
, buildPythonPackage
, fetchFromGitHub
, gitignoreSource
, magic-wormhole
}:

let
  hpos-seed = buildPythonPackage rec {
    name = "hpos_seed";

    src = fetchFromGitHub {
      owner = "Holo-Host";
      repo = "hpos-seed";
      rev = "67860acb797dceadf499e77231d76ef5f79821d7";
      sha256 = "07s26ki4v75ssdlqf8i7nb537w2zr6krq09yc2c7w7nyb8q4arl7";
    };

    propagatedBuildInputs = [ magic-wormhole ];
    doCheck = false;
  };
in

buildPythonApplication {
  name = "hpos-init";
  src = gitignoreSource ./.;

  propagatedBuildInputs = [ hpos-seed ];
}
