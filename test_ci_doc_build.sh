#!/usr/bin/env bash
#
# test_ci_doc_build.sh
#
# Reproduces the HuggingFace doc-builder CI workflow locally using the
# Docker image built from this repo's Dockerfile.
#
# This faithfully replicates what the reusable workflow at
# huggingface/doc-builder/.github/workflows/build_pr_documentation.yml does
# when called from pollen-robotics/reachy_mini with custom_container set.
#
# Usage:
#   ./test_ci_doc_build.sh [OPTIONS]
#
# Options:
#   --branch BRANCH   reachy_mini branch to test (default: main)
#   --no-build        Skip Docker image rebuild, reuse existing local image
#   --image IMAGE     Docker image name (default: reachymini_doc_test:latest)
#

set -euo pipefail

# --- defaults ---
REACHY_BRANCH="main"
BUILD_IMAGE=true
IMAGE_NAME="pollenrobotics/reachymini_documentation:1.0.2"

# --- parse arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --branch)
            REACHY_BRANCH="$2"
            shift 2
            ;;
        --no-build)
            BUILD_IMAGE=false
            shift
            ;;
        --image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Reproduces the HuggingFace doc-builder CI workflow locally."
            echo "By default, builds the Docker image from the local Dockerfile."
            echo ""
            echo "Options:"
            echo "  --branch BRANCH   reachy_mini branch to test (default: 859-add-gstreamer-to-pyprojectyml)"
            echo "  --no-build        Skip Docker image rebuild, reuse existing local image"
            echo "  --image IMAGE     Docker image name (default: reachymini_doc_test:latest)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  CI Doc Build Reproduction Test"
echo "============================================"
echo "  reachy_mini branch: ${REACHY_BRANCH}"
echo "  Docker image:       ${IMAGE_NAME}"
echo "  Build image:        ${BUILD_IMAGE}"
echo "============================================"
echo ""

# --- Step 1: Build Docker image from local Dockerfile ---
if [ "${BUILD_IMAGE}" = true ]; then
    echo ">>> Building Docker image from local Dockerfile..."
    docker build -t "${IMAGE_NAME}" "${SCRIPT_DIR}"
    echo ""
fi

# --- Step 2: Run the CI steps inside the container ---
echo ">>> Running CI doc build in container..."
echo ""

docker run --rm \
    -e "DIFFUSERS_SLOW_IMPORT=yes" \
    -e "UV_HTTP_TIMEOUT=900" \
    -e "NODE_OPTIONS=--max-old-space-size=6656" \
    "${IMAGE_NAME}" \
    bash -exc "
# -------------------------------------------------------
# This script mirrors the CI workflow steps exactly.
# See: huggingface/doc-builder/.github/workflows/build_pr_documentation.yml
# -------------------------------------------------------

# --- CI Step: Setup uv and venv ---
# The CI does: pip install -U uv && uv venv
# With custom_container, PIP_OR_UV=pip and ROOT_APT_GET=apt-get
pip install -U uv
uv venv

# --- CI Step: Clone doc-builder ---
git clone --depth 1 https://github.com/huggingface/doc-builder.git

# --- CI Step: Clone reachy_mini (the target branch) ---
git clone --depth 1 --branch '${REACHY_BRANCH}' https://github.com/pollen-robotics/reachy_mini.git

# --- CI Step: Setup environment ---
# The CI activates the venv, reinstalls doc-builder from source,
# then installs the target package with .[dev]
source .venv/bin/activate

pip uninstall -y doc-builder || true

cd doc-builder
git pull origin main
pip install .
cd ..

# Install reachy_mini with .[dev] -- the CI does this even though
# reachy_mini uses [dependency-groups] instead of [project.optional-dependencies] dev.
# This effectively just installs base dependencies.
cd reachy_mini
pip install .[dev]
cd ..

# --- CI Step: Make documentation ---
# The CI runs doc-builder build from inside the doc-builder directory.
# The paths are relative to doc-builder/:
#   package docs:  ../reachy_mini/docs/source
#   build output:  ../build_dir/reachy_mini/test/en
cd doc-builder

doc-builder build reachy_mini \
    ../reachy_mini/docs/source \
    --build_dir ../build_dir/reachy_mini/test/en \
    --clean \
    --html \
    --repo_owner pollen-robotics \
    --repo_name reachy_mini \
    --version_tag_suffix=src/

cd ..

echo ''
echo '============================================'
echo '  Doc build completed successfully!'
echo '============================================'
"

EXIT_CODE=$?

echo ""
if [ ${EXIT_CODE} -eq 0 ]; then
    echo ">>> SUCCESS: Doc build passed."
else
    echo ">>> FAILURE: Doc build failed with exit code ${EXIT_CODE}."
fi

exit ${EXIT_CODE}
