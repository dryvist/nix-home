# Changelog

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
