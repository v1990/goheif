#!/bin/bash

# Usage: 编译并输出依赖的库

set -e
set -x
PROJECT_DIR=$(pwd)

GOOS="$(go env GOOS)"
# 源码路径
SOURCE_CODE_PATH="${PROJECT_DIR}/libs"
# 编译后输出路径
if [[ -z "$INSTALL_PREFIX" ]]; then INSTALL_PREFIX="${PROJECT_DIR}/output/${GOOS}"; fi
if [[ -z "$HEIF_LIB_PATH" ]]; then HEIF_LIB_PATH="${PROJECT_DIR}/lib/${GOOS}"; fi

function install_tools_ubuntu() {
  tools=(git gcc g++ make cmake automake libtool pkg-config wget)
  for name in "${tools[@]}"; do
    if [[ ! -x $(which "$name") ]]; then
      echo "installing ${name} ... "

      (apt-get install -y "$name") || {
        echo "install $name failed."
        exit 1
      }
    fi
  done
}

function build_libx265() {
  if [[ ! -d "${SOURCE_CODE_PATH}/x265" ]]; then
    git clone https://github.com/videolan/x265.git "${SOURCE_CODE_PATH}/x265"
  fi

  if [[ -f "${SOURCE_CODE_PATH}/x265/build/${GOOS}/Makefile" ]]; then
    cd ${SOURCE_CODE_PATH}/x265/build/${GOOS} && make clean
  fi

  (
    echo "building libx265 ..." &&
      cd "${SOURCE_CODE_PATH}/x265" &&
      mkdir -p build/${GOOS} &&
      cd build/${GOOS} &&
      cmake -G "Unix Makefiles" -D CMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" ../../source &&
      make &&
      make install &&
      echo "build libde265 finish."
  ) || {
    echo "build libde265 failed"
    exit 1
  }
}

function build_libde265() {
  if [[ ! -d "${SOURCE_CODE_PATH}/libde265" ]]; then
    git clone https://github.com/strukturag/libde265.git "${SOURCE_CODE_PATH}/libde265"
  fi

  if [[ -f "${SOURCE_CODE_PATH}/libde265/Makefile" ]]; then
    cd ${SOURCE_CODE_PATH}/libde265 && make clean
  fi

  (
    echo "building libde265 ..." &&
      cd "${SOURCE_CODE_PATH}/libde265" &&
      sh ./autogen.sh &&
      ./configure --prefix="${INSTALL_PREFIX}" --disable-sherlock265 &&
      make &&
      make install &&
      echo "build libde265 finish."
  ) || {
    echo "build libde265 failed"
    exit 1
  }
}

function build_libheif() {
  if [[ ! -d "${SOURCE_CODE_PATH}/libheif" ]]; then
    git clone https://github.com/strukturag/libheif.git "${SOURCE_CODE_PATH}/libheif"
  fi

  if [[ -f "${SOURCE_CODE_PATH}/libheif/Makefile" ]]; then
    cd ${SOURCE_CODE_PATH}/libheif && make clean
  fi

  (
    echo "building libheif ..." &&
      cd "${SOURCE_CODE_PATH}/libheif" &&
      sh ./autogen.sh &&
      ./configure --prefix="${INSTALL_PREFIX}" &&
      make &&
      make install &&
      echo "build libheif finish."
  ) || {
    echo "build libde265 failed"
    exit 1
  }
}

function test_libheif() {
  ${GOROOT}/bin/go test -v ./...
  if [[ ! $? -eq 0 ]]; then
    echo "test failed"
    exit 1
  fi
}

function build_libs() {
  mkdir -p "$SOURCE_CODE_PATH" "$INSTALL_PREFIX" "$HEIF_LIB_PATH"

  export PKG_CONFIG_PATH=${INSTALL_PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH

  if [[ "$GOOS" =~ "linux" ]]; then
    install_tools_ubuntu
  elif [[ "$GOOS" =~ "darwin" ]]; then
    brew install cmake qt automake make pkg-config x265 libde265 libjpeg
  fi

  build_libx265
  build_libde265
  build_libheif

  mkdir -p ${HEIF_LIB_PATH}/lib ${HEIF_LIB_PATH}/include
  cp -f ${INSTALL_PREFIX}/lib/*.a ${HEIF_LIB_PATH}/lib/
  cp -R ${INSTALL_PREFIX}/include/* ${HEIF_LIB_PATH}/include/

  test_libheif

  echo "build libs finish"

}

build_libs
