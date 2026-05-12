# just-build-fdb — FoundationDB dev workflow.
# Source lives in src/<repo>, builds in build/<repo>, all compilation
# happens inside the upstream Rocky 9 container.

image     := "foundationdb/devel:rockylinux9-20250823035553-71c3cd601f"
container := "fdb-dev"

# Repo-relative paths. `justfile_directory()` is the dir containing this Justfile,
# so this works no matter where you invoke `just` from.
root      := justfile_directory()

# Repo registry. Each upstream gets owner + repo + destination dir.
# Add a new triple here and one line in `bootstrap` to wire in another repo.
fdb_owner          := "apple"
fdb_repo           := "foundationdb"
joshua_owner       := "FoundationDB"
joshua_repo        := "fdb-joshua"
build_support_owner:= "FoundationDB"
build_support_repo := "fdb-build-support"
k8s_operator_owner := "FoundationDB"
k8s_operator_repo  := "fdb-kubernetes-operator"

src_host           := root / "src" / fdb_repo
build_host         := root / "build" / fdb_repo
joshua_host        := root / "joshua"
build_support_host := root / "build-support"
k8s_operator_host  := root / "k8s-operator"

# ccache lives outside the repo so it survives `rm -rf build/` and re-clones.
ccache    := env_var('HOME') / ".cache/fdb-ccache"

# Dev parallelism. Override per-call (e.g. `just build fdbserver` then later
# `just build target=foo`; bump this when CI-parity recipes land).
jobs      := "3"

# Default: list recipes.
default:
    @just --list

# Clone one upstream repo into `dest` if absent. Private — used by `bootstrap`.
_clone owner repo dest:
    @if [ ! -d {{dest}}/.git ]; then \
        echo "cloning {{owner}}/{{repo}} into {{dest}}..." ; \
        git clone https://github.com/{{owner}}/{{repo}}.git {{dest}} ; \
    else \
        echo "{{dest}} already cloned" ; \
    fi

# Clone every configured upstream repo. Add a `_clone` line per new repo.
bootstrap:
    @just _clone {{fdb_owner}} {{fdb_repo}} {{src_host}}
    @just _clone {{joshua_owner}} {{joshua_repo}} {{joshua_host}}
    @just _clone {{build_support_owner}} {{build_support_repo}} {{build_support_host}}
    @just _clone {{k8s_operator_owner}} {{k8s_operator_repo}} {{k8s_operator_host}}

# Create host dirs and pull the image.
setup:
    mkdir -p {{build_host}} {{ccache}}
    docker pull {{image}}

# Start the dev container detached. Idempotent.
up:
    @if [ -z "$(docker ps -q -f name=^{{container}}$)" ]; then \
        docker run -d --rm \
            --name {{container}} \
            -v {{src_host}}:/workspace/src \
            -v {{build_host}}:/workspace/build \
            -v {{ccache}}:/workspace/.ccache \
            -w /workspace \
            -e CC=clang -e CXX=clang++ \
            -e USE_LD=LLD -e USE_LIBCXX=1 \
            -e CCACHE_DIR=/workspace/.ccache \
            --user "$(id -u):$(id -g)" \
            {{image}} sleep infinity ; \
        echo "started {{container}}" ; \
    else \
        echo "{{container}} already running" ; \
    fi

# Stop (and `--rm` removes) the container.
down:
    -docker stop {{container}}

# Interactive bash inside the running container. `just up` first if needed.
shell: up
    docker exec -it {{container}} bash

# Configure the build with the dev flag set. Run once, or after big CMake changes.
configure: up
    docker exec -i {{container}} bash -lc '\
        cmake -S /workspace/src -B /workspace/build \
            -D USE_CCACHE=ON -D USE_WERROR=ON \
            -D USE_LD=LLD -D USE_LIBCXX=1 \
            -G Ninja'

# Build one or more ninja targets. Defaults to the dev trio: fdbserver, fdbcli, mako.
# Pass a different space-separated set to override (e.g. `just build fdbcli`).
build target="fdbserver fdbcli mako": up
    docker exec -i {{container}} bash -lc 'ninja -C /workspace/build -j {{jobs}} {{target}}'
