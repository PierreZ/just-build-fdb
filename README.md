# just-build-fdb

A self-contained dev environment for hacking on
[FoundationDB](https://github.com/apple/foundationdb) and friends from a NixOS
host, using the upstream Rocky 9 build container. More build/run recipes will
be added incrementally.

## Layout

```
just-build-fdb/
├── flake.nix       # nix dev shell (just, docker-client, git, jq, ripgrep, libxml2)
├── .envrc          # direnv: auto-loads the flake if `nix` is on PATH
├── Justfile        # recipes — entry point for every operation
├── src/            # upstream source clones (gitignored)
├── build/          # build outputs (gitignored)
├── dockerfiles/    # custom Dockerfiles
├── joshua/         # fdb-joshua clone (gitignored)
├── build-support/  # fdb-build-support clone (gitignored)
└── k8s-operator/   # fdb-kubernetes-operator clone (gitignored)
```

## Prerequisites

- Docker (rootless or rootful).
- `nix` with flakes enabled (preferred), or `just` ≥ 1.x on PATH.

## First-time setup

```bash
nix develop          # or let direnv do it via .envrc
just bootstrap       # clone all configured upstream repos
just setup           # create build/ + ccache dirs, docker pull the image
```

## Adding another repo

Add `<name>_owner` / `<name>_repo` / `<name>_host` near the top of the
`Justfile`, then append one `_clone` line to the `bootstrap` recipe.
