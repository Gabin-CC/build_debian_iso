#!/bin/bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source_repository=${SEAPATH_MANAGER_REPOSITORY:-git@github.com:rte-i/SEAPATH-Manager.git}
source_commit=${SEAPATH_MANAGER_COMMIT:-070a03dd957f9de905fd17b4c1bdb6a0587e84d0}
image=${SEAPATH_MANAGER_IMAGE:-ghcr.io/rte-i/seapath-manager:latest}
work_dir=$(mktemp -d)
podman_args=()

if [ -n "${SEAPATH_PODMAN_ROOT:-}" ]; then
    podman_runroot=${SEAPATH_PODMAN_RUNROOT:-${SEAPATH_PODMAN_ROOT}/runroot}
    sudo mkdir -p "$SEAPATH_PODMAN_ROOT" "$podman_runroot"
    podman_args=(--root "$SEAPATH_PODMAN_ROOT" --runroot "$podman_runroot")
fi

cleanup() {
    rm -rf "$work_dir"
}
trap cleanup EXIT

git clone "$source_repository" "$work_dir/SEAPATH-Manager"
git -C "$work_dir/SEAPATH-Manager" checkout --detach "$source_commit"
git -C "$work_dir/SEAPATH-Manager" apply "$script_dir/../manager-image/SEAPATH-Manager.patch"

sudo podman "${podman_args[@]}" build --tag "$image" "$work_dir/SEAPATH-Manager"
echo "Built $image from SEAPATH-Manager@$source_commit"
