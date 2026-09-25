# packages/playwright-cli.nix
#
# Pure Nix derivation for `playwright-cli` (npm package `@playwright/cli`),
# packaged so the KiroCrew gateway's browser tool works on this NixOS-in-WSL
# host with NO runtime curl-installer and NO CDN browser download. Everything
# is resolved at BUILD time to /nix/store paths.
#
# WHY THIS EXISTS / HOW IT IS ACCEPTED BY THE GATEWAY
#   The gateway resolves the binary named exactly `playwright-cli` by ABSOLUTE
#   PATH from a fixed allow-list of trusted system bin dirs
#   (kiro_crew/platform_compat.py _TRUSTED_SYSTEM_BIN_DIRS), which includes
#   /run/current-system/sw/bin -- never from $PATH. NixOS places every
#   environment.systemPackages binary into /run/current-system/sw/bin, so a
#   Nix-provided `playwright-cli` there IS an accepted "vetted system install".
#   kiro.nix adds this package to environment.systemPackages (kiro flake scope
#   only), which is what puts it on that trusted path.
#
# THE BROWSER-REVISION RECONCILIATION (the usual failure, solved here)
#   Playwright pins EXACT browser build numbers per release. The nixpkgs
#   `playwright-driver` provides a browsers directory built for one specific
#   Playwright line; if the CLI's bundled playwright-core expects a different
#   chromium build number than the one in that directory, launch fails even
#   with PLAYWRIGHT_BROWSERS_PATH set (it looks for chromium-<N> and finds a
#   different <N>). So the CLI version is pinned to the one whose playwright-core
#   matches the nixpkgs driver's chromium build:
#
#     nixpkgs playwright-driver @ 1.63.0  ships  chromium-1243 (+ headless_shell
#         -1243), ffmpeg-1011, firefox-1543, webkit-2359.
#     @playwright/cli @ 0.1.19  ->  playwright-core 1.63.0-alpha-2026-08-31,
#         whose browsers.json expects chromium revision 1243 (EXACT match),
#         chromium-headless-shell 1243 (exact), ffmpeg 1011 (exact).
#
#   Chromium is the browser the gateway's browser tool drives, and it matches
#   exactly. (firefox/webkit are +1 build in nixpkgs -- 1542 vs 1543, 2358 vs
#   2359 -- harmless for the chromium-only browser tool; noted for honesty.)
#   The latest CLI (0.1.21) wants chromium 1246, which nixpkgs 1.63.0 does NOT
#   provide -- that is exactly why `latest` is not pinned here.
#
#   A guard below asserts, at build time, that the nixpkgs driver still ships
#   chromium-1243. If a future nixpkgs bump moves the driver's chromium build,
#   this derivation FAILS LOUDLY (telling you to re-pin the CLI version and
#   npmDepsHash) instead of silently shipping a CLI that cannot launch.
#
# RE-PINNING (when you deliberately bump)
#   1. Pick a @playwright/cli version whose playwright-core browsers.json
#      chromium revision equals the nixpkgs playwright-driver.browsers
#      chromium-<N> build (compare `ls playwright-driver.browsers` against the
#      tarball's node_modules/playwright-core/browsers.json).
#   2. Set `version` below, regenerate packages/playwright-cli/package-lock.json
#      (npm install --package-lock-only --ignore-scripts in a dir whose
#      package.json pins that version), and recompute npmDepsHash with
#      `prefetch-npm-deps package-lock.json`.
#   3. Update `expectedChromiumRevision` to the new build number.

{ lib
, buildNpmPackage
, nodejs_22
, makeWrapper
, playwright-driver
, runCommand
}:

