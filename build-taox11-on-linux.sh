#!/bin/bash
#
# adapted from:
# https://github.com/RemedyIT/axcioma/blob/master/.github/workflows/linux.yml
#

set -e
set -u

export LANG=C
export CC=${CC:-clang}
export CXX=${CXX:=-clang++}

export WORKSPACE=$(realpath .)
export X11_BASE_ROOT="${WORKSPACE}"
export INSTALL_PREFIX="${X11_BASE_ROOT}/stagedir"

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
echo "c++std=c++17" >> ${ACE_ROOT}/include/makeinclude/platform_macros.GNU

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
make c++17=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${X11_BASE_ROOT}" 2>&1 | tee make-all.log
make c++17=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${TAOX11_ROOT}/orbsvcs/tests" 2>&1 | tee -a make-all.log
make c++17=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${TAOX11_ROOT}/examples" 2>&1 | tee -a make-all.log
make c++17=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${TAOX11_ROOT}/tests" 2>&1 | tee -a make-all.log

# TODO(CK): run tests, but only on WSL2 without windows firerwall!
# taox11/bin/taox11_tests.lst
# ACE/ACE/bin/ace_tests.lst
# ACE/ACE/tests/run_test.lst
# ACE/TAO/bin/tao_other_tests.lst
# ACE/TAO/bin/tao_orb_tests.lst
# NO! "${X11_BASE_ROOT}/bin/brix11" run list -l taox11/bin/taox11_tests.lst -r taox11 2>&1 | tee run-list.log

# FIXME: install is only partly usable!
make -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${X11_BASE_ROOT}" install 2>&1 | tee make-install.log

# NOTE: remove the installed garbage from include directory tree! CK
rm -rf "${INSTALL_PREFIX}/include"

./.install.sh

exit 0
