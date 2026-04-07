{
  buildPythonPackage,
  fetchPypi,
  docopt,
  flask,
  markdown,
  path-and-address,
  pygments,
  requests,
  setuptools,
  tabulate,
  werkzeug,
}:

buildPythonPackage rec {
  pname = "grip";
  # managed by: nix-update (deps-update-packages.yml)
  version = "4.6.2";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-PPbc4KoG7dZjF2kUBpr4PxncuQ86nEAScaz6cYcvjOM=";
  };

  dependencies = [
    docopt
    flask
    markdown
    path-and-address
    pygments
    requests
    tabulate
    werkzeug
  ];

  nativeBuildInputs = [ setuptools ];

  postPatch = ''
    mkdir -p grip/static grip/templates
  '';

  doCheck = false;
}
