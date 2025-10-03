{ stdenv, lib }:

stdenv.mkDerivation {
  pname = "cnpg-kubectl-completion";
  version = "0.1";

  # nothing to fetch/build
  unpackPhase = "true";
  buildPhase = "true";

  installPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/kubectl_complete-cnpg <<'EOF'
    #!/usr/bin/env sh

    # Call the __complete command passing it all arguments
    kubectl cnpg __complete "$@"
    EOF
    chmod +x $out/bin/kubectl_complete-cnpg
  '';

  meta = with lib; {
    description = "Wrapper script that enables kubectl cnpg completions";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
