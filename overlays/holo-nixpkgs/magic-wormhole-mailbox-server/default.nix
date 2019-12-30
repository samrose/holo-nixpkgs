{ buildPythonPackage
, fetchPypi
, python
, autobahn
, mock
, pyopenssl
, service-identity
, treq
, twisted
}:

buildPythonPackage rec {
  pname = "magic-wormhole-mailbox-server";
  version = "0.4.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1yw8i8jv5iv1kkz1aqimskw7fpichjn6ww0fq0czbalwj290bw8s";
  };

  passthru = { inherit python; };

  propagatedBuildInputs = [
    autobahn
    mock
    pyopenssl
    service-identity
    treq
    twisted
  ];
}
