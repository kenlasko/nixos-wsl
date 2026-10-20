---
title: "oc-login lab/usprod/euprod/inprod: GitLab IdP via oc login --web on WSL"
author: Ken
date: 2026-10-20
branch: main
cost: { minutes: 9, tokens: 61110 }
touches:
  - config/bash.nix
  - flake.nix
---

## Decided
- `oc-login lab|usprod|euprod|inprod` (config/bash.nix) uses `oc login --web` against Lab (api.lab1.test.nectarvoip.com, which is NOT prod) and the prod clusters api.prod{1,2,3}.nectar.services (US/EU/IN). These authenticate via a GitLab OAuth IdP, a browser redirect flow, so the sandbox's openshift-challenging-client basic-auth flow with sops credentials can't be reused.
- All four OAuth servers have openshift-cli-client registered and accept PKCE with a 127.0.0.1 redirect, so --web works. Their TLS is publicly trusted, so no --insecure-skip-tls-verify.
- After a --web login the function restores the previous current-context (or unsets it in ~/.kube/openshift), so these clusters are only ever active after an explicit `kuc <ctx>`.
- Lab's context is `nectar-lab`, not `lab`: ~/.kube/config already has a `lab` context (home lab), and ~/.kube/openshift comes first in KUBECONFIG, so a duplicate name would shadow it.
- oc opens the browser with xdg-open / x-www-browser / www-browser, none of which exist on this WSL host. A Nix-built `xdg-open` shim that execs wslview goes on PATH only for the oc call.

## Tried and ruled out
- Scripting the GitLab web login with curl (gitlab.com bot protection and 2FA) and using glab_token (OpenShift's GitLab IdP doesn't accept GitLab PATs).
- wslview as `cmd.exe /c start "$@"` (flake.nix): cmd treats `&` as a command separator, so any URL with a query string gets truncated and the call exits 1, which makes `oc login --web` abort with "error: exit status 1". Replaced with `rundll32.exe url.dll,FileProtocolHandler "$@"`.

## Watch out
- The wslview fix is in flake.nix and needs a nixos-rebuild switch before it takes effect; until then `oc-login prod` fails at the browser-open step.
- Test the login flow with HOME pointed at a scratch dir holding a copy of ~/.kube/openshift, so the real kubeconfig isn't touched.