let
  # ---- pins -----------------------------------------------------------------
  version = "0.1.19";                 # @playwright/cli, chosen for chromium-1243
  npmDepsHash = "sha256-OTvTcXALsKONhE8zAAPnbjyvsZ3N+BLmpSm1aRJ5o38=";
  expectedChromiumRevision = "1243";  # must match nixpkgs playwright-driver

  browsers = playwright-driver.browsers;

  # Build-time guard: fail loudly if the nixpkgs driver's chromium build no
  # longer matches what the pinned CLI expects. `browsers` is a directory of
  # symlinks named chromium-<rev>, firefox-<rev>, ... so we just assert the
  # expected chromium-<rev> entry exists.
  browsersChecked = runCommand "playwright-browsers-revision-checked"
    { inherit browsers expectedChromiumRevision; }
    ''
      if [ ! -e "$browsers/chromium-$expectedChromiumRevision" ]; then
        echo "ERROR: nixpkgs playwright-driver.browsers does not contain" >&2
        echo "  chromium-$expectedChromiumRevision" >&2
        echo "Its actual contents are:" >&2
        ls -1 "$browsers" >&2
        echo "" >&2
        echo "The pinned @playwright/cli version expects chromium-$expectedChromiumRevision." >&2
        echo "Re-pin playwright-cli.nix: choose a @playwright/cli version whose" >&2
        echo "playwright-core browsers.json chromium revision matches the driver," >&2
        echo "then update version + npmDepsHash + expectedChromiumRevision." >&2
        exit 1
      fi
      # Pass-through: expose the driver's browsers dir under a stable name.
      ln -s "$browsers" "$out"
    '';

in
buildNpmPackage {
  pname = "playwright-cli";
  inherit version npmDepsHash;

  # The "src" is a tiny vendor project whose only dependency is the pinned
  # @playwright/cli. buildNpmPackage runs `npm ci` against the committed
  # package-lock.json in a NETWORK-FREE sandbox, fetching every tarball from
  # the fixed-output npmDeps derivation (hashed by npmDepsHash).
  src = ./playwright-cli;

  nodejs = nodejs_22;

  nativeBuildInputs = [ makeWrapper ];

  # No compile/build step -- @playwright/cli is a plain JS launcher.
  dontNpmBuild = true;

  # Never let any transitive postinstall reach the Playwright CDN during the
  # build. playwright's postinstall would try to download browsers; we ship
  # them from nixpkgs instead, so skip the download entirely.
  npmInstallFlags = [ "--ignore-scripts" ];
  PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
  PLAYWRIGHT_BROWSERS_PATH = "0";

  # buildNpmPackage's default install copies the whole project (incl.
  # node_modules) to $out/lib/node_modules/<pname>. We override installPhase to
  # place node_modules under $out/lib and wrap the CLI entry as the final
  # `playwright-cli` binary with the runtime env baked in.
  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib" "$out/bin"
    cp -r node_modules "$out/lib/node_modules"

    entry="$out/lib/node_modules/@playwright/cli/playwright-cli.js"
    if [ ! -f "$entry" ]; then
      echo "ERROR: expected CLI entry not found at $entry" >&2
      ls -la "$out/lib/node_modules/@playwright/cli" >&2 || true
      exit 1
    fi

    makeWrapper "${nodejs_22}/bin/node" "$out/bin/playwright-cli" \
      --add-flags "$entry" \
      --prefix PATH : "${lib.makeBinPath [ nodejs_22 ]}" \
      --set PLAYWRIGHT_BROWSERS_PATH "${browsersChecked}" \
      --set PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD "1" \
      --set NO_UPDATE_NOTIFIER "1"

    runHook postInstall
  '';

  # Sanity check at build time: the wrapped binary must run offline and print
  # its version (this also proves node + the launcher resolve correctly).
  doInstallCheck = true;
  installCheckPhase = ''
    export HOME="$(mktemp -d)"
    echo "playwright-cli --version:"
    "$out/bin/playwright-cli" --version
  '';

  meta = {
    description = "Playwright CLI (@playwright/cli), pinned to match the nixpkgs playwright-driver browsers for offline launch";
    homepage = "https://playwright.dev";
    license = lib.licenses.asl20;
    mainProgram = "playwright-cli";
    platforms = lib.platforms.linux;
  };
}
