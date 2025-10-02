#!/bin/bash
#
# adapted from:
# https://github.com/RemedyIT/axcioma/blob/master/.github/workflows/linux.yml
#

set -e
set -u

export LANG=C
export CC=gcc-15
export CXX=g++-15

export WORKSPACE=$(realpath .)
export X11_BASE_ROOT="${WORKSPACE}"
export INSTALL_PREFIX="${X11_BASE_ROOT}/stagedir"

source .envrc

export LLVM_PREFIX=`brew --prefix llvm@21`
export LLVM_ROOT=`realpath ${LLVM_PREFIX}`
# for clang-tools
export PATH=${LLVM_ROOT}/bin:${PATH}
export PATH="/usr/local/Cellar/ruby/3.4.6/bin:$PATH"

# XXX export CXX=${LLVM_ROOT}/bin/clang++
# XXX export CC=${LLVM_ROOT}/bin/clang
# XXX export LDFLAGS="-L${LLVM_ROOT}/lib/c++ -lc++abi -lc++"


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

# Print brix11 configuration
"${X11_BASE_ROOT}/bin/brix11" --version
"${X11_BASE_ROOT}/bin/brix11" env -- configure -P 2>&1 | tee configure.log

############################################################
# gen GNUmakefile from workspace.mwc
# see taox11/tao/x11/taox11.mpc
# and ACE/ACE/ace/ace_for_tao.mpc
# FIXME: "${X11_BASE_ROOT}/bin/brix11" gen build workspace.mwc -- gen build ${TAOX11_ROOT}/examples -- gen build ${TAOX11_ROOT}/orbsvcs/tests -- gen build ${TAOX11_ROOT}/tests
############################################################

# TODO(CK): quickfixes for OSX
# ACE/ACE/include/makeinclude/platform_gcc_clang_common.GNU
# ACE/ACE/include/makeinclude/platform_g++_common.GNU
# ACE/ACE/include/makeinclude/platform_clang_common.GNU
# ACE/ACE/include/makeinclude/platform_macosx_common.GNU
# ACE/ACE/include/makeinclude/platform_macosx.GNU
platform_file='include $(ACE_ROOT)/include/makeinclude/platform_macosx.GNU'

# create $ACE_ROOT/ace/config.h
# ACE/ACE/ace/config.h
# ACE/ACE/ace/config-macosx.h
# ACE/ACE/ace/config-macosx-mojave.h
# ACE/ACE/ace/config-macosx-highsierra.h
# ACE/ACE/ace/config-macosx-sierra.h
# ACE/ACE/ace/config-macosx-elcapitan.h
# ACE/ACE/ace/config-macosx-yosemite.h
# ACE/ACE/ace/config-macosx-mavericks.h
# ACE/ACE/ace/config-macosx-mountainlion.h
# ACE/ACE/ace/config-macosx-lion.h
# ACE/ACE/ace/config-macosx-leopard.h
echo '#include "ace/config-macosx.h"' > "${ACE_ROOT}/ace/config.h"

# create ACE/ACE/include/makeinclude/platform_macros.GNU
echo "c++std=c++17" > ${ACE_ROOT}/include/makeinclude/platform_macros.GNU
echo ${platform_file} >> ${ACE_ROOT}/include/makeinclude/platform_macros.GNU

# ACE/ACE/bin/MakeProjectCreator/config/default.features
# Create $ACE_ROOT/bin/MakeProjectCreator/config/default.features
echo 'ipv6=1' > ${ACE_ROOT}/bin/MakeProjectCreator/config/default.features
echo 'versioned_namespace=1' >> ${ACE_ROOT}/bin/MakeProjectCreator/config/default.features
#XXX echo 'acetaompc=1' >> "${ACE_ROOT}/bin/MakeProjectCreator/config/default.features"
#XXX echo 'inline=1' >> "${ACE_ROOT}/bin/MakeProjectCreator/config/default.features"
#XXX echo 'optimize=1' >> "${ACE_ROOT}/bin/MakeProjectCreator/config/default.features"

# generate all GNUmakefile's
# see workspace.mwc
perl "${TAOX11_ROOT}/bin/mwc.pl" -type gnuace "${X11_BASE_ROOT}/workspace.mwc" -workers ${BRIX11_NUMBER_OF_PROCESSORS}
perl "${TAOX11_ROOT}/bin/mwc.pl" -type gnuace "${TAOX11_ROOT}/examples" -workers ${BRIX11_NUMBER_OF_PROCESSORS}
perl "${TAOX11_ROOT}/bin/mwc.pl" -type gnuace "${TAOX11_ROOT}/tests" -workers ${BRIX11_NUMBER_OF_PROCESSORS}
perl "${TAOX11_ROOT}/bin/mwc.pl" -type gnuace "${TAOX11_ROOT}/orbsvcs/tests" -workers ${BRIX11_NUMBER_OF_PROCESSORS}

# make all
make c++17=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${X11_BASE_ROOT}" 2>&1 | tee make-all.log
#XXX make c++17=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${TAOX11_ROOT}/examples" #XXX 2>&1 | tee -a make-all.log
#XXX make c++17=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${TAOX11_ROOT}/tests" #XXX 2>&1 | tee -a make-all.log
#XXX make c++17=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${TAOX11_ROOT}/orbsvcs/tests" #XXX 2>&1 | tee -a make-all.log

# TODO(CK): run all tests
# taox11/bin/taox11_tests.lst
# ACE/ACE/bin/ace_tests.lst
# ACE/ACE/tests/run_test.lst
# ACE/TAO/bin/tao_other_tests.lst
# ACE/TAO/bin/tao_orb_tests.lst
# FIXME: "${X11_BASE_ROOT}/bin/brix11" run list -l taox11/bin/taox11_tests.lst -r taox11 #XXX 2>&1 | tee run-list.log

# FIXME: install is only partly usable!
make -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${X11_BASE_ROOT}" install 2>&1 | tee make-install.log

# NOTE: remove the installed garbage from include directory tree! CK
rm -rf "${INSTALL_PREFIX}/include"

./.install.sh

exit 0
