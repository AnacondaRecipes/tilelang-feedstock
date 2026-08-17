#!/bin/bash
set -exo pipefail

# Keep the wheel version exactly the release version — suppress upstream's
# "+cuXXX.git<sha>" local version label (see version_provider.py)
export NO_VERSION_LABEL=1

CMAKE_ARGS="${CMAKE_ARGS:-} -DCMAKE_BUILD_TYPE=Release"
CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_PREFIX_PATH=${PREFIX}"
# Use conda's libz3 (headers + Z3Config.cmake in $PREFIX) instead of the
# pip z3-solver site-packages layout
CMAKE_ARGS="${CMAKE_ARGS} -DUSE_PYPI_Z3=OFF"

if [[ "${gpu_variant}" == "cuda" ]]; then
    CMAKE_ARGS="${CMAKE_ARGS} -DUSE_CUDA=ON"
elif [[ "${gpu_variant}" == "metal" ]]; then
    CMAKE_ARGS="${CMAKE_ARGS} -DUSE_METAL=ON"
fi

export CMAKE_ARGS
export CMAKE_BUILD_PARALLEL_LEVEL=${CPU_COUNT}

${PYTHON} -m pip install . -vv --no-deps --no-build-isolation

# Upstream forces INSTALL_RPATH to $ORIGIN-relative entries only (wheel layout),
# so libz3 in $PREFIX/lib is not reachable at runtime. Append a $PREFIX/lib
# rpath; conda-build relocates it to a relative path at packaging time.
for lib in "${SP_DIR}"/tilelang/lib/*; do
    if [[ "$(uname)" == "Darwin" ]]; then
        install_name_tool -add_rpath "${PREFIX}/lib" "${lib}"
    else
        patchelf --add-rpath "${PREFIX}/lib" "${lib}"
    fi
done
