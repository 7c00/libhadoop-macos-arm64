#!/bin/bash

set -eux
readonly _PWD="$(cd "$(dirname "$0")"; pwd)"
readonly SRC_DIR="${_PWD}/build/src"
readonly OPT_DIR="${_PWD}/build/opt"
readonly OUT_DIR="${_PWD}/out"

mkdir -p "${SRC_DIR}" "${OPT_DIR}"

(
: ==== Build zlib ====
readonly SRC_ZLIB="${SRC_DIR}/zlib"
mkdir -p "${SRC_ZLIB}"
pushd "${SRC_ZLIB}"

curl -sL -o zlib-1.2.12.tar.gz  https://github.com/madler/zlib/archive/refs/tags/v1.2.12.tar.gz
shasum -a 256 zlib-1.2.12.tar.gz
tar --strip-components=1 -xzf zlib-1.2.12.tar.gz

export ZERO_AR_DATE=1
cmake -B build -DCMAKE_OSX_ARCHITECTURES='arm64' -DCMAKE_INSTALL_PREFIX="${OPT_DIR}"
cmake --build build
cmake --install build
popd
)


(
: ==== Build snappy ====
readonly SRC_SNAPPY="${SRC_DIR}/snappy"
mkdir -p "${SRC_SNAPPY}"
pushd "${SRC_SNAPPY}"

# 6a2b78a is the lastest commit from main branch in June 2022
curl -sL -o snappy-6a2b78a.tar.gz https://github.com/google/snappy/archive/6a2b78a379e4a6ca11eaacb3e26bea397a46d74b.tar.gz
shasum -a 256 snappy-6a2b78a.tar.gz
tar --strip-components=1 -xzf snappy-6a2b78a.tar.gz

export ZERO_AR_DATE=1
cmake -B build -DSNAPPY_BUILD_TESTS=off \
    -DSNAPPY_BUILD_BENCHMARKS=off \
    -DBUILD_SHARED_LIBS=on \
    -DCMAKE_OSX_ARCHITECTURES='arm64' \
    -DCMAKE_PREFIX_PATH="${OPT_DIR}" \
    -DCMAKE_INSTALL_PREFIX="${OPT_DIR}"
cmake --build build
cmake --install build

cp "${OPT_DIR}/lib/libsnappy.1.1.9.dylib" "${OUT_DIR}"
popd
)

(
: ==== Build bzip2 ====
readonly SRC_BZIP2="${SRC_DIR}/bzip2"
mkdir -p "${SRC_BZIP2}"
pushd "${SRC_BZIP2}"

# 1ea1ac1 is the lastest commit from master branch in June 2022
curl -sL -o bzip2-1ea1ac18.tar.gz https://gitlab.com/bzip2/bzip2/-/archive/1ea1ac188ad4b9cb662e3f8314673c63df95a589/bzip2-1ea1ac188ad4b9cb662e3f8314673c63df95a589.tar.gz
shasum -a 256 bzip2-1ea1ac18.tar.gz
tar --strip-components=1 -xzf bzip2-1ea1ac18.tar.gz

export ZERO_AR_DATE=1
cmake -B build -DBUILD_SHARED_LIBS=on \
    -DCMAKE_OSX_ARCHITECTURES='arm64' \
    -DCMAKE_PREFIX_PATH="${OPT_DIR}" \
    -DCMAKE_INSTALL_PREFIX="${OPT_DIR}"
cmake --build build
cmake --install build

cp "${OPT_DIR}/lib/libbz2.1.0.9.dylib" "${OUT_DIR}"
popd
)

(
: ===== Build libhadoop ====
readonly SRC_HADOOP="${SRC_DIR}/hadoop"
mkdir -p "${SRC_HADOOP}"
pushd "${SRC_HADOOP}"

curl -sL -o hadoop-2.7.4.tar.gz https://github.com/apache/hadoop/archive/refs/heads/branch-2.7.4.tar.gz
shasum -a 256 hadoop-2.7.4.tar.gz
tar --strip-components=1 -xzf hadoop-2.7.4.tar.gz

# patch org_apache_hadoop_io_compress_bzip2.h
sed -i -e '/HADOOP_BZIP2_LIBRARY/d' \
    hadoop-common-project/hadoop-common/src/main/native/src/org/apache/hadoop/io/compress/bzip2/org_apache_hadoop_io_compress_bzip2.h

curl -sL -o protoc https://repo.maven.apache.org/maven2/com/google/protobuf/protoc/2.5.0/protoc-2.5.0-osx-x86_64.exe
shasum -a 256 protoc
chmod +x protoc
mkdir protoc-bin
mv protoc protoc-bin

export PATH="$(pwd)/protoc-bin:${PATH}"
export ZERO_AR_DATE=1
export CMAKE_PREFIX_PATH="${OPT_DIR}"
export CMAKE_OSX_ARCHITECTURES='arm64'
export CFLAGS='-Wl,-U,_JNI_CreateJavaVM -Wl,-U,_JNI_GetCreatedJavaVMs'
mvn package -DskipTests -pl hadoop-common-project/hadoop-common -am -Pnative -B

cp hadoop-common-project/hadoop-common/target/native/target/usr/local/lib/libhadoop.1.0.0.dylib "${OUT_DIR}"
popd
)

(
pushd "${OUT_DIR}"
shasum -a 256 *.dylib 2>&1 | tee sha256sum.txt
popd
)