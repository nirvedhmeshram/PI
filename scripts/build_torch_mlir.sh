#!/bin/bash
set -eu -o pipefail

GITHUB_WORKSPACE=$PWD
if [ ! -d "$GITHUB_WORKSPACE" ]; then
  git clone --recursive git@github.com:makslevental/torch-mlir.git
fi
TORCH_MLIR_MAIN_SRC_DIR=${GITHUB_WORKSPACE}/torch-mlir
TORCH_MLIR_MAIN_BINARY_DIR=${GITHUB_WORKSPACE}/torch-mlir/build
TORCH_MLIR_INSTALL_DIR=${GITHUB_WORKSPACE}/torch_mlir_install

CMAKE_CONFIGS="\
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_INSTALL_PREFIX=$TORCH_MLIR_INSTALL_DIR \
  -DLLVM_CCACHE_BUILD=ON \
  -DLLVM_ENABLE_ASSERTIONS=ON \
  -DCMAKE_LINKER=lld \
  -DLLVM_ENABLE_PROJECTS=mlir \
  -DLLVM_ENABLE_ZSTD=OFF \
  -DLLVM_EXTERNAL_PROJECTS=torch-mlir;torch-mlir-dialects \
  -DLLVM_EXTERNAL_TORCH_MLIR_DIALECTS_SOURCE_DIR=${TORCH_MLIR_MAIN_SRC_DIR}/externals/llvm-external-projects/torch-mlir-dialects \
  -DLLVM_EXTERNAL_TORCH_MLIR_SOURCE_DIR=$TORCH_MLIR_MAIN_SRC_DIR \
  -DLLVM_INCLUDE_UTILS=ON \
  -DLLVM_INSTALL_UTILS=ON \
  -DLLVM_USE_HOST_TOOLS=ON \
  -DMLIR_ENABLE_BINDINGS_PYTHON=ON \
  -DPython3_EXECUTABLE=$(which python) \
  -DTORCH_MLIR_ENABLE_ONLY_MLIR_PYTHON_BINDINGS=ON \
  -DTORCH_MLIR_ENABLE_LTC=OFF \
  -DTORCH_MLIR_ENABLE_STABLEHLO=OFF \
  -DTORCH_MLIR_USE_INSTALLED_PYTORCH=ON"

case $OSTYPE in darwin*)
  CMAKE_CONFIGS="${CMAKE_CONFIGS} \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DLLVM_TARGETS_TO_BUILD=AArch64 \
    -DMACOSX_DEPLOYMENT_TARGET=12.0"
esac

cmake -G Ninja \
      $CMAKE_CONFIGS \
      -S${TORCH_MLIR_MAIN_SRC_DIR}/externals/llvm-project/llvm \
      -B${TORCH_MLIR_MAIN_BINARY_DIR}

cmake --build ${TORCH_MLIR_MAIN_BINARY_DIR} --target install
cp $TORCH_MLIR_MAIN_BINARY_DIR/tools/torch-mlir/python_packages/torch_mlir/torch_mlir/_mlir_libs/_jit_ir_importer* \
  $TORCH_MLIR_INSTALL_DIR/python_packages/torch_mlir/torch_mlir/_mlir_libs/
