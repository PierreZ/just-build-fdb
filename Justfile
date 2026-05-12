# just-build-fdb — FoundationDB dev workflow.
# Source lives in src/<repo>, builds in build/<repo>, all compilation
# happens inside the upstream Rocky 9 container.

image     := "foundationdb/devel:rockylinux9-20250823035553-71c3cd601f"

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
