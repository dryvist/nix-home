# Bitwarden Secrets Manager CLI — vendor binary package
#
# This intentionally does not use `pkgs.bws`. nixpkgs builds BWS from its Rust
# source and runs its upstream test graph, which added 7–13 minutes to every
# cold Home Manager activation build. Bitwarden publishes verified native
# archives for all four supported systems, so downloading the pinned release is
# the smallest reproducible package that preserves the `bws` command without a
# local Rust rebuild. Do not switch this back to nixpkgs or raise CI timeouts:
# fix a genuine source/build regression instead.
{
  fetchurl,
  stdenvNoCC,
  unzip,
}:

let
  version = "2.1.0";
  releases = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-nLHBxuYWTYOy4zmIO6ArTLs3GIzppISxzoJJRDFj4GY=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      hash = "sha256-b2JrOXE2iQKvG5hHwCeRobRmaWnXVh4gR2gc3teZdTc=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-gnu";
      hash = "sha256-GCU3VyhuEZ1FATOofrRjv4wc5BjOJMg09PJQ1gy6b54=";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-gnu";
      hash = "sha256-uoIzw6Su5dQ+PHO70E2Z6bxauhO7v9BtibBzq+cyuGA=";
    };
  };
  release =
    releases.${stdenvNoCC.hostPlatform.system}
      or (throw "unsupported BWS system: ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "bws";
  inherit version;

  # Bitwarden publishes the SHA-256 of each archive, so use fetchurl rather
  # than fetchzip (which would hash the extracted tree instead).
  src = fetchurl {
    url = "https://github.com/bitwarden/sdk-sm/releases/download/bws-v${version}/bws-${release.target}-${version}.zip";
    inherit (release) hash;
  };

  nativeBuildInputs = [ unzip ];
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    unzip "$src"
    install -Dm755 bws "$out/bin/bws"
  '';

  meta = {
    description = "Bitwarden Secrets Manager CLI";
    homepage = "https://bitwarden.com/help/secrets-manager-cli/";
    mainProgram = "bws";
    platforms = builtins.attrNames releases;
  };
}
