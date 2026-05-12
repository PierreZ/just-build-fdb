# just-build-fdb — agent notes

## What this repo is

A thin shell around upstream FoundationDB tooling. The actual work happens in
the cloned subtrees (`src/foundationdb`, `joshua/`, `build-support/`,
`k8s-operator/`) and inside the Rocky 9 dev container. This repo is the glue.

## Working principles here

- **Keep it minimal.** Recipes are added incrementally as the user asks for
  them. Don't pre-emptively lift the CI-parity, sim-loop, mako, serve, etc.
  recipes from the gist (`Justfile` history) until they're requested.
- **Two first-time recipes by design**: `bootstrap` (clone repos) and `setup`
  (mkdir + docker pull). They fail for different reasons — keep them split.
- **One bootstrap, many repos.** Each upstream gets an `<name>_owner` +
  `<name>_repo` + `<name>_host` triple at the top of the `Justfile`, plus
  one `_clone` line in `bootstrap`. The private `_clone` helper is the only
  place git-clone logic lives.
- **Paths are repo-relative.** All `*_host` vars derive from
  `justfile_directory()`; ccache is the one exception (it lives under
  `~/.cache/` so it survives `rm -rf build/`).
- **Cloned subtrees are gitignored.** Each has its own `.git`. Don't `git add`
  inside them from this repo.

## Provenance

The Justfile + flake were lifted from a gist
(<https://gist.github.com/PierreZ/a83f4da77fdd9853c174ba48c32fada4>) that
captures the original FDB-on-NixOS workflow. The gist has the full set of
build/run/CI recipes — when the user asks for one, copy it over and adapt the
paths to the repo-relative `src_host` / `build_host`.

## Things to be careful with

- The FDB build is hours cold. Don't trigger a build "to verify" anything
  unless the user explicitly asks.
- The cloned subtrees can be large (`src/foundationdb` is hundreds of MB).
  Don't grep them as part of routine exploration.
- User signs commits with a yubikey — wait for them to touch it before
  assuming `git commit` will complete.
