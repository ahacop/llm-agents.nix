{
  lib,
  flake,
  buildGoModule,
  go_1_26,
  fetchFromGitHub,
  git,
  versionCheckHook,
  versionCheckHomeHook,
}:

# crit requires a go >= 1.26 toolchain.
(buildGoModule.override { go = go_1_26; }) rec {
  pname = "crit";
  version = "0.18.1";

  src = fetchFromGitHub {
    owner = "tomasz-tomczyk";
    repo = "crit";
    tag = "v${version}";
    hash = "sha256-7mvSuODYWxAhrjKMPbSt8n5jBHoB8xoG+amIT9vS9n8=";
  };

  vendorHash = "sha256-xgNFYuYw6if40UmxoAGNve9FWy6Gt5MCEIz+7CIqjRo=";

  subPackages = [ "cmd/crit" ];

  # cmd/crit's preflight tests (TestPreflightCheck_*) shell out to `git init`.
  nativeCheckInputs = [ git ];
  preCheck = ''
    export HOME=$(mktemp -d)
    git config --global user.email crit@example.com
    git config --global user.name crit
    git config --global init.defaultBranch main
  '';

  # The story-generation tests write a fake agent as a `#!/usr/bin/env bash`
  # script and exec it. `/usr/bin/env` is absent from the sandbox, so the exec
  # fails with ENOENT.
  checkFlags = [ "-skip=^TestStoryLLM_" ];

  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${version}"
  ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    versionCheckHook
    versionCheckHomeHook
  ];

  passthru.category = "Code Review";

  meta = with lib; {
    description = "Local-first review tool for coding-agent plans, diffs, and web pages";
    homepage = "https://github.com/tomasz-tomczyk/crit";
    changelog = "https://github.com/tomasz-tomczyk/crit/releases/tag/v${version}";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
    maintainers = with flake.lib.maintainers; [ ahacop ];
    mainProgram = "crit";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
