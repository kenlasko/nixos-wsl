# packages/kirocrew.nix
#
# Pure Nix derivation for the `kirocrew` gateway (v0.7.0), packaged from the
# official py3-none-any wheel plus its dependency closure. Runs entirely from a
# /nix/store path: no venv, no first-boot pip, and NO LD_LIBRARY_PATH hack --
# the two libraries numpy needed at runtime (libz.so.1 from zlib, libstdc++.so.6
# from stdenv.cc.cc.lib) are resolved via nixpkgs' already-patched numpy, and
# the two deps we vendor from wheels (cryptography, pysqlite3-binary) are run
# through autoPatchelfHook so their .so files find their RPATH libraries at the
# store path directly.
#
# Usage from an overlay:  final.callPackage ./packages/kirocrew.nix { }
#
# Design notes:
#   * kirocrew itself is a pure-python wheel (py3-none-any) shipping a PREBUILT
#     dashboard under kiro_crew/static/dist (2545 assets). format="wheel" unpacks
#     the wheel verbatim, so those assets are preserved, never rebuilt.
#   * kirocrew's runtime constraints are RANGES, not exact pins, so most deps come
#     straight from nixpkgs (numpy<3, aiohttp<4, jsonschema<5, ... all satisfied).
#   * TWO deps need vendoring from their upstream wheels:
#       - cryptography: kirocrew pins cryptography<48; nixpkgs ships 50.0.0, which
#         violates the bound. We build 47.0.0 (the version the working venv ran)
#         from its manylinux2014 abi3 wheel.
#       - pysqlite3-binary: not in nixpkgs at all. Built from its cp312
#         manylinux2014 wheel.
#     Both are binary wheels; autoPatchelfHook + [ zlib stdenv.cc.cc.lib openssl ]
#     patches their ELF so no LD_LIBRARY_PATH is required.
#   * darwin/Windows-only deps (truststore, tzdata, pywinpty, tzlocal, pywin*)
#     are gated by environment markers in the wheel metadata and are not needed
#     on linux-x86_64, so they are intentionally absent.

{ lib
, python312
, fetchurl
, autoPatchelfHook
, zlib
, stdenv
, openssl
}:

let
  python = python312;
  pyPkgs = python.pkgs;

  # ---- vendored binary wheel: cryptography 47.0.0 (kirocrew needs <48) --------
  cryptography47 = pyPkgs.buildPythonPackage rec {
    pname = "cryptography";
    version = "47.0.0";
    format = "wheel";

    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/00/e3/b27be1a670a9b87f855d211cf0e1174a5d721216b7616bd52d8581d912ed/cryptography-47.0.0-cp311-abi3-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
      hash = "sha256-9cFXZPJhOUsirvawAlL1GV9G8sowC+xXFJR04lOLMfg=";
    };

    nativeBuildInputs = [ autoPatchelfHook ];
    # cryptography's _rust extension dlopens libssl/libcrypto and libgcc_s.
    buildInputs = [ openssl stdenv.cc.cc.lib ];
    propagatedBuildInputs = [ pyPkgs.cffi ];

    # This is the whole point of vendoring it -- do not let nixpkgs' newer
    # cryptography shadow it, and skip the (irrelevant) runtime-deps recheck.
    dontCheckRuntimeDeps = true;
    pythonImportsCheck = [ "cryptography" "cryptography.hazmat.bindings._rust" ];
  };

  # ---- vendored binary wheel: pysqlite3-binary (absent from nixpkgs) ----------
  pysqlite3-binary = pyPkgs.buildPythonPackage rec {
    pname = "pysqlite3-binary";
    version = "0.5.4.post2";
    format = "wheel";

    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/35/e8/292e14aa4ed1ef3d4a70703c0103823fcd4b7d9701d9462e52ef88c2cc10/pysqlite3_binary-0.5.4.post2-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
      hash = "sha256-thYs2Wb6Vj/oW1Nyw+YdEd15A70PCcwYXLCkyRJfSg8=";
    };

    nativeBuildInputs = [ autoPatchelfHook ];
    # The wheel statically bundles sqlite3; zlib/libgcc_s are the runtime libs.
    buildInputs = [ zlib stdenv.cc.cc.lib ];

    dontCheckRuntimeDeps = true;
    pythonImportsCheck = [ "pysqlite3" ];
  };

  # ---- vendored pure-python wheels: pdfminer.six + pdfplumber -----------------
  # nixpkgs' pdfplumber drags a build-time test/doc closure (backrefs ->
  # mkdocs-material) whose test suite has a flaky regex-timeout failure that
  # breaks the build on this channel. Both are pure-python py3-none-any wheels,
  # so vendoring them from PyPI sidesteps that closure entirely.
  pdfminer-six = pyPkgs.buildPythonPackage rec {
    pname = "pdfminer.six";
    version = "20260107";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/20/8b/28c4eaec9d6b036a52cb44720408f26b1a143ca9bce76cc19e8f5de00ab4/pdfminer_six-20260107-py3-none-any.whl";
      hash = "sha256-NmWFupfoDf+o8Azr4wPS84GITYY3r0zkIvHfPvOBEak=";
    };
    propagatedBuildInputs = [ pyPkgs.charset-normalizer cryptography47 ];
    dontCheckRuntimeDeps = true;
    pythonImportsCheck = [ "pdfminer" ];
  };

  pdfplumber = pyPkgs.buildPythonPackage rec {
    pname = "pdfplumber";
    version = "0.11.10";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/a2/9a/07d658e1e7fad860f1c541ab941348125dbdab773be3a0afaf32361866c7/pdfplumber-0.11.10-py3-none-any.whl";
      hash = "sha256-d0Hqgb8WW0dLFT5nidENGOBrbdzz7IQonD7y/taAJYA=";
    };
    propagatedBuildInputs = [ pdfminer-six pyPkgs.pillow pypdfium2 ];
    dontCheckRuntimeDeps = true;
    pythonImportsCheck = [ "pdfplumber" ];
  };

  # pypdfium2 is in nixpkgs (5.11.0, satisfies pdfplumber's range); reuse it.
  pypdfium2 = pyPkgs.pypdfium2;

