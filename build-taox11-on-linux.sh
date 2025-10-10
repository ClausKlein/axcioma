#!/bin/bash
#
# adapted from:
# https://github.com/RemedyIT/axcioma/blob/master/.github/workflows/linux.yml
#

set -e
set -u

export LANG=C
export CC=${CC:-gcc-13}
export CXX=${CXX:-g++-13}

source .envrc

# TODO(CK): force to build only taox11!
rm -rf "${INSTALL_PREFIX}"
rm -rf ciaox11 dancex11
rm -f ./*.log
find . -type d -name .shobj | xargs rm -rf

set -x

# see etc/brix11rc
# and brix11/lib/brix11/brix/common/cmds/bootstrap.rb
"${X11_BASE_ROOT}/bin/brix11" bootstrap taox11
"${X11_BASE_ROOT}/bin/brix11" configure -W aceroot="${ACE_ROOT}" -W taoroot="${TAO_ROOT}" -W mpcroot="${MPC_ROOT}"

# patch $ACE_ROOT/include/makeinclude/platform_macros.GNU
# includes $ACE_ROOT/include/makeinclude/platform_linux.GNU
# includes $ACE_ROOT/include/makeinclude/platform_g++_common.GNU
# includes $ACE_ROOT/include/makeinclude/platform_clang_common.GNU
# includes $ACE_ROOT/include/makeinclude/platform_linux_common.GNU
echo "c++std=c++20" >> ${ACE_ROOT}/include/makeinclude/platform_macros.GNU

# Print brix11 configuration
"${X11_BASE_ROOT}/bin/brix11" --version
"${X11_BASE_ROOT}/bin/brix11" env -- configure -P 2>&1 | tee configure.log

############################################################
# gen GNUmakefile from workspace.mwc
# see taox11/tao/x11/taox11.mpc
# and ACE/ACE/ace/ace_for_tao.mpc
"${X11_BASE_ROOT}/bin/brix11" gen build workspace.mwc -- gen build "${TAOX11_ROOT}/examples" -- gen build "${TAOX11_ROOT}/orbsvcs/tests" -- gen build "${TAOX11_ROOT}/tests"
############################################################

# make all
make c++20=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${X11_BASE_ROOT}" 2>&1 | tee make-all.log
make c++20=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${TAOX11_ROOT}/orbsvcs/tests" 2>&1 | tee -a make-all.log
make c++20=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${TAOX11_ROOT}/examples" 2>&1 | tee -a make-all.log
make c++20=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${TAOX11_ROOT}/tests" 2>&1 | tee -a make-all.log

# TODO(CK): run tests, but only on WSL2 without windows firerwall!
# taox11/bin/taox11_tests.lst
# ACE/ACE/bin/ace_tests.lst
# ACE/ACE/tests/run_test.lst
# ACE/TAO/bin/tao_other_tests.lst
# ACE/TAO/bin/tao_orb_tests.lst
# NO! "${X11_BASE_ROOT}/bin/brix11" run list -l taox11/bin/taox11_tests.lst -r taox11 2>&1 | tee run-list.log

# FIXME: install is only partly usable! CK
# make -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${X11_BASE_ROOT}" install 2>&1 | tee make-install.log
#
# # NOTE: remove the installed garbage from include directory tree! CK
# rm -rf "${INSTALL_PREFIX}/include"

export PATH="$X11_BASE_ROOT/bin:$X11_BASE_ROOT/lib:$TAOX11_ROOT/bin:$ACE_ROOT/bin:$ACE_ROOT/lib:$PATH"
export LD_LIBRARY_PATH="${X11_BASE_ROOT}/lib:${ACE_ROOT}/lib:/usr/local/lib:/usr/lib"

(type cmake && type ninja) || (python -m pip install -r requirements.txt && builddriver cat make-all.log)

bin/brix11 execute cmake -B build -S . -G Ninja \
  -D CMAKE_BUILD_TYPE=Release \
  -D CMAKE_SKIP_BUILD_RPATH=OFF \
  -D CMAKE_INSTALL_RPATH=${INSTALL_PREFIX}/lib \
  -D CMAKE_BUILD_WITH_INSTALL_NAME_DIR=OFF \
  -D CMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -D CMAKE_INSTALL_RPATH_USE_LINK_PATH=ON \
  -D CMAKE_STAGING_PREFIX=${INSTALL_PREFIX} \
  -D CMAKE_PREFIX_PATH=${INSTALL_PREFIX} \
  -D CMAKE_CXX_STANDARD=20 \
  -D BUILD_SHARED_LIBS=OFF -Wdev -Wdeprecated \
  --fresh

bin/brix11 execute cmake --build build --target all
bin/brix11 execute cmake --install build --prefix ${INSTALL_PREFIX}

# check that all needed libs are installed:
export LD_LIBRARY_PATH="${INSTALL_PREFIX}/lib:/usr/local/lib:/usr/lib"
export PATH="${INSTALL_PREFIX}/bin:${PATH}"
bin/brix11 execute ctest --test-dir build --output-on-failure

bin/brix11 execute cmake --build build --target package

exit 0
