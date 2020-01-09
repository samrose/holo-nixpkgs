final: previous:

with final;

let
  happ-store = fetchFromGitHub {
    owner = "holochain";
    repo = "happ-store";
    rev = "11b4a43e4fe12c71e1efc3a19ccfab021bc8ede9";
    sha256 = "07azyb4gspabh13h9cxwkpmlissqah88viy7m6dmq0sh0cdbir7k";
  };

  holofuel = fetchurl {
    url = "https://holo-host.github.io/holofuel/releases/download/v0.14.1-alpha1/holofuel.dna.json";
    name = "holofuel.dna.json";
    sha256 = "0bkixlh5ass5p9xzi4hh31z2lyw29qbn742fmnlbl6zi6y5qrsjd";
  };

  holo-hosting-app = fetchFromGitHub {
    owner = "Holo-Host";
    repo = "holo-hosting-app";
    rev = "da3f1c4efdf6634fe8ca255ff0baf399c2f4fbb4";
    sha256 = "1jlx1992zc9xc1gc12iqy409qf1nakpmsrn0lrr97p76r55igacz";
  };

  holo-communities-dna = fetchFromGitHub {
    owner = "Holo-Host";
    repo = "holo-communities-dna";
    rev = "53f204094e35f21bdd5009ed43cc16b093560737";
    sha256 = "0jyjj1762d905ysgkhg3p062vp9rmx552nb87z6n4vb11lm3hhh6";
   };

  servicelogger = fetchFromGitHub {
    owner = "Holo-Host";
    repo = "servicelogger";
    rev = "389d6f7c1f0bb4e514a9d4ea56d5220992abed89";
    sha256 = "13q78mc33h3d4rvmbh7sqzh8rlpxf895b656jji4g74m1ps1cd10";
  };
in

{
  inherit (callPackage happ-store {}) happ-store;

  inherit (callPackage holo-hosting-app {}) holo-hosting-app;

  inherit (callPackage holo-communities-dna {}) holo-communities-dna;

  inherit (callPackage servicelogger {}) servicelogger;

  holofuel = wrapDNA holofuel;
}
