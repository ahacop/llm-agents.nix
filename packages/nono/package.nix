{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  dbus,
  pkg-config,
  autoPatchelfHook,
  versionCheckHook,
  unpinCargoMsrvHook,
  ...
}:

rustPlatform.buildRustPackage rec {
  pname = "nono";
  version = "0.61.0";

  src = fetchFromGitHub {
    owner = "always-further";
    repo = "nono";
    rev = "v${version}";
    hash = "sha256-4ZcYqU0p3C9a2akOFYqyltVyAIsmafVTWtc3uxzF+I4=";
  };

  cargoHash = "sha256-6Zdvf7W8WMm2lGfgSb+PZk2h+r2hMU2CbByfOdCO41E=";

  # `if let` guards in match arms require Rust >= 1.95; rewrite the single
  # use until nixpkgs ships a new enough rustc.
  patches = [ ./no-if-let-guard.patch ];

  # keyring uses sync-secret-service (dbus) on Linux, apple-native on Darwin
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ dbus ];
  # unpinCargoMsrvHook: upstream pins rust-version = "1.95" (unreleased MSRV
  # bump) but builds fine on the rustc in nixpkgs.
  nativeBuildInputs = [
    unpinCargoMsrvHook
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    pkg-config
    autoPatchelfHook
  ];

  doCheck = false;

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    versionCheckHook
  ];

  passthru.category = "Sandboxing & Isolation";

  meta = with lib; {
    description = "Kernel-enforced agent sandbox. Capability-based isolation with secure key management, atomic rollback, cryptographic immutable audit chain of provenance. Run your agents in a zero-trust environment.";
    homepage = "https://nono.sh/";
    changelog = "https://github.com/always-further/nono/releases/tag/v${version}";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ fromSource ];
    maintainers = with maintainers; [ pogobanane ];
    mainProgram = "nono";
    platforms = platforms.unix;
  };
}
