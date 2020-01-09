{ buildPythonApplication
, python3Packages
, gitignoreSource
, hpos-config-py
}:

with python3Packages;

buildPythonApplication {
  name = "hpos-admin";
  src = gitignoreSource ./.;

  propagatedBuildInputs = [
    flask
    gevent
    hpos-config-py
  ];

  checkInputs = [ pytest ];
  checkPhase = ''
    python3 -m pytest
  '';
}
