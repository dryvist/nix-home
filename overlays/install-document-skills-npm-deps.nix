# Overlay providing install-document-skills-npm-deps as a proper Nix package.
# Idempotent wrapper around `npm install -g docx pptxgenjs` with a fast-path
# check, used by the document-skills home.activation entry.
_final: prev: {
  install-document-skills-npm-deps = prev.writeShellApplication {
    name = "install-document-skills-npm-deps";
    runtimeInputs = [
      prev.nodejs
      prev.jq
    ];
    text = builtins.readFile ../modules/home-manager/scripts/install-document-skills-npm-deps.sh;
  };
}
