# Changelog

## [1.43.0](https://github.com/dryvist/nix-home/compare/v1.42.3...v1.43.0) (2026-08-30)


### Features

* **darwin:** add the coding-agent usage collector LaunchAgent ([#455](https://github.com/dryvist/nix-home/issues/455)) ([98dd71b](https://github.com/dryvist/nix-home/commit/98dd71b1249f52d3adf68946a0548c99ae42bdc2))

## [1.42.3](https://github.com/dryvist/nix-home/compare/v1.42.2...v1.42.3) (2026-08-28)


### Bug Fixes

* **monitoring:** require an OTLP endpoint and default to http/protobuf ([f18fd42](https://github.com/dryvist/nix-home/commit/f18fd42d42bfc526e35bb7a485d1b40e517ca14d))
* **monitoring:** require an OTLP endpoint and default to http/protobuf ([c2593bd](https://github.com/dryvist/nix-home/commit/c2593bd57001492ad5dd6aa2f25b1200e5ebc595))

## [1.42.2](https://github.com/dryvist/nix-home/compare/v1.42.1...v1.42.2) (2026-08-27)


### Bug Fixes

* **gh-guard:** judge against the resident model, and sharpen the prompt ([#444](https://github.com/dryvist/nix-home/issues/444)) ([04c9eed](https://github.com/dryvist/nix-home/commit/04c9eed4716564e1b6aa1c6773cd56e4a0054c8f))

## [1.42.1](https://github.com/dryvist/nix-home/compare/v1.42.0...v1.42.1) (2026-08-22)


### Bug Fixes

* **packages:** cut the Swift toolchain out of the pre-commit closure ([#439](https://github.com/dryvist/nix-home/issues/439)) ([33ef0e4](https://github.com/dryvist/nix-home/commit/33ef0e41e1108b153db2390341622347083a6823))
* **packages:** pass emptyDirectory for pre-commit's dotnet-sdk argument ([#440](https://github.com/dryvist/nix-home/issues/440)) ([20c3f2f](https://github.com/dryvist/nix-home/commit/20c3f2f9ff1c5e4fed3abb84b608ea6a0c2d49a5))

## [1.42.0](https://github.com/dryvist/nix-home/compare/v1.41.0...v1.42.0) (2026-08-15)


### Features

* **gh:** package gh-guard publish-boundary gate ([#429](https://github.com/dryvist/nix-home/issues/429)) ([78940a3](https://github.com/dryvist/nix-home/commit/78940a37633ba5ccc1d11c5c346ef83ffd82ddae))


### Bug Fixes

* **overlays:** build markitdown with only the pptx converter's dependencies ([#433](https://github.com/dryvist/nix-home/issues/433)) ([704c950](https://github.com/dryvist/nix-home/commit/704c95012bf15bb274a611d630c14ce7345c700b))
* use Bitwarden release binary ([fdfd8bf](https://github.com/dryvist/nix-home/commit/fdfd8bfe087af500462a96f504d727442c7bcfc3))
* use Bitwarden release binary ([3a54dc5](https://github.com/dryvist/nix-home/commit/3a54dc5194100c0573a5835d179e8edf95e42dfe))

## [1.41.0](https://github.com/dryvist/nix-home/compare/v1.40.0...v1.41.0) (2026-08-05)


### Features

* **ci:** relock the whole flake into a single pull request ([#422](https://github.com/dryvist/nix-home/issues/422)) ([013fe22](https://github.com/dryvist/nix-home/commit/013fe22db38d1cbd89977749618403fb1a41227c))

## [1.40.0](https://github.com/dryvist/nix-home/compare/v1.39.1...v1.40.0) (2026-08-02)


### Features

* **packages:** ship flow-lock and deployment-json in the cloud group ([#416](https://github.com/dryvist/nix-home/issues/416)) ([cf97d10](https://github.com/dryvist/nix-home/commit/cf97d108f979f9395fdfe197f40571c417484aa4))

## [1.39.1](https://github.com/dryvist/nix-home/compare/v1.39.0...v1.39.1) (2026-08-02)


### Bug Fixes

* **ci:** drop unused id-token: write from ci-fix.yml ([#411](https://github.com/dryvist/nix-home/issues/411)) ([4c9bc9f](https://github.com/dryvist/nix-home/commit/4c9bc9fc963f5c483b6fabe511f98baed10130a7))

## [1.39.0](https://github.com/dryvist/nix-home/compare/v1.38.1...v1.39.0) (2026-07-30)


### Features

* **ci:** refresh nixpkgs channel pin on a schedule ([#401](https://github.com/dryvist/nix-home/issues/401)) ([655e239](https://github.com/dryvist/nix-home/commit/655e2396e08ec3bc348973da21fae8d23ca2ed6e))

## [1.38.1](https://github.com/dryvist/nix-home/compare/v1.38.0...v1.38.1) (2026-07-20)


### Bug Fixes

* **deps:** refresh gh-aw action SHA pins [aw:gh-aw-pin-refresh] ([#386](https://github.com/dryvist/nix-home/issues/386)) ([6b52692](https://github.com/dryvist/nix-home/commit/6b52692fdc4906536883e07e8d848fcbec0a3810))

## [1.38.0](https://github.com/dryvist/nix-home/compare/v1.37.1...v1.38.0) (2026-07-16)


### Features

* **aws:** add openbao-iac-admin credential_process profile ([#382](https://github.com/dryvist/nix-home/issues/382)) ([972848a](https://github.com/dryvist/nix-home/commit/972848af2ef2268232b9e553d17c8e1b3c04acd3))


### Bug Fixes

* **deps:** refresh gh-aw action SHA pins [aw:gh-aw-pin-refresh] ([#377](https://github.com/dryvist/nix-home/issues/377)) ([aa3ced0](https://github.com/dryvist/nix-home/commit/aa3ced0d8f54f546f510c8cffd34bc3416e31049))

## [1.37.1](https://github.com/dryvist/nix-home/compare/v1.37.0...v1.37.1) (2026-07-13)


### Bug Fixes

* **tmux:** robust autostart logging (log paths + PATH for run-shell hooks) ([#372](https://github.com/dryvist/nix-home/issues/372)) ([bf6a4f8](https://github.com/dryvist/nix-home/commit/bf6a4f8bf27288f00a0e78d8313c0d3a9ce08634))

## [1.37.0](https://github.com/dryvist/nix-home/compare/v1.36.0...v1.37.0) (2026-07-12)


### Features

* **aws:** serve tf-proxmox creds via OpenBao credential_process ([#368](https://github.com/dryvist/nix-home/issues/368)) ([4df7a40](https://github.com/dryvist/nix-home/commit/4df7a40bdf69c2bf62304e8f1ff03280c5b5dfed))
* **tmux:** mobile/Termius ergonomics ([#365](https://github.com/dryvist/nix-home/issues/365)) ([e90b0d9](https://github.com/dryvist/nix-home/commit/e90b0d9c3976669a087105e4e82bbf7af6dab3f3))


### Bug Fixes

* point GIT_HOME_PRIVATE at the new private workspace root ([#366](https://github.com/dryvist/nix-home/issues/366)) ([5545404](https://github.com/dryvist/nix-home/commit/5545404f8be6b7288177d12d16443a6f9d62420f))
* **tmux-autostart:** move launchd logs from /tmp to ~/Library/Logs ([#369](https://github.com/dryvist/nix-home/issues/369)) ([1501f3d](https://github.com/dryvist/nix-home/commit/1501f3d8fbb2a91da1b64f5814e093216946cfaa))

## [1.36.0](https://github.com/dryvist/nix-home/compare/v1.35.1...v1.36.0) (2026-07-09)


### Features

* **git:** configure global git-flow-next branch model ([#363](https://github.com/dryvist/nix-home/issues/363)) ([0fdf073](https://github.com/dryvist/nix-home/commit/0fdf0731221a79c20e0b3e4a40c0dff2ee4aa858))

## [1.35.1](https://github.com/dryvist/nix-home/compare/v1.35.0...v1.35.1) (2026-07-09)


### Bug Fixes

* **deps:** refresh gh-aw action SHA pins [aw:gh-aw-pin-refresh] ([#361](https://github.com/dryvist/nix-home/issues/361)) ([ecfd293](https://github.com/dryvist/nix-home/commit/ecfd29396908ac8d57c9345effb477d0c32df2ee))

## [1.35.0](https://github.com/dryvist/nix-home/compare/v1.34.1...v1.35.0) (2026-07-07)


### Features

* **zsh:** d-r rebuilds from the canonical remote flake ([#355](https://github.com/dryvist/nix-home/issues/355)) ([7f89b5d](https://github.com/dryvist/nix-home/commit/7f89b5d3cc3d90f08cab4539a2803205ec26d146))

## [1.34.1](https://github.com/dryvist/nix-home/compare/v1.34.0...v1.34.1) (2026-07-06)


### Bug Fixes

* **deps:** refresh gh-aw action SHA pins [aw:gh-aw-pin-refresh] ([#351](https://github.com/dryvist/nix-home/issues/351)) ([72f3b7b](https://github.com/dryvist/nix-home/commit/72f3b7b639847b884cea7a5ace5dc445ef7c2967))

## [1.34.0](https://github.com/dryvist/nix-home/compare/v1.33.1...v1.34.0) (2026-07-05)


### Features

* **darwin:** set HF_HOME on all Macs, not just workstations ([#349](https://github.com/dryvist/nix-home/issues/349)) ([8725a98](https://github.com/dryvist/nix-home/commit/8725a9897e5fcb2797f79d1d76bd45f56bb59dbf))

## [1.33.1](https://github.com/dryvist/nix-home/compare/v1.33.0...v1.33.1) (2026-07-04)


### Bug Fixes

* nixfmt-rfc-style -&gt; nixfmt (nixpkgs deprecation alias) ([#343](https://github.com/dryvist/nix-home/issues/343)) ([557e343](https://github.com/dryvist/nix-home/commit/557e3434407704cf4b08bf05f86641f1e84209c2))

## [1.33.0](https://github.com/dryvist/nix-home/compare/v1.32.0...v1.33.0) (2026-07-04)


### Features

* enable issues:labeled trigger to close the auto-resolve loop ([#344](https://github.com/dryvist/nix-home/issues/344)) ([2f600a3](https://github.com/dryvist/nix-home/commit/2f600a35fd5d75e82f0c117bd1ecb99c64d01af4))

## [1.32.0](https://github.com/dryvist/nix-home/compare/v1.31.0...v1.32.0) (2026-07-04)


### Features

* **profiles:** gate aws-config keychain generator behind server preset ([#341](https://github.com/dryvist/nix-home/issues/341)) ([77e34c3](https://github.com/dryvist/nix-home/commit/77e34c31d7ed06fe643ee77a8f9f4787ad30499c))

## [1.31.0](https://github.com/dryvist/nix-home/compare/v1.30.0...v1.31.0) (2026-07-03)


### Features

* add issue-backlog-sweep caller ([#339](https://github.com/dryvist/nix-home/issues/339)) ([47c8496](https://github.com/dryvist/nix-home/commit/47c849692ace496e1b32e4fef80d0fad2a5e36f8))

## [1.30.0](https://github.com/dryvist/nix-home/compare/v1.29.2...v1.30.0) (2026-07-03)


### Features

* add AI PR care caller (dep review + release highlights) ([#336](https://github.com/dryvist/nix-home/issues/336)) ([aafdc83](https://github.com/dryvist/nix-home/commit/aafdc83e82786acc25c496813c61f4e863d36f91))

## [1.29.2](https://github.com/dryvist/nix-home/compare/v1.29.1...v1.29.2) (2026-07-02)


### Bug Fixes

* **deps:** refresh gh-aw action SHA pins [aw:gh-aw-pin-refresh] ([#333](https://github.com/dryvist/nix-home/issues/333)) ([7546282](https://github.com/dryvist/nix-home/commit/7546282bd581d71f14c5745e9c0386933f435f27))

## [1.29.1](https://github.com/dryvist/nix-home/compare/v1.29.0...v1.29.1) (2026-07-02)


### Bug Fixes

* point callers at renamed cc- reusable workflows ([cdb60df](https://github.com/dryvist/nix-home/commit/cdb60df6c8c7185eb355b9275d6f48561010a3cf))

## [1.29.0](https://github.com/dryvist/nix-home/compare/v1.28.4...v1.29.0) (2026-07-01)


### Features

* **profiles:** workstation/server host profiles for two-machine setup ([#325](https://github.com/dryvist/nix-home/issues/325)) ([ce50efa](https://github.com/dryvist/nix-home/commit/ce50efa093b72139f5927c530a4cf5444f85f495))

## [1.28.4](https://github.com/dryvist/nix-home/compare/v1.28.3...v1.28.4) (2026-07-01)


### Bug Fixes

* **ci:** pin GitHub Actions to commit SHAs (resolve CodeQL actions/unpinned-tag) ([#326](https://github.com/dryvist/nix-home/issues/326)) ([293d4d8](https://github.com/dryvist/nix-home/commit/293d4d805c228f3b2f931eeda8c8cbdbd7644668))

## [1.28.3](https://github.com/dryvist/nix-home/compare/v1.28.2...v1.28.3) (2026-06-29)


### Bug Fixes

* **deps:** refresh gh-aw action SHA pins [aw:gh-aw-pin-refresh] ([#310](https://github.com/dryvist/nix-home/issues/310)) ([2bc5b5f](https://github.com/dryvist/nix-home/commit/2bc5b5fcd1ad8d504bb7de03c6756cf97e9f97b1))

## [1.28.2](https://github.com/dryvist/nix-home/compare/v1.28.1...v1.28.2) (2026-06-25)


### Bug Fixes

* **deps:** refresh gh-aw action SHA pins [aw:gh-aw-pin-refresh] ([#307](https://github.com/dryvist/nix-home/issues/307)) ([b035809](https://github.com/dryvist/nix-home/commit/b0358099c435324574a123f0f662678f3d73238f))

## [1.28.1](https://github.com/dryvist/nix-home/compare/v1.28.0...v1.28.1) (2026-06-22)


### Bug Fixes

* **deps:** refresh gh-aw action SHA pins [aw:gh-aw-pin-refresh] ([#305](https://github.com/dryvist/nix-home/issues/305)) ([b801e1a](https://github.com/dryvist/nix-home/commit/b801e1a119db8a570c2dca4568abcff2ee1280a5))

## [1.28.0](https://github.com/dryvist/nix-home/compare/v1.27.1...v1.28.0) (2026-06-19)


### Features

* **python:** include PyYAML in shared environment ([#300](https://github.com/dryvist/nix-home/issues/300)) ([9fbee5e](https://github.com/dryvist/nix-home/commit/9fbee5edd15300ba769438371177d1e53042aa8d))

## [1.27.1](https://github.com/dryvist/nix-home/compare/v1.27.0...v1.27.1) (2026-06-12)


### Bug Fixes

* **ci:** repoint shared reusable workflows to dryvist org ([#298](https://github.com/dryvist/nix-home/issues/298)) ([db86ea4](https://github.com/dryvist/nix-home/commit/db86ea46d041eb708f4eac45fb758d04e1c7439b))

## [1.27.0](https://github.com/dryvist/nix-home/compare/v1.26.3...v1.27.0) (2026-06-07)


### Features

* add awscli2 to nix-home packages ([#294](https://github.com/dryvist/nix-home/issues/294)) ([ca30348](https://github.com/dryvist/nix-home/commit/ca3034806fea5aa5c8550437e54baf114841fdf6))

## [1.26.3](https://github.com/dryvist/nix-home/compare/v1.26.2...v1.26.3) (2026-06-05)


### Bug Fixes

* **zsh:** use 4h unit in aws-vault duration aliases ([#291](https://github.com/dryvist/nix-home/issues/291)) ([8f81223](https://github.com/dryvist/nix-home/commit/8f812232ef2bfbb2c06a610e0e538a75e748ab0a))

## [1.26.2](https://github.com/dryvist/nix-home/compare/v1.26.1...v1.26.2) (2026-06-04)


### Bug Fixes

* **git:** drop global core.hooksPath; rely on init.templateDir + per-repo install ([9ae3a57](https://github.com/dryvist/nix-home/commit/9ae3a5718975480dad3a00dcd6df0990a1858d86))

## [1.26.1](https://github.com/dryvist/nix-home/compare/v1.26.0...v1.26.1) (2026-06-04)


### Bug Fixes

* **aws:** set --duration=14400 on av and avd aliases ([#286](https://github.com/dryvist/nix-home/issues/286)) ([3e5f5bc](https://github.com/dryvist/nix-home/commit/3e5f5bcfeb27832a3f678ff494040dbc5e9a8cc1))

## [1.26.0](https://github.com/dryvist/nix-home/compare/v1.25.0...v1.26.0) (2026-06-04)


### Features

* **ci:** dispatch flake-input update to nix-darwin on release ([#284](https://github.com/dryvist/nix-home/issues/284)) ([e62977e](https://github.com/dryvist/nix-home/commit/e62977e9b3018cf320f733df7fb704cdd386a255))

## [1.25.0](https://github.com/dryvist/nix-home/compare/v1.24.0...v1.25.0) (2026-06-03)


### Features

* **aws:** generate tf-* profiles from a names list; add tf-unifi ([#279](https://github.com/dryvist/nix-home/issues/279)) ([1afb777](https://github.com/dryvist/nix-home/commit/1afb7777b433911f4aede750d2183b10b24c34b5))
* **aws:** tofu + tofu-admin identities; group tf-* by base ([#282](https://github.com/dryvist/nix-home/issues/282)) ([225b28d](https://github.com/dryvist/nix-home/commit/225b28dbfcaa6c7888a9524cbf2975dd8aa70250))

## [1.24.0](https://github.com/dryvist/nix-home/compare/v1.23.1...v1.24.0) (2026-06-01)


### Features

* **home:** add GIT_HOME_PRIVATE sessionVariable ([#268](https://github.com/dryvist/nix-home/issues/268)) ([b6f3cd2](https://github.com/dryvist/nix-home/commit/b6f3cd2f872c4abf801deefadacbd7ccbb273108))


### Bug Fixes

* **ci:** repoint release-please caller to org-native reusable workflow ([#274](https://github.com/dryvist/nix-home/issues/274)) ([56d9791](https://github.com/dryvist/nix-home/commit/56d9791c5c7d6dfb761ad1b00f63d95fba981237))
* **ci:** retarget reusable-workflow uses: refs to current org homes ([#270](https://github.com/dryvist/nix-home/issues/270)) ([fc124db](https://github.com/dryvist/nix-home/commit/fc124db8b4296bc16b72058ccd74997f2436d644))
* **identity:** update standalone fallback git email to renamed account ([#271](https://github.com/dryvist/nix-home/issues/271)) ([36bdd10](https://github.com/dryvist/nix-home/commit/36bdd10672708728cfcac1a6a82ea8704375302c))

## [1.23.1](https://github.com/JacobPEvans/nix-home/compare/v1.23.0...v1.23.1) (2026-05-25)


### Bug Fixes

* **deps:** refresh gh-aw action SHA pins [aw:gh-aw-pin-refresh] ([#263](https://github.com/JacobPEvans/nix-home/issues/263)) ([c110c88](https://github.com/JacobPEvans/nix-home/commit/c110c88c5eaec7ecf2c2f3fc4ff6bff71f5349b3))

## [1.23.0](https://github.com/JacobPEvans/nix-home/compare/v1.22.9...v1.23.0) (2026-05-25)


### Features

* add GIT_HOME and GIT_HOME_PUBLIC sessionVariables ([#261](https://github.com/JacobPEvans/nix-home/issues/261)) ([b716868](https://github.com/JacobPEvans/nix-home/commit/b71686844d599eb050d3cf3a1152261e9ab9fe97))

## [1.22.9](https://github.com/JacobPEvans/nix-home/compare/v1.22.8...v1.22.9) (2026-05-21)


### Bug Fixes

* **deps:** refresh gh-aw action SHA pins ([#254](https://github.com/JacobPEvans/nix-home/issues/254)) ([5066648](https://github.com/JacobPEvans/nix-home/commit/5066648fc06c259d42a956df4b28df2b95e22d31))

## [1.22.8](https://github.com/JacobPEvans/nix-home/compare/v1.22.7...v1.22.8) (2026-05-18)


### Bug Fixes

* **deps:** refresh gh-aw action SHA pins ([#249](https://github.com/JacobPEvans/nix-home/issues/249)) ([0da382a](https://github.com/JacobPEvans/nix-home/commit/0da382a701cdbf7dba4e7185fa665c26d5b11d91))

## [1.22.7](https://github.com/JacobPEvans/nix-home/compare/v1.22.6...v1.22.7) (2026-05-15)


### Bug Fixes

* **python:** skip speechrecognition tests on darwin ([#245](https://github.com/JacobPEvans/nix-home/issues/245)) ([730c3bf](https://github.com/JacobPEvans/nix-home/commit/730c3bf6c92107d8b27246a5fbacf62c418e18a7))

## [1.22.6](https://github.com/JacobPEvans/nix-home/compare/v1.22.5...v1.22.6) (2026-05-14)


### Bug Fixes

* **flake:** scope checks to x86_64-linux for --all-systems compatibility ([#241](https://github.com/JacobPEvans/nix-home/issues/241)) ([d85361e](https://github.com/JacobPEvans/nix-home/commit/d85361ea12f0ffed1893e9b942ee036eaa6d8d25))

## [1.22.5](https://github.com/JacobPEvans/nix-home/compare/v1.22.4...v1.22.5) (2026-05-14)


### Bug Fixes

* **deps:** refresh gh-aw action SHA pins ([#238](https://github.com/JacobPEvans/nix-home/issues/238)) ([03ced98](https://github.com/JacobPEvans/nix-home/commit/03ced981efb6def99c148675e4f1e0bb6ccf60d5))

## [1.22.4](https://github.com/JacobPEvans/nix-home/compare/v1.22.3...v1.22.4) (2026-05-11)


### Bug Fixes

* **checks:** allow broken in test-only pkgsWithUnfree for arrow-cpp on darwin ([#234](https://github.com/JacobPEvans/nix-home/issues/234)) ([c77ff5d](https://github.com/JacobPEvans/nix-home/commit/c77ff5daba0d963fc1f0ca0c2f70f7c874f9e69e))

## [1.22.3](https://github.com/JacobPEvans/nix-home/compare/v1.22.2...v1.22.3) (2026-05-11)


### Bug Fixes

* **deps:** refresh gh-aw action SHA pins ([#232](https://github.com/JacobPEvans/nix-home/issues/232)) ([cd4830b](https://github.com/JacobPEvans/nix-home/commit/cd4830b6ced7f7fd41a998ea482b01e12c0263f1))

## [1.22.2](https://github.com/JacobPEvans/nix-home/compare/v1.22.1...v1.22.2) (2026-05-11)


### Bug Fixes

* **deps:** bump nixpkgs past broken postgresql-test-hook rev ([#229](https://github.com/JacobPEvans/nix-home/issues/229)) ([8e639c0](https://github.com/JacobPEvans/nix-home/commit/8e639c004c0d0d561178e2dcd6ecc03581fe6ddb))

## [1.22.1](https://github.com/JacobPEvans/nix-home/compare/v1.22.0...v1.22.1) (2026-05-07)


### Bug Fixes

* **deps:** refresh gh-aw action SHA pins ([#226](https://github.com/JacobPEvans/nix-home/issues/226)) ([8241af5](https://github.com/JacobPEvans/nix-home/commit/8241af53a3f63193e8692cb040b482e1020d134f))

## [1.22.0](https://github.com/JacobPEvans/nix-home/compare/v1.21.12...v1.22.0) (2026-05-06)


### Features

* **gpg-agent:** unattended signing config for AI sessions ([#223](https://github.com/JacobPEvans/nix-home/issues/223)) ([311f46b](https://github.com/JacobPEvans/nix-home/commit/311f46b38fc6645596d1b507ff91ff8acbc5abd7))

## [1.21.12](https://github.com/JacobPEvans/nix-home/compare/v1.21.11...v1.21.12) (2026-05-05)


### Bug Fixes

* **renovate:** annotate docx and pptxgenjs version pins for tracking ([#221](https://github.com/JacobPEvans/nix-home/issues/221)) ([818130b](https://github.com/JacobPEvans/nix-home/commit/818130b1478fc2e7d7d9b6a3b091452573ba0634))

## [1.21.11](https://github.com/JacobPEvans/nix-home/compare/v1.21.10...v1.21.11) (2026-05-04)


### Bug Fixes

* **deps:** refresh gh-aw action SHA pins ([#219](https://github.com/JacobPEvans/nix-home/issues/219)) ([f66e219](https://github.com/JacobPEvans/nix-home/commit/f66e21918bfc28f2f1b5f5f1866b10e423ed93e0))

## [1.21.10](https://github.com/JacobPEvans/nix-home/compare/v1.21.9...v1.21.10) (2026-05-03)


### Bug Fixes

* **ci:** remove deprecated app-id secret passthrough ([806e7bc](https://github.com/JacobPEvans/nix-home/commit/806e7bc3387d5de51696f288158110ca956bae0b))

## [1.21.9](https://github.com/JacobPEvans/nix-home/compare/v1.21.8...v1.21.9) (2026-05-03)


### Bug Fixes

* **overlays:** skip flaky aarch64-darwin tests for markitdown audio chain ([#214](https://github.com/JacobPEvans/nix-home/issues/214)) ([f482721](https://github.com/JacobPEvans/nix-home/commit/f482721b38f47449485321223824b7409b53e1a2))

## [1.21.8](https://github.com/JacobPEvans/nix-home/compare/v1.21.7...v1.21.8) (2026-05-03)


### Bug Fixes

* **deps:** refresh gh-aw action SHA pins ([#212](https://github.com/JacobPEvans/nix-home/issues/212)) ([2e10a52](https://github.com/JacobPEvans/nix-home/commit/2e10a5253a71063c2485caa21bf5e80233f79e94))

## [1.21.7](https://github.com/JacobPEvans/nix-home/compare/v1.21.6...v1.21.7) (2026-04-29)


### Bug Fixes

* **ci:** drop RunsOn from nix-validate gate path ([#209](https://github.com/JacobPEvans/nix-home/issues/209)) ([ede4e18](https://github.com/JacobPEvans/nix-home/commit/ede4e18b1b339307d1b849f0509349fb0a808fa7))

## [1.21.6](https://github.com/JacobPEvans/nix-home/compare/v1.21.5...v1.21.6) (2026-04-29)


### Bug Fixes

* **deps:** refresh gh-aw action SHA pins ([#206](https://github.com/JacobPEvans/nix-home/issues/206)) ([c986d7d](https://github.com/JacobPEvans/nix-home/commit/c986d7ded01b5c1e2f80a26c1a8880497e8a8ce6))

## [1.21.5](https://github.com/JacobPEvans/nix-home/compare/v1.21.4...v1.21.5) (2026-04-26)


### Bug Fixes

* **ci:** standardize deps-update-flake naming + renovate v5 ([#201](https://github.com/JacobPEvans/nix-home/issues/201)) ([12609c0](https://github.com/JacobPEvans/nix-home/commit/12609c0ec605ba69d557f0910f4629b099aade1a))
* **deps:** refresh gh-aw action SHA pins ([249734a](https://github.com/JacobPEvans/nix-home/commit/249734a92a38174db7313ce7ac0b82d9c2e2288d))

## [1.21.4](https://github.com/JacobPEvans/nix-home/compare/v1.21.3...v1.21.4) (2026-04-24)


### Bug Fixes

* **ci:** add gh-aw-pin-refresh workflow and recompile lock files ([39c26e1](https://github.com/JacobPEvans/nix-home/commit/39c26e1362fe0b5578f73f3fc1186a8176e5e69f)), closes [#190](https://github.com/JacobPEvans/nix-home/issues/190)
* **deps:** refresh gh-aw action SHA pins ([219fc47](https://github.com/JacobPEvans/nix-home/commit/219fc47c03643d51250bdbcbf4bf139f48fbb27f))
* **deps:** refresh gh-aw action SHA pins ([#198](https://github.com/JacobPEvans/nix-home/issues/198)) ([9aef301](https://github.com/JacobPEvans/nix-home/commit/9aef301910df218ede8de3a38ac6a3c852476832))

## [1.21.2](https://github.com/JacobPEvans/nix-home/compare/v1.21.1...v1.21.2) (2026-04-15)


### Bug Fixes

* add automation bots to AI Moderator skip-bots ([#170](https://github.com/JacobPEvans/nix-home/issues/170)) ([aea22e8](https://github.com/JacobPEvans/nix-home/commit/aea22e8e9ef462d02c9b443d67b35defab63f5cb))

## [1.21.1](https://github.com/JacobPEvans/nix-home/compare/v1.21.0...v1.21.1) (2026-04-13)


### Bug Fixes

* **gh-aw:** recompile workflows with v0.68.1 ([cfa817f](https://github.com/JacobPEvans/nix-home/commit/cfa817f16ef470039b67919cf90d319a95dad1f0))

## [1.21.0](https://github.com/JacobPEvans/nix-home/compare/v1.20.1...v1.21.0) (2026-04-12)


### Features

* add AI merge gate ([#132](https://github.com/JacobPEvans/nix-home/issues/132)) ([dea9a7f](https://github.com/JacobPEvans/nix-home/commit/dea9a7f996a5746c19d55904b0de48745d0d662f))
* add automated flake.lock update workflow ([#47](https://github.com/JacobPEvans/nix-home/issues/47)) ([7c7229c](https://github.com/JacobPEvans/nix-home/commit/7c7229ce50b5b733899aa2b86f7f135e74282576))
* add aws-vault to common packages ([#140](https://github.com/JacobPEvans/nix-home/issues/140)) ([0038120](https://github.com/JacobPEvans/nix-home/commit/003812098a59d2ba847bce80cd4cb6bb3cab4bfb))
* add CI infrastructure ([#1](https://github.com/JacobPEvans/nix-home/issues/1)) ([1b464b4](https://github.com/JacobPEvans/nix-home/commit/1b464b4e74f04acf74996aac1eb674031a8816b4))
* add daily repo health audit agentic workflow ([#55](https://github.com/JacobPEvans/nix-home/issues/55)) ([1bf8cae](https://github.com/JacobPEvans/nix-home/commit/1bf8cae8f76103e58238b784c54954e8060d5a06))
* add dependencies for Claude document-skills ([#142](https://github.com/JacobPEvans/nix-home/issues/142)) ([ee19586](https://github.com/JacobPEvans/nix-home/commit/ee19586cba3899e058100dd1f70aade9f3ef71bf))
* add dev shell eval smoke tests and remove redundant markdownlint config ([#22](https://github.com/JacobPEvans/nix-home/issues/22)) ([ff1884a](https://github.com/JacobPEvans/nix-home/commit/ff1884aadb58610402b58358d3b9381bbc4e9984))
* add GitHub Agentic Workflows ([#29](https://github.com/JacobPEvans/nix-home/issues/29)) ([263ce9c](https://github.com/JacobPEvans/nix-home/commit/263ce9c10758c8d821daa793fcb3f16277e4d2e3))
* add Google Workspace CLI tools (gmailctl, rclone, gdrive3) ([#103](https://github.com/JacobPEvans/nix-home/issues/103)) ([8cb77ec](https://github.com/JacobPEvans/nix-home/commit/8cb77eca40830850397644bf99cabe265e912a34))
* add minio-client (mc) to common packages ([#136](https://github.com/JacobPEvans/nix-home/issues/136)) ([b5fd725](https://github.com/JacobPEvans/nix-home/commit/b5fd7250b301164ae3d3edc20b6f5abffba55a5e))
* add MIT license, workflows, renovate, and trigger-nix-update ([700b95c](https://github.com/JacobPEvans/nix-home/commit/700b95cf7c656f2d7b7f927308fa4966f2afb883))
* add scheduled AI workflow callers ([#36](https://github.com/JacobPEvans/nix-home/issues/36)) ([9ea7e66](https://github.com/JacobPEvans/nix-home/commit/9ea7e667134ffd90379058b9d3df99b0f56d01c9))
* **aliases:** add tf-claude combo launcher (aws-vault + doppler) ([#144](https://github.com/JacobPEvans/nix-home/issues/144)) ([432cba4](https://github.com/JacobPEvans/nix-home/commit/432cba4e47bbf24d434cb9e230aa98ef5ba3bf8c))
* **aws:** add per-project assume-role profiles for Terraform ([#87](https://github.com/JacobPEvans/nix-home/issues/87)) ([5013ccf](https://github.com/JacobPEvans/nix-home/commit/5013ccf1ee734d4c90e50a390f9a4b5fba450d20))
* consolidate package updates into single workflow job ([#46](https://github.com/JacobPEvans/nix-home/issues/46)) ([7eb38c1](https://github.com/JacobPEvans/nix-home/commit/7eb38c1a63313ffa86aafa416de17f0d6e635e29))
* disable automatic triggers on Claude-executing workflows ([df000b1](https://github.com/JacobPEvans/nix-home/commit/df000b1a0a90aa71716a5fa17b93c6cf9a166c56))
* initial nix-home repository ([9088cfe](https://github.com/JacobPEvans/nix-home/commit/9088cfe724e675cde2f82d8d5cdf1f16d0f25e5b))
* make python3 resolve to Python 3.14 via overlay ([#68](https://github.com/JacobPEvans/nix-home/issues/68)) ([47c8e9a](https://github.com/JacobPEvans/nix-home/commit/47c8e9afdb9f613c110c86b72f40798b25056128))
* migrate flake.lock updates to Renovate nix manager ([#73](https://github.com/JacobPEvans/nix-home/issues/73)) ([1e0430f](https://github.com/JacobPEvans/nix-home/commit/1e0430f6aed962908419ac6b76d913accca2cbe9))
* **packages:** add D2 and mermaid-cli diagram tools ([#123](https://github.com/JacobPEvans/nix-home/issues/123)) ([2ce1a69](https://github.com/JacobPEvans/nix-home/commit/2ce1a6924c38861b801fd0cb12b2cc480c5c46f0))
* **packages:** add zellij terminal multiplexer ([#113](https://github.com/JacobPEvans/nix-home/issues/113)) ([a6a8259](https://github.com/JacobPEvans/nix-home/commit/a6a82594a97cecabdf691dfeb4c97402c5ea5e13))
* **packages:** audit package placement — remove project-scoped tools from global env ([#146](https://github.com/JacobPEvans/nix-home/issues/146)) ([e90c4b0](https://github.com/JacobPEvans/nix-home/commit/e90c4b02f79593335cae48e5f0108b1cd600bb81))
* Python 3.14 overlay, HF_HOME volume, and MLX aliases ([#57](https://github.com/JacobPEvans/nix-home/issues/57)) ([0548954](https://github.com/JacobPEvans/nix-home/commit/0548954ceb48420e6b4c7081afc47dc74024aee0))
* replace background processes with native source configs ([#66](https://github.com/JacobPEvans/nix-home/issues/66)) ([af489d1](https://github.com/JacobPEvans/nix-home/commit/af489d11e5e61973e1b1933cfb479da30bb59129))
* replace shells/ with per-repo templates, trim global packages ([#25](https://github.com/JacobPEvans/nix-home/issues/25)) ([10b3ae6](https://github.com/JacobPEvans/nix-home/commit/10b3ae673082101affc3f6e7baae61e03c379d01))


### Bug Fixes

* add concurrency groups to prevent duplicate PR creation ([#37](https://github.com/JacobPEvans/nix-home/issues/37)) ([f3989fa](https://github.com/JacobPEvans/nix-home/commit/f3989faf77c581fb23d9793e177b7d70c9b341c3))
* add concurrency guard to release-please caller workflow ([5d2568c](https://github.com/JacobPEvans/nix-home/commit/5d2568ca15b0e7f9d36b14e21cb18ee06b72108d))
* add missing pygments and tabulate deps to grip package ([#58](https://github.com/JacobPEvans/nix-home/issues/58)) ([9301351](https://github.com/JacobPEvans/nix-home/commit/9301351a4898ffc043052ad8bf8e412435f6e8ca))
* add release-please config for manifest mode ([b7e16ed](https://github.com/JacobPEvans/nix-home/commit/b7e16ed71472a808f4fe12602eff2821c87fae9c))
* add tf-runs-on aws-vault profile for RunsOn infrastructure ([#108](https://github.com/JacobPEvans/nix-home/issues/108)) ([7156895](https://github.com/JacobPEvans/nix-home/commit/715689594c3ef5d8ef93109ed6747f7c678e1a20))
* **aws:** move config generation from activation to shell init ([1eeb6a3](https://github.com/JacobPEvans/nix-home/commit/1eeb6a3cfc810bcb31141e727150807865ce8e52))
* **aws:** use keychain activation hook for account ID ([#95](https://github.com/JacobPEvans/nix-home/issues/95)) ([cdad962](https://github.com/JacobPEvans/nix-home/commit/cdad962f91c4c086346feaf6c539987ea5f48f02))
* bump ci-fail-issue workflow to v0.6.1 ([#26](https://github.com/JacobPEvans/nix-home/issues/26)) ([3e1df2f](https://github.com/JacobPEvans/nix-home/commit/3e1df2f78b61dbd50aeb4a13debb9d7649f3c6ad))
* **checks:** avoid building activation pkg in module-eval check ([467e211](https://github.com/JacobPEvans/nix-home/commit/467e211ec7151bbea6e4ec491876a80e2cf4483d))
* **ci:** add pull-requests:write for release-please auto-approve ([#79](https://github.com/JacobPEvans/nix-home/issues/79)) ([f08dd3d](https://github.com/JacobPEvans/nix-home/commit/f08dd3dad84d4458a1742f19fdb3bbe11bfabd21))
* **ci:** migrate copilot-setup-steps to determinate-nix-action@v3 ([#75](https://github.com/JacobPEvans/nix-home/issues/75)) ([18696ca](https://github.com/JacobPEvans/nix-home/commit/18696cae0e05d736ee82514b488602a6f7bfb2df))
* **ci:** resolve system deprecation and grip build warnings ([#85](https://github.com/JacobPEvans/nix-home/issues/85)) ([3bd66e3](https://github.com/JacobPEvans/nix-home/commit/3bd66e35fb5c4224bcd1c3a38fb108f2c290d306))
* **ci:** upgrade ci-gate.yml to Merge Gatekeeper pattern ([#70](https://github.com/JacobPEvans/nix-home/issues/70)) ([4360274](https://github.com/JacobPEvans/nix-home/commit/4360274ffe986d82a74afeebc75a75abff0f8697))
* **ci:** use GitHub App token for release-please to trigger CI Gate ([#61](https://github.com/JacobPEvans/nix-home/issues/61)) ([411a3bd](https://github.com/JacobPEvans/nix-home/commit/411a3bdb61fd7e6ad7d3795d4628d92e3cbe2105))
* complete changelog-sections for full Conventional Commits coverage ([effaccc](https://github.com/JacobPEvans/nix-home/commit/effacccbe8a1813fb523954443d4c0385c90d8b5))
* correct best-practices permissions and add ref-scoped concurrency ([#38](https://github.com/JacobPEvans/nix-home/issues/38)) ([f2493b1](https://github.com/JacobPEvans/nix-home/commit/f2493b1c754952ce4ca5b9bb539f5c9b47a7e50b))
* correct misleading auto-merge comment in deps-update-flake.yml ([#49](https://github.com/JacobPEvans/nix-home/issues/49)) ([e893bfc](https://github.com/JacobPEvans/nix-home/commit/e893bfc00b47f34161c6a409432f460f9a04456c))
* **deps:** add Renovate annotations for custom Nix packages ([#110](https://github.com/JacobPEvans/nix-home/issues/110)) ([73c7d15](https://github.com/JacobPEvans/nix-home/commit/73c7d15f188125b07b4ad2c80cac5c9631978e53))
* **deps:** switch git-flow-next to daily nix-update ([#124](https://github.com/JacobPEvans/nix-home/issues/124)) ([75a5524](https://github.com/JacobPEvans/nix-home/commit/75a5524f7d29b03856e0db2bac4a8c0b4214c847))
* **deps:** update all flake inputs ([#118](https://github.com/JacobPEvans/nix-home/issues/118)) ([7c9041b](https://github.com/JacobPEvans/nix-home/commit/7c9041b0161892c3266e052ab48c437dc1bb3b6c))
* disable hash pinning for trusted actions, use version tags ([#40](https://github.com/JacobPEvans/nix-home/issues/40)) ([9f869c3](https://github.com/JacobPEvans/nix-home/commit/9f869c32338234f86055f739051831b73cafe5cc))
* **docs:** drop "quartet" and "all four repos" language ([#148](https://github.com/JacobPEvans/nix-home/issues/148)) ([a7d9a1a](https://github.com/JacobPEvans/nix-home/commit/a7d9a1aa0bdb625a93d00dceafe681a5706897b1))
* expose merge-json-settings as writeShellApplication ([#100](https://github.com/JacobPEvans/nix-home/issues/100)) ([b3908fb](https://github.com/JacobPEvans/nix-home/commit/b3908fb040dc0b8026c67759319a2c42054c5260))
* **grip:** list Python dependencies explicitly to avoid self-referential overlay cycle ([#53](https://github.com/JacobPEvans/nix-home/issues/53)) ([a412e42](https://github.com/JacobPEvans/nix-home/commit/a412e42f22565001488402fafc942f9ac8ba0c3c))
* move minio-client to dedicated Object Storage section ([#138](https://github.com/JacobPEvans/nix-home/issues/138)) ([8d3e9fd](https://github.com/JacobPEvans/nix-home/commit/8d3e9fd3f750b100e96e069c361fe87fdca79adc))
* move security-policies to nix-home, clarify git tooling docs ([#105](https://github.com/JacobPEvans/nix-home/issues/105)) ([ceed895](https://github.com/JacobPEvans/nix-home/commit/ceed895fbd3015caeb1b0c7bab18cb95c54da7ac))
* **overlay:** resolve python3 infinite recursion on Darwin ([#81](https://github.com/JacobPEvans/nix-home/issues/81)) ([6085101](https://github.com/JacobPEvans/nix-home/commit/60851010df5f57b1317b1aa21bbcc7e9d2bfcd4f))
* **overlay:** source python314 from nixpkgs-unstable for 3.14 compat ([#83](https://github.com/JacobPEvans/nix-home/issues/83)) ([701750b](https://github.com/JacobPEvans/nix-home/commit/701750bef0cd286765e1ba7c47b1ff69c2788b64))
* pass python-prev to grip overlay to break infinite recursion ([#52](https://github.com/JacobPEvans/nix-home/issues/52)) ([80bb1fa](https://github.com/JacobPEvans/nix-home/commit/80bb1fa0c9b8c0dee96a4feaaa505905dcd66837))
* remove blanket auto-merge workflow ([#39](https://github.com/JacobPEvans/nix-home/issues/39)) ([9ddc2fc](https://github.com/JacobPEvans/nix-home/commit/9ddc2fc763210c55a754c88ddca47e54bbf5fed8))
* remove claude-review workflow — replaced by Gemini + Copilot ([#126](https://github.com/JacobPEvans/nix-home/issues/126)) ([10eaedd](https://github.com/JacobPEvans/nix-home/commit/10eaedda1ab6decade0cfe7f714b3ebbe8ef6a91))
* remove cloud CLIs from global packages ([#98](https://github.com/JacobPEvans/nix-home/issues/98)) ([f5b8e41](https://github.com/JacobPEvans/nix-home/commit/f5b8e41b4a26b8cdc9dc2fa51af3f44bb9477689))
* remove Ollama from packages, VS Code settings, and shell aliases ([#96](https://github.com/JacobPEvans/nix-home/issues/96)) ([30a560c](https://github.com/JacobPEvans/nix-home/commit/30a560cb8f480716a5a25f0a4ca4fd7d6b3aa227))
* remove soft-fail patterns from deps-update-packages workflow ([#51](https://github.com/JacobPEvans/nix-home/issues/51)) ([a609a72](https://github.com/JacobPEvans/nix-home/commit/a609a723e61dc2d5446926e424279b362d8b3892))
* rename GH_APP_ID secret to GH_ACTION_JACOBPEVANS_APP_ID ([#48](https://github.com/JacobPEvans/nix-home/issues/48)) ([b74734e](https://github.com/JacobPEvans/nix-home/commit/b74734e3b99e6f90bafcfab4a4549feb0b0668ab))
* replace renovate annotation with nix-update convention in grip ([#130](https://github.com/JacobPEvans/nix-home/issues/130)) ([95d5ab3](https://github.com/JacobPEvans/nix-home/commit/95d5ab3e4826d9b76ea205edc07bc9d360017332))
* resolve module-eval check failures in CI ([#21](https://github.com/JacobPEvans/nix-home/issues/21)) ([a46513b](https://github.com/JacobPEvans/nix-home/commit/a46513beef81b8ee01ca7b9cf3bd220faf8e9a7a))
* sync release-please permissions and VERSION ([d6fccab](https://github.com/JacobPEvans/nix-home/commit/d6fccab566ac2d8b3a978d75e65ab5a47928f668))
* write aws config from activation script instead of home.file ([a66763e](https://github.com/JacobPEvans/nix-home/commit/a66763ee2e918da3a4c9b2c01152814c1d465f21))

## [1.20.1](https://github.com/JacobPEvans/nix-home/compare/v1.20.0...v1.20.1) (2026-04-12)


### Bug Fixes

* **checks:** avoid building activation pkg in module-eval check ([467e211](https://github.com/JacobPEvans/nix-home/commit/467e211ec7151bbea6e4ec491876a80e2cf4483d))

## [1.19.0](https://github.com/JacobPEvans/nix-home/compare/v1.18.0...v1.19.0) (2026-04-11)


### Features

* **packages:** audit package placement — remove project-scoped tools from global env ([#146](https://github.com/JacobPEvans/nix-home/issues/146)) ([e90c4b0](https://github.com/JacobPEvans/nix-home/commit/e90c4b02f79593335cae48e5f0108b1cd600bb81))


### Bug Fixes

* **docs:** drop "quartet" and "all four repos" language ([#148](https://github.com/JacobPEvans/nix-home/issues/148)) ([a7d9a1a](https://github.com/JacobPEvans/nix-home/commit/a7d9a1aa0bdb625a93d00dceafe681a5706897b1))

## [1.18.0](https://github.com/JacobPEvans/nix-home/compare/v1.17.0...v1.18.0) (2026-04-11)


### Features

* **aliases:** add tf-claude combo launcher (aws-vault + doppler) ([#144](https://github.com/JacobPEvans/nix-home/issues/144)) ([432cba4](https://github.com/JacobPEvans/nix-home/commit/432cba4e47bbf24d434cb9e230aa98ef5ba3bf8c))

## [1.17.0](https://github.com/JacobPEvans/nix-home/compare/v1.16.0...v1.17.0) (2026-04-10)


### Features

* add dependencies for Claude document-skills ([#142](https://github.com/JacobPEvans/nix-home/issues/142)) ([ee19586](https://github.com/JacobPEvans/nix-home/commit/ee19586cba3899e058100dd1f70aade9f3ef71bf))

## [1.16.0](https://github.com/JacobPEvans/nix-home/compare/v1.15.1...v1.16.0) (2026-04-10)


### Features

* add aws-vault to common packages ([#140](https://github.com/JacobPEvans/nix-home/issues/140)) ([0038120](https://github.com/JacobPEvans/nix-home/commit/003812098a59d2ba847bce80cd4cb6bb3cab4bfb))

## [1.15.1](https://github.com/JacobPEvans/nix-home/compare/v1.15.0...v1.15.1) (2026-04-10)


### Bug Fixes

* move minio-client to dedicated Object Storage section ([#138](https://github.com/JacobPEvans/nix-home/issues/138)) ([8d3e9fd](https://github.com/JacobPEvans/nix-home/commit/8d3e9fd3f750b100e96e069c361fe87fdca79adc))

## [1.15.0](https://github.com/JacobPEvans/nix-home/compare/v1.14.0...v1.15.0) (2026-04-10)


### Features

* add minio-client (mc) to common packages ([#136](https://github.com/JacobPEvans/nix-home/issues/136)) ([b5fd725](https://github.com/JacobPEvans/nix-home/commit/b5fd7250b301164ae3d3edc20b6f5abffba55a5e))

## [1.14.0](https://github.com/JacobPEvans/nix-home/compare/v1.13.3...v1.14.0) (2026-04-08)


### Features

* add AI merge gate ([#132](https://github.com/JacobPEvans/nix-home/issues/132)) ([dea9a7f](https://github.com/JacobPEvans/nix-home/commit/dea9a7f996a5746c19d55904b0de48745d0d662f))

## [1.13.3](https://github.com/JacobPEvans/nix-home/compare/v1.13.2...v1.13.3) (2026-04-07)


### Bug Fixes

* replace renovate annotation with nix-update convention in grip ([#130](https://github.com/JacobPEvans/nix-home/issues/130)) ([95d5ab3](https://github.com/JacobPEvans/nix-home/commit/95d5ab3e4826d9b76ea205edc07bc9d360017332))

## [1.13.2](https://github.com/JacobPEvans/nix-home/compare/v1.13.1...v1.13.2) (2026-04-04)


### Bug Fixes

* remove claude-review workflow — replaced by Gemini + Copilot ([#126](https://github.com/JacobPEvans/nix-home/issues/126)) ([10eaedd](https://github.com/JacobPEvans/nix-home/commit/10eaedda1ab6decade0cfe7f714b3ebbe8ef6a91))

## [1.13.1](https://github.com/JacobPEvans/nix-home/compare/v1.13.0...v1.13.1) (2026-04-03)


### Bug Fixes

* **deps:** switch git-flow-next to daily nix-update ([#124](https://github.com/JacobPEvans/nix-home/issues/124)) ([75a5524](https://github.com/JacobPEvans/nix-home/commit/75a5524f7d29b03856e0db2bac4a8c0b4214c847))

## [1.13.0](https://github.com/JacobPEvans/nix-home/compare/v1.12.1...v1.13.0) (2026-04-03)


### Features

* **packages:** add D2 and mermaid-cli diagram tools ([#123](https://github.com/JacobPEvans/nix-home/issues/123)) ([2ce1a69](https://github.com/JacobPEvans/nix-home/commit/2ce1a6924c38861b801fd0cb12b2cc480c5c46f0))


### Bug Fixes

* **aws:** move config generation from activation to shell init ([1eeb6a3](https://github.com/JacobPEvans/nix-home/commit/1eeb6a3cfc810bcb31141e727150807865ce8e52))

## [1.12.1](https://github.com/JacobPEvans/nix-home/compare/v1.12.0...v1.12.1) (2026-03-31)


### Bug Fixes

* **deps:** update all flake inputs ([#118](https://github.com/JacobPEvans/nix-home/issues/118)) ([7c9041b](https://github.com/JacobPEvans/nix-home/commit/7c9041b0161892c3266e052ab48c437dc1bb3b6c))

## [1.12.0](https://github.com/JacobPEvans/nix-home/compare/v1.11.1...v1.12.0) (2026-03-30)


### Features

* add Google Workspace CLI tools (gmailctl, rclone, gdrive3) ([#103](https://github.com/JacobPEvans/nix-home/issues/103)) ([8cb77ec](https://github.com/JacobPEvans/nix-home/commit/8cb77eca40830850397644bf99cabe265e912a34))

## [1.11.1](https://github.com/JacobPEvans/nix-home/compare/v1.11.0...v1.11.1) (2026-03-26)


### Bug Fixes

* write aws config from activation script instead of home.file ([a66763e](https://github.com/JacobPEvans/nix-home/commit/a66763ee2e918da3a4c9b2c01152814c1d465f21))

## [1.11.0](https://github.com/JacobPEvans/nix-home/compare/v1.10.8...v1.11.0) (2026-03-26)


### Features

* **packages:** add zellij terminal multiplexer ([#113](https://github.com/JacobPEvans/nix-home/issues/113)) ([a6a8259](https://github.com/JacobPEvans/nix-home/commit/a6a82594a97cecabdf691dfeb4c97402c5ea5e13))

## [1.10.8](https://github.com/JacobPEvans/nix-home/compare/v1.10.7...v1.10.8) (2026-03-24)


### Bug Fixes

* **deps:** add Renovate annotations for custom Nix packages ([#110](https://github.com/JacobPEvans/nix-home/issues/110)) ([73c7d15](https://github.com/JacobPEvans/nix-home/commit/73c7d15f188125b07b4ad2c80cac5c9631978e53))

## [1.10.7](https://github.com/JacobPEvans/nix-home/compare/v1.10.6...v1.10.7) (2026-03-24)


### Bug Fixes

* add tf-runs-on aws-vault profile for RunsOn infrastructure ([#108](https://github.com/JacobPEvans/nix-home/issues/108)) ([7156895](https://github.com/JacobPEvans/nix-home/commit/715689594c3ef5d8ef93109ed6747f7c678e1a20))

## [1.10.6](https://github.com/JacobPEvans/nix-home/compare/v1.10.5...v1.10.6) (2026-03-22)


### Bug Fixes

* move security-policies to nix-home, clarify git tooling docs ([#105](https://github.com/JacobPEvans/nix-home/issues/105)) ([ceed895](https://github.com/JacobPEvans/nix-home/commit/ceed895fbd3015caeb1b0c7bab18cb95c54da7ac))

## [1.10.5](https://github.com/JacobPEvans/nix-home/compare/v1.10.4...v1.10.5) (2026-03-20)


### Bug Fixes

* **aws:** use keychain activation hook for account ID ([#95](https://github.com/JacobPEvans/nix-home/issues/95)) ([cdad962](https://github.com/JacobPEvans/nix-home/commit/cdad962f91c4c086346feaf6c539987ea5f48f02))

## [1.10.4](https://github.com/JacobPEvans/nix-home/compare/v1.10.3...v1.10.4) (2026-03-20)


### Bug Fixes

* expose merge-json-settings as writeShellApplication ([#100](https://github.com/JacobPEvans/nix-home/issues/100)) ([b3908fb](https://github.com/JacobPEvans/nix-home/commit/b3908fb040dc0b8026c67759319a2c42054c5260))

## [1.10.3](https://github.com/JacobPEvans/nix-home/compare/v1.10.2...v1.10.3) (2026-03-20)


### Bug Fixes

* remove cloud CLIs from global packages ([#98](https://github.com/JacobPEvans/nix-home/issues/98)) ([f5b8e41](https://github.com/JacobPEvans/nix-home/commit/f5b8e41b4a26b8cdc9dc2fa51af3f44bb9477689))

## [1.10.2](https://github.com/JacobPEvans/nix-home/compare/v1.10.1...v1.10.2) (2026-03-20)


### Bug Fixes

* remove Ollama from packages, VS Code settings, and shell aliases ([#96](https://github.com/JacobPEvans/nix-home/issues/96)) ([30a560c](https://github.com/JacobPEvans/nix-home/commit/30a560cb8f480716a5a25f0a4ca4fd7d6b3aa227))

## [1.10.1](https://github.com/JacobPEvans/nix-home/compare/v1.10.0...v1.10.1) (2026-03-19)


### Bug Fixes

* add release-please config for manifest mode ([b7e16ed](https://github.com/JacobPEvans/nix-home/commit/b7e16ed71472a808f4fe12602eff2821c87fae9c))
* sync release-please permissions and VERSION ([d6fccab](https://github.com/JacobPEvans/nix-home/commit/d6fccab566ac2d8b3a978d75e65ab5a47928f668))

## [1.10.0](https://github.com/JacobPEvans/nix-home/compare/v1.9.0...v1.10.0) (2026-03-18)


### Features

* **aws:** add per-project assume-role profiles for Terraform ([#87](https://github.com/JacobPEvans/nix-home/issues/87)) ([5013ccf](https://github.com/JacobPEvans/nix-home/commit/5013ccf1ee734d4c90e50a390f9a4b5fba450d20))

## [1.9.0](https://github.com/JacobPEvans/nix-home/compare/v1.8.0...v1.9.0) (2026-03-18)


### Bug Fixes

* **ci:** resolve system deprecation and grip build warnings ([#85](https://github.com/JacobPEvans/nix-home/issues/85)) ([3bd66e3](https://github.com/JacobPEvans/nix-home/commit/3bd66e35fb5c4224bcd1c3a38fb108f2c290d306))

## [1.8.0](https://github.com/JacobPEvans/nix-home/compare/v1.7.0...v1.8.0) (2026-03-18)


### Bug Fixes

* **overlay:** source python314 from nixpkgs-unstable for 3.14 compat ([#83](https://github.com/JacobPEvans/nix-home/issues/83)) ([701750b](https://github.com/JacobPEvans/nix-home/commit/701750bef0cd286765e1ba7c47b1ff69c2788b64))

## [1.7.0](https://github.com/JacobPEvans/nix-home/compare/v1.6.0...v1.7.0) (2026-03-17)


### Bug Fixes

* **overlay:** resolve python3 infinite recursion on Darwin ([#81](https://github.com/JacobPEvans/nix-home/issues/81)) ([6085101](https://github.com/JacobPEvans/nix-home/commit/60851010df5f57b1317b1aa21bbcc7e9d2bfcd4f))

## [1.6.0](https://github.com/JacobPEvans/nix-home/compare/v1.5.0...v1.6.0) (2026-03-15)


### Bug Fixes

* **ci:** add pull-requests:write for release-please auto-approve ([#79](https://github.com/JacobPEvans/nix-home/issues/79)) ([f08dd3d](https://github.com/JacobPEvans/nix-home/commit/f08dd3dad84d4458a1742f19fdb3bbe11bfabd21))

## [1.5.0](https://github.com/JacobPEvans/nix-home/compare/v1.4.0...v1.5.0) (2026-03-15)


### Bug Fixes

* **ci:** migrate copilot-setup-steps to determinate-nix-action@v3 ([#75](https://github.com/JacobPEvans/nix-home/issues/75)) ([18696ca](https://github.com/JacobPEvans/nix-home/commit/18696cae0e05d736ee82514b488602a6f7bfb2df))

## [1.4.0](https://github.com/JacobPEvans/nix-home/compare/v1.3.0...v1.4.0) (2026-03-14)


### Features

* migrate flake.lock updates to Renovate nix manager ([#73](https://github.com/JacobPEvans/nix-home/issues/73)) ([1e0430f](https://github.com/JacobPEvans/nix-home/commit/1e0430f6aed962908419ac6b76d913accca2cbe9))


### Bug Fixes

* **ci:** upgrade ci-gate.yml to Merge Gatekeeper pattern ([#70](https://github.com/JacobPEvans/nix-home/issues/70)) ([4360274](https://github.com/JacobPEvans/nix-home/commit/4360274ffe986d82a74afeebc75a75abff0f8697))

## [1.3.0](https://github.com/JacobPEvans/nix-home/compare/v1.2.0...v1.3.0) (2026-03-14)


### Features

* make python3 resolve to Python 3.14 via overlay ([#68](https://github.com/JacobPEvans/nix-home/issues/68)) ([47c8e9a](https://github.com/JacobPEvans/nix-home/commit/47c8e9afdb9f613c110c86b72f40798b25056128))

## [1.2.0](https://github.com/JacobPEvans/nix-home/compare/v1.1.0...v1.2.0) (2026-03-14)


### Features

* replace background processes with native source configs ([#66](https://github.com/JacobPEvans/nix-home/issues/66)) ([af489d1](https://github.com/JacobPEvans/nix-home/commit/af489d11e5e61973e1b1933cfb479da30bb59129))

## [1.1.0](https://github.com/JacobPEvans/nix-home/compare/v1.0.0...v1.1.0) (2026-03-13)


### Features

* add automated flake.lock update workflow ([#47](https://github.com/JacobPEvans/nix-home/issues/47)) ([7c7229c](https://github.com/JacobPEvans/nix-home/commit/7c7229ce50b5b733899aa2b86f7f135e74282576))
* add daily repo health audit agentic workflow ([#55](https://github.com/JacobPEvans/nix-home/issues/55)) ([1bf8cae](https://github.com/JacobPEvans/nix-home/commit/1bf8cae8f76103e58238b784c54954e8060d5a06))
* add dev shell eval smoke tests and remove redundant markdownlint config ([#22](https://github.com/JacobPEvans/nix-home/issues/22)) ([ff1884a](https://github.com/JacobPEvans/nix-home/commit/ff1884aadb58610402b58358d3b9381bbc4e9984))
* add GitHub Agentic Workflows ([#29](https://github.com/JacobPEvans/nix-home/issues/29)) ([263ce9c](https://github.com/JacobPEvans/nix-home/commit/263ce9c10758c8d821daa793fcb3f16277e4d2e3))
* add scheduled AI workflow callers ([#36](https://github.com/JacobPEvans/nix-home/issues/36)) ([9ea7e66](https://github.com/JacobPEvans/nix-home/commit/9ea7e667134ffd90379058b9d3df99b0f56d01c9))
* consolidate package updates into single workflow job ([#46](https://github.com/JacobPEvans/nix-home/issues/46)) ([7eb38c1](https://github.com/JacobPEvans/nix-home/commit/7eb38c1a63313ffa86aafa416de17f0d6e635e29))
* disable automatic triggers on Claude-executing workflows ([df000b1](https://github.com/JacobPEvans/nix-home/commit/df000b1a0a90aa71716a5fa17b93c6cf9a166c56))
* Python 3.14 overlay, HF_HOME volume, and MLX aliases ([#57](https://github.com/JacobPEvans/nix-home/issues/57)) ([0548954](https://github.com/JacobPEvans/nix-home/commit/0548954ceb48420e6b4c7081afc47dc74024aee0))
* replace shells/ with per-repo templates, trim global packages ([#25](https://github.com/JacobPEvans/nix-home/issues/25)) ([10b3ae6](https://github.com/JacobPEvans/nix-home/commit/10b3ae673082101affc3f6e7baae61e03c379d01))


### Bug Fixes

* add concurrency groups to prevent duplicate PR creation ([#37](https://github.com/JacobPEvans/nix-home/issues/37)) ([f3989fa](https://github.com/JacobPEvans/nix-home/commit/f3989faf77c581fb23d9793e177b7d70c9b341c3))
* add concurrency guard to release-please caller workflow ([5d2568c](https://github.com/JacobPEvans/nix-home/commit/5d2568ca15b0e7f9d36b14e21cb18ee06b72108d))
* add missing pygments and tabulate deps to grip package ([#58](https://github.com/JacobPEvans/nix-home/issues/58)) ([9301351](https://github.com/JacobPEvans/nix-home/commit/9301351a4898ffc043052ad8bf8e412435f6e8ca))
* bump ci-fail-issue workflow to v0.6.1 ([#26](https://github.com/JacobPEvans/nix-home/issues/26)) ([3e1df2f](https://github.com/JacobPEvans/nix-home/commit/3e1df2f78b61dbd50aeb4a13debb9d7649f3c6ad))
* **ci:** use GitHub App token for release-please to trigger CI Gate ([#61](https://github.com/JacobPEvans/nix-home/issues/61)) ([411a3bd](https://github.com/JacobPEvans/nix-home/commit/411a3bdb61fd7e6ad7d3795d4628d92e3cbe2105))
* complete changelog-sections for full Conventional Commits coverage ([effaccc](https://github.com/JacobPEvans/nix-home/commit/effacccbe8a1813fb523954443d4c0385c90d8b5))
* correct best-practices permissions and add ref-scoped concurrency ([#38](https://github.com/JacobPEvans/nix-home/issues/38)) ([f2493b1](https://github.com/JacobPEvans/nix-home/commit/f2493b1c754952ce4ca5b9bb539f5c9b47a7e50b))
* correct misleading auto-merge comment in deps-update-flake.yml ([#49](https://github.com/JacobPEvans/nix-home/issues/49)) ([e893bfc](https://github.com/JacobPEvans/nix-home/commit/e893bfc00b47f34161c6a409432f460f9a04456c))
* disable hash pinning for trusted actions, use version tags ([#40](https://github.com/JacobPEvans/nix-home/issues/40)) ([9f869c3](https://github.com/JacobPEvans/nix-home/commit/9f869c32338234f86055f739051831b73cafe5cc))
* **grip:** list Python dependencies explicitly to avoid self-referential overlay cycle ([#53](https://github.com/JacobPEvans/nix-home/issues/53)) ([a412e42](https://github.com/JacobPEvans/nix-home/commit/a412e42f22565001488402fafc942f9ac8ba0c3c))
* pass python-prev to grip overlay to break infinite recursion ([#52](https://github.com/JacobPEvans/nix-home/issues/52)) ([80bb1fa](https://github.com/JacobPEvans/nix-home/commit/80bb1fa0c9b8c0dee96a4feaaa505905dcd66837))
* remove blanket auto-merge workflow ([#39](https://github.com/JacobPEvans/nix-home/issues/39)) ([9ddc2fc](https://github.com/JacobPEvans/nix-home/commit/9ddc2fc763210c55a754c88ddca47e54bbf5fed8))
* remove soft-fail patterns from deps-update-packages workflow ([#51](https://github.com/JacobPEvans/nix-home/issues/51)) ([a609a72](https://github.com/JacobPEvans/nix-home/commit/a609a723e61dc2d5446926e424279b362d8b3892))
* rename GH_APP_ID secret to GH_ACTION_JACOBPEVANS_APP_ID ([#48](https://github.com/JacobPEvans/nix-home/issues/48)) ([b74734e](https://github.com/JacobPEvans/nix-home/commit/b74734e3b99e6f90bafcfab4a4549feb0b0668ab))
