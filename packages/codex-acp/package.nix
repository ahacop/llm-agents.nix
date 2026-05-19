{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  rustPlatform,
  pkg-config,
  openssl,
  libcap,
}:
let
  versionData = builtins.fromJSON (builtins.readFile ./hashes.json);
  inherit (versionData)
    version
    hash
    cargoHash
    codexOwner
    codexRev
    codexSrcHash
    librusty_v8
    ;

  # codex-linux-sandbox's build.rs compiles a vendored copy of bubblewrap (with
  # patches) that lives in codex-rs/vendor/bubblewrap in the main codex repo.
  # Cargo vendoring flattens the workspace so this directory is missing; we
  # fetch the codex source at the pinned rev to provide it via
  # CODEX_BWRAP_SOURCE_DIR.
  codexSrc = fetchFromGitHub {
    owner = codexOwner;
    repo = "codex";
    rev = codexRev;
    hash = codexSrcHash;
  };

  # The v8 crate downloads a prebuilt static library at build time. Fetch it
  # as a fixed-output derivation so the build stays sandboxed.
  librustyV8 = fetchurl {
    name = "librusty_v8-${librusty_v8.version}";
    url = "https://github.com/denoland/rusty_v8/releases/download/v${librusty_v8.version}/librusty_v8_release_${stdenv.hostPlatform.rust.rustcTarget}.a.gz";
    hash = librusty_v8.hashes.${stdenv.hostPlatform.system};
    meta.sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
in
rustPlatform.buildRustPackage {
  pname = "codex-acp";
  inherit version;

  src = fetchFromGitHub {
    owner = "zed-industries";
    repo = "codex-acp";
    rev = "v${version}";
    inherit hash;
  };

  inherit cargoHash;

  env = {
    RUSTY_V8_ARCHIVE = librustyV8;
  }
  // lib.optionalAttrs stdenv.hostPlatform.isLinux {
    # Point the codex-linux-sandbox build.rs at the vendored bubblewrap source
    CODEX_BWRAP_SOURCE_DIR = "${codexSrc}/codex-rs/vendor/bubblewrap";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libcap
  ];

  doCheck = false;

  passthru.category = "ACP Ecosystem";

  meta = with lib; {
    description = "An ACP-compatible coding agent powered by Codex";
    homepage = "https://github.com/zed-industries/codex-acp";
    changelog = "https://github.com/zed-industries/codex-acp/releases/tag/v${version}";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    sourceProvenance = with sourceTypes; [
      fromSource
      binaryNativeCode
    ];
    mainProgram = "codex-acp";
  };
}
