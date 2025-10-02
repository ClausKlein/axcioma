#!/bin/bash

source .envrc

export LANG=C
export CC=${CC:-gcc}
export CXX=${CXX:-g++}

# configure
export BUILD_DIR=${PWD}/build
export STAGE_DIR=${PWD}/install
export CCACHE=`which ccache`

pipx install clang-tidy && \
pipx install clang-format && \
pipx install cmake-format && \
pipx install cmake && \
pipx install ninja && \
pipx install builddriver

cat configure.log
#TODO(CK): builddriver cat make-all.log

set -e
set -u
set -x

# first install axcioma to ${INSTALL_PREFIX} if not yet done
#FIXME: make -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${X11_BASE_ROOT}" install 2>&1 | tee make-install.log

# distclean of cmake build trees
rm -rf ${BUILD_DIR} ${STAGE_DIR} ${INSTALL_PREFIX}/include

#FIXME: LD_LIBRARY_PATH=${INSTALL_PREFIX}/lib:/usr/local/lib:/usr/lib
# TODO(CK): export LD_LIBRARY_PATH=${X11_BASE_ROOT}/lib:${ACE_ROOT}/lib:/usr/local/lib:/usr/lib
export DYLD_LIBRARY_PATH=${LD_LIBRARY_PATH}
# see https://gitlab.kitware.com/cmake/community/-/wikis/doc/cmake/RPATH-handling

cmake -S . -B ${BUILD_DIR} -G Ninja -D CMAKE_CXX_COMPILER_LAUNCHER=${CCACHE} \
  -D CMAKE_BUILD_TYPE=Release \
  -D CMAKE_SKIP_BUILD_RPATH=OFF \
  -D CMAKE_INSTALL_RPATH=${INSTALL_PREFIX}/lib \
  -D CMAKE_BUILD_WITH_INSTALL_NAME_DIR=OFF \
  -D CMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -D CMAKE_INSTALL_RPATH_USE_LINK_PATH=ON \
  -D CMAKE_STAGING_PREFIX=${STAGE_DIR} \
  -D CMAKE_PREFIX_PATH=${INSTALL_PREFIX} \
  -D CMAKE_CXX_STANDARD=17 \
  -D BUILD_SHARED_LIBS=ON -Wdev -Wdeprecated \
  --fresh

# build example
cmake --build ${BUILD_DIR} --target all

# install example and its runtime dependencies
mkdir -p ${STAGE_DIR}/lib

# NOTE: Not used! cmake --build ${BUILD_DIR} --target install
# # cleanup
# rm -rf ${STAGE_DIR}/lib/pkgconfig
# rm -rf ${STAGE_DIR}/bin/fuzzers
# rm -rf ${STAGE_DIR}/bin/*.bat

# path to gnu-tar needed for Darwin
export PATH="/usr/local/opt/llvm/bin:/usr/local/opt/gnu-tar/libexec/gnubin:${PATH}"
pushd ${BUILD_DIR} && cpack -G TGZ
tar -C ${STAGE_DIR} -xzvf ${PWD}/itaox11-*.tar.gz --strip-components=1 \
    --exclude="*.a" --exclude="*.bat" --exclude=fuzzers --exclude=pkgconfig
popd

# cleanup dead symlinks
symlinks -rvd ${STAGE_DIR}/lib

# rpath needed for Darwin
for f in ${STAGE_DIR}/bin/*
do
    install_name_tool -add_rpath @executable_path/../lib $f || echo ignored
done

# check that all needed libs are installed:
export LD_LIBRARY_PATH=${STAGE_DIR}/lib:/usr/local/lib:/usr/lib
export DYLD_LIBRARY_PATH=${LD_LIBRARY_PATH}
if [[ -x "${STAGE_DIR}/bin/consumer" ]]; then
  ldd ${STAGE_DIR}/bin/consumer || objdump --dylibs-used --macho ${STAGE_DIR}/bin/consumer
fi
find ${STAGE_DIR}/lib -name 'lib*.so*' -o -name 'lib*.dylib' | egrep -v '(taox11|TAO|ACE)' | xargs ls -l

# test installed example
export PATH="${STAGE_DIR}/bin:${PATH}"
#NO! pushd ${STAGE_DIR}/bin && ./run_test.pl -s -debug
pushd ${BUILD_DIR} && ctest --output-on-failure

# path needed for Linux
export PATH="/usr/lib/llvm-17/bin:${PATH}"
pushd ${BUILD_DIR} && run-clang-tidy -checks='-*,bugprone-*,-bugprone-reserved-identifier,hicpp-*,-hicpp-avoid-c-arrays,-hicpp-exception-baseclass,-hicpp-no-array-decay,-hicpp-braces-around-statements' || echo ignored
