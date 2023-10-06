#!/bin/bash

source .envrc

# configure
BUILD_DIR=${PWD}/build
STAGE_DIR=${PWD}/install
CCACHE=`which ccache`

set -e
set -u
set -x

# distclean
rm -rf ${BUILD_DIR} ${STAGE_DIR}

export LD_LIBRARY_PATH=${INSTALL_PREFIX}/lib:/usr/local/lib:/usr/lib
export DYLD_LIBRARY_PATH=${LD_LIBRARY_PATH}
# see https://gitlab.kitware.com/cmake/community/-/wikis/doc/cmake/RPATH-handling

cmake -S . -B ${BUILD_DIR} -G Ninja -D CMAKE_CXX_COMPILER_LAUNCHER=${CCACHE} \
  -D CMAKE_BUILD_TYPE=Release \
  -D CMAKE_SKIP_BUILD_RPATH=OFF \
  -D CMAKE_INSTALL_RPATH=${INSTALL_PREFIX}/lib \
  -D BUILD_WITH_INSTALL_NAME_DIR=OFF \
  -D CMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -D CMAKE_INSTALL_RPATH_USE_LINK_PATH=ON \
  -D CMAKE_STAGING_PREFIX=${STAGE_DIR} \
  -D CMAKE_PREFIX_PATH=${INSTALL_PREFIX} \
  -D CMAKE_CXX_STANDARD=17 \
  -D BUILD_SHARED_LIBS=ON -Wdev -Wdeprecated

# build example
cmake --build ${BUILD_DIR} --target all

# install example and its runtime dependencies
mkdir -p ${STAGE_DIR}

# cmake --build ${BUILD_DIR} --target install
# # cleanup
# #XXX rm -rf ${STAGE_DIR}/lib/ridl
# rm -rf ${STAGE_DIR}/lib/pkgconfig
# rm -rf ${STAGE_DIR}/bin/fuzzers
# rm -rf ${STAGE_DIR}/bin/*.bat

PATH="/usr/local/opt/gnu-tar/libexec/gnubin:${PATH}"
pushd ${BUILD_DIR} && cpack -G TGZ
tar -C ${STAGE_DIR} -xzvf ${PWD}/itaox11-*.tar.gz --strip-components=1 \
    --exclude="*.a" --exclude="*.bat" --exclude=fuzzers --exclude=pkgconfig
popd

# cleanup
symlinks -rvd ${STAGE_DIR}/lib

for f in ${STAGE_DIR}/bin/*
do
    install_name_tool -add_rpath @executable_path/../lib $f || echo ignored
done

export LD_LIBRARY_PATH=${STAGE_DIR}/lib:/usr/local/lib:/usr/lib
export DYLD_LIBRARY_PATH=${LD_LIBRARY_PATH}
ldd ${STAGE_DIR}/bin/consumer || objdump --dylibs-used --macho ${STAGE_DIR}/bin/consumer
find ${STAGE_DIR}/lib -name 'lib*.so*' -o -name 'lib*.dylib' | egrep -v '(taox11|TAO|ACE)' | xargs ls -l

# test installed example
export PATH="${STAGE_DIR}/bin:${PATH}"
pushd ${STAGE_DIR}/bin && ./run_test.pl -s #XXX -debug
#XXX pushd ${BUILD_DIR} && ctest --output-on-failure
