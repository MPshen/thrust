#! /usr/bin/env bash

# Copyright (c) 2018-2020 NVIDIA Corporation
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Released under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.

################################################################################
# Thrust and CUB build script for gpuCI
################################################################################

set -e

# Logger function for build status output
function logger() {
  echo -e "\n>>>> ${@}\n"
}

################################################################################
# VARIABLES - Set up bash and environmental variables.
################################################################################

# Get the variables the Docker container set up for us: ${CXX}, ${CUDACXX}, etc.
source /etc/cccl.bashrc

# Set path and build parallel level
export PATH=/usr/local/cuda/bin:${PATH}

# Set home to the job's workspace.
export HOME=${WORKSPACE}

# Switch to the build directory.
cd ${WORKSPACE}
mkdir -p build
cd build

# The Docker image sets up `${CXX}` and `${CUDACXX}`.
CMAKE_FLAGS="-G Ninja -DCMAKE_CXX_COMPILER='${CXX}' -DCMAKE_CUDA_COMPILER='${CUDACXX}'"

# COVERAGE_PLAN options:
# * EXHAUSTIVE
# * THOROUGH
# * MINIMAL
if [ ! -z "${COVERAGE_PLAN}" ]; then
  if [ "${BUILD_TYPE}" == "cpu" ] && [ "${BUILD_MODE}" == "branch" ]; then
    # Post-commit CPU CI builds.
    COVERAGE_PLAN="COMPLETE"
  elif [ "${BUILD_TYPE}" == "cpu" ]; then
    # Pre-commit CPU CI builds.
    COVERAGE_PLAN="THOROUGH"
  elif [ "${BUILD_TYPE}" == "gpu" ]; then
    # Pre- and post-commit GPU CI builds.
    COVERAGE_PLAN="MINIMAL"
  fi
fi

case "${COVERAGE_PLAN}" in
  EXHAUSTIVE)
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_INCLUDE_CUB_CMAKE=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_ENABLE_MULTICONFIG=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_MULTICONFIG_ENABLE_DIALECT_CPP11=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_IGNORE_DEPRECATED_CPP_11=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_MULTICONFIG_ENABLE_DIALECT_CPP14=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_MULTICONFIG_ENABLE_DIALECT_CPP17=OFF"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_MULTICONFIG_ENABLE_SYSTEM_CPP=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_MULTICONFIG_ENABLE_SYSTEM_TBB=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_MULTICONFIG_ENABLE_SYSTEM_OMP=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_MULTICONFIG_ENABLE_SYSTEM_CUDA=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_MULTICONFIG_WORKLOAD=LARGE"
    ;;
  THOROUGH)
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_INCLUDE_CUB_CMAKE=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_ENABLE_MULTICONFIG=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_MULTICONFIG_ENABLE_DIALECT_CPP11=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_IGNORE_DEPRECATED_CPP_11=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_MULTICONFIG_ENABLE_DIALECT_CPP14=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_MULTICONFIG_ENABLE_DIALECT_CPP17=OFF"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_MULTICONFIG_ENABLE_SYSTEM_CPP=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_MULTICONFIG_ENABLE_SYSTEM_TBB=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_MULTICONFIG_ENABLE_SYSTEM_OMP=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_MULTICONFIG_ENABLE_SYSTEM_CUDA=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_MULTICONFIG_WORKLOAD=SMALL"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_AUTO_DETECT_COMPUTE_ARCHS=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_ENABLE_COMPUTE_50=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_ENABLE_COMPUTE_60=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_ENABLE_COMPUTE_70=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_ENABLE_COMPUTE_80=ON"
    ;;
  MINIMAL)
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_INCLUDE_CUB_CMAKE=ON"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DCUB_TEST_VARIANT=MINIMAL"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_HOST_SYSTEM=CPP"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_DEVICE_SYSTEM=CUDA"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_CPP_DIALECT=14"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTHRUST_AUTO_DETECT_COMPUTE_ARCHS=ON"
    ;;
esac

CMAKE_BUILD_FLAGS="-j${PARALLEL_LEVEL}"

if [ ! -z "${@}" ]; then
  CMAKE_BUILD_FLAGS="${CMAKE_BUILD_FLAGS} -- ${@}"
fi

CTEST_FLAGS=""

if [ "${BUILD_TYPE}" == "cpu" ]; then
  CTEST_FLAGS="${CTEST_FLAGS} -E ^cub|^thrust.*cuda"
fi

if [ ! -z "${@}" ]; then
  CTEST_FLAGS="${CTEST_FLAGS} -R ^${@}$"
fi

# Export variables so they'll show up in the logs when we report the environment.
export COVERAGE_PLAN
export CMAKE_FLAGS
export CMAKE_BUILD_FLAGS
export CTEST_FLAGS

################################################################################
# ENVIRONMENT - Configure and print out information about the environment.
################################################################################

logger "Get environment..."
env

logger "Check versions..."
${CXX} --version
${CUDACXX} --version

################################################################################
# BUILD - Build Thrust and CUB examples and tests.
################################################################################

logger "Configure Thrust and CUB..."
echo cmake .. ${CMAKE_FLAGS}
cmake .. ${CMAKE_FLAGS}

logger "Build Thrust and CUB..."
echo cmake --build . ${CMAKE_BUILD_FLAGS}
cmake --build . ${CMAKE_BUILD_FLAGS}

################################################################################
# TEST - Run Thrust and CUB examples and tests.
################################################################################

logger "Test Thrust and CUB..."
echo ctest ${CTEST_FLAGS}
ctest ${CTEST_FLAGS}

