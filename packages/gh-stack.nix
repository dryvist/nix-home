{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:

buildGoModule rec {
  pname = "gh-stack";
  # managed by: nix-update (deps-update-packages.yml)
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "github";
    repo = "gh-stack";
    rev = "v${version}";
    hash = "sha256-jwfqiCnCOOW0AKA52hbgvCCoLzfFX+QfM+vXABkzZgw=";
  };

  vendorHash = "sha256-0Xtr/MOpX4u5GnbRdNxKPA0GpSzi8PIbVc9MmP05De4=";

  # Root main package only; the module's other packages are libraries.
  subPackages = [ "." ];

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "GitHub CLI extension for managing stacked branches and pull requests";
    homepage = "https://github.com/github/gh-stack";
    license = lib.licenses.mit;
    mainProgram = "gh-stack";
  };
}