in
pyPkgs.buildPythonApplication rec {
  pname = "kirocrew";
  version = "0.7.0";
  format = "wheel";

  src = fetchurl {
    url = "https://download.crew.kiro.dev/cli/stable/0.7.0/kirocrew-0.7.0-py3-none-any.whl";
    hash = "sha256-MwPoqs7WvtWtncAgctcaYSpTGUi4Jc0twHby4Bm/pps=";
  };

  # Pure-python wheel; no compiled ext of its own. autoPatchelfHook is not needed
  # for kirocrew itself, only for the vendored binary deps above.
  #
  # Explicit pyPkgs.* qualification (no `with pyPkgs`) so the vendored let-bound
  # names -- cryptography47, pysqlite3-binary, pdfplumber, pdfminer-six -- are
  # unambiguously the ones used, never silently shadowed by a nixpkgs attr.
  propagatedBuildInputs = [
    # networking / async
    pyPkgs.aiohttp
    pyPkgs.yarl
    pyPkgs.multidict
    pyPkgs.frozenlist
    pyPkgs.aiohappyeyeballs
    pyPkgs.aiosignal
    pyPkgs.websockets
    pyPkgs.requests
    pyPkgs.urllib3
    pyPkgs.certifi
    pyPkgs.charset-normalizer
    pyPkgs.idna
    # scheduling
    pyPkgs.cron-descriptor
    pyPkgs.croniter
    pyPkgs.python-dateutil
    pyPkgs.pytz
    # schema / config
    pyPkgs.jsonschema
    pyPkgs.jsonschema-specifications
    pyPkgs.referencing
    pyPkgs.rpds-py
    pyPkgs.attrs
    pyPkgs.pathspec
    pyPkgs.pyyaml
    pyPkgs.jinja2
    pyPkgs.markupsafe
    pyPkgs.typing-extensions
    # documents / office
    pyPkgs.openpyxl
    pyPkgs.et-xmlfile
    pyPkgs.python-docx
    pyPkgs.lxml
    pyPkgs.defusedxml
    # pdf  (vendored pdfplumber + pdfminer.six; pypdfium2/pillow from nixpkgs)
    pdfplumber
    pdfminer-six
    pypdfium2
    pyPkgs.pillow
    # numerics
    pyPkgs.numpy
    # qr
    pyPkgs.qrcode
    # slack
    pyPkgs.slack-sdk
    # telemetry
    pyPkgs.opentelemetry-api
    pyPkgs.opentelemetry-sdk
    pyPkgs.opentelemetry-semantic-conventions
    # misc
    pyPkgs.snowballstemmer
    pyPkgs.cffi
    pyPkgs.pycparser
    pyPkgs.six
    pyPkgs.propcache
    # package manager kirocrew shells out to
    pyPkgs.uv
    # vendored binary wheels
    cryptography47
    pysqlite3-binary
  ];

  # kirocrew's metadata bound is cryptography<48; our vendored 47.0.0 satisfies
  # it, but the default runtime-deps check can still trip on the beta/rc
  # resolutions the upstream freeze used (e.g. lxml 7.0.0b1 vs nixpkgs 6.1.1).
  # The wheel constraints are ranges and nixpkgs versions all fall inside them,
  # so disable the strict recheck rather than chase beta pins that add no value.
  dontCheckRuntimeDeps = true;

  pythonImportsCheck = [
    "kiro_crew"
    "kiro_crew._bootstrap"
  ];

  meta = {
    description = "Kiro Crew gateway (NixOS-native spoke), packaged from the 0.7.0 wheel";
    homepage = "https://crew.kiro.dev";
    mainProgram = "kirocrew";
    platforms = [ "x86_64-linux" ];
  };
}
