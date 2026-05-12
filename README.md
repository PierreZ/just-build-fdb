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
├── src/            # apple/foundationdb clone (gitignored)
├── build/          # foundationdb build output (gitignored)
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
just configure       # cmake configure inside the container
just build           # ninja fdbserver fdbcli mako (cold: hours, warm: minutes)
```

## Daily loop

```bash
just build                                # incremental rebuild of dev trio
just sim                                  # run a simulation (AtomicOps by default)
just sim tests/fast/CycleTest.toml "-s 42 -b on"
just shell                                # interactive shell in the container
just exec "ls /workspace/build/bin"       # one-shot command in the container
just down                                 # stop the container
```

Run `just` with no arguments for the live recipe list.

## Adding another repo

Add `<name>_owner` / `<name>_repo` / `<name>_host` near the top of the
`Justfile`, then append one `_clone` line to the `bootstrap` recipe.
