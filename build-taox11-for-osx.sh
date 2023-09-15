#!/bin/bash
#
# adapted from:
# https://github.com/RemedyIT/axcioma/blob/master/.github/workflows/linux.yml
#

set -e
set -u

export LANG=C
export CC=gcc
export CXX=g++

export WORKSPACE=$(realpath .)
export X11_BASE_ROOT="${WORKSPACE}"
export INSTALL_PREFIX="${X11_BASE_ROOT}/stagedir"

source .env_add.sh

export BRIX11_VERBOSE=1
export BRIX11_NUMBER_OF_PROCESSORS=6

# TODO: force to build only taox11! CK
rm -rf "${INSTALL_PREFIX}"
rm -rf ciaox11 dancex11
rm -f ./*.log

set -x

# see etc/brix11rc
# and brix11/lib/brix11/brix/common/cmds/bootstrap.rb
"${X11_BASE_ROOT}/bin/brix11" bootstrap taox11

############################################################
# patch to build ACE with -std=c++17
#XXX cd "${ACE_ROOT}" && git stash && patch -N -p2 -i ../../ACE_Auto_Ptr.patch
#XXX cd "${TAOX11_ROOT}" && git stash && patch -N -p2 -i ../taox11-system_exception.patch
cd "${X11_BASE_ROOT}"
############################################################

"${X11_BASE_ROOT}/bin/brix11" configure -W aceroot="${ACE_ROOT}" -W taoroot="${TAO_ROOT}" -W mpcroot="${MPC_ROOT}"

# Print brix11 configuration
"${X11_BASE_ROOT}/bin/brix11" --version
"${X11_BASE_ROOT}/bin/brix11" env -- configure -P 2>&1 | tee configure.log

############################################################
# gen GNUmakefile from workspace.mwc
# see taox11/tao/x11/taox11.mpc
# and ACE/ACE/ace/ace_for_tao.mpc
"${X11_BASE_ROOT}/bin/brix11" gen build workspace.mwc -- gen build ${TAOX11_ROOT}/examples -- gen build ${TAOX11_ROOT}/orbsvcs/tests -- gen build ${TAOX11_ROOT}/tests
############################################################

# FIXME: quickfixes for OSX
# ACE/ACE/include/makeinclude/platform_gcc_clang_common.GNU
# ACE/ACE/include/makeinclude/platform_g++_common.GNU
# ACE/ACE/include/makeinclude/platform_clang_common.GNU
# ACE/ACE/include/makeinclude/platform_macosx_common.GNU
# ACE/ACE/include/makeinclude/platform_macosx.GNU
#XXX echo 'include $(ACE_ROOT)/include/makeinclude/platform_macosx.GNU' > "${ACE_ROOT}/include/makeinclude/platform_macros.GNU"

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
#XXX echo '#include "ace/config-macosx.h"' > "${ACE_ROOT}/ace/config.h"

# patch to build ACE with -std=c++20
#TODO echo '#define throw() noexcept' >> "${ACE_ROOT}/ace/config.h"

# ACE/ACE/bin/MakeProjectCreator/config/default.features
#XXX echo 'ipv6=1' > "${ACE_ROOT}/bin/MakeProjectCreator/config/default.features"
#XXX echo 'versioned_namespace=1' >> "${ACE_ROOT}/bin/MakeProjectCreator/config/default.features"
#XXX echo 'acetaompc=1' >> "${ACE_ROOT}/bin/MakeProjectCreator/config/default.features"
#XXX echo 'inline=1' >> "${ACE_ROOT}/bin/MakeProjectCreator/config/default.features"
#XXX echo 'optimize=1' >> "${ACE_ROOT}/bin/MakeProjectCreator/config/default.features"

# generate all GNUmakefile's
# see workspace.mwc
perl "${TAOX11_ROOT}/bin/mwc.pl" -type gnuace "${X11_BASE_ROOT}/workspace.mwc" -workers ${BRIX11_NUMBER_OF_PROCESSORS}
perl "${TAOX11_ROOT}/bin/mwc.pl" -type gnuace "${TAOX11_ROOT}/orbsvcs/tests" -workers ${BRIX11_NUMBER_OF_PROCESSORS}
perl "${TAOX11_ROOT}/bin/mwc.pl" -type gnuace "${TAOX11_ROOT}/examples" -workers ${BRIX11_NUMBER_OF_PROCESSORS}
perl "${TAOX11_ROOT}/bin/mwc.pl" -type gnuace "${TAOX11_ROOT}/tests" -workers ${BRIX11_NUMBER_OF_PROCESSORS}

# make all
make c++17=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${X11_BASE_ROOT}" 2>&1 | tee make-all.log
make c++17=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${TAOX11_ROOT}/orbsvcs/tests" 2>&1 | tee -a make-all.log
make c++17=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${TAOX11_ROOT}/examples" 2>&1 | tee -a make-all.log
make c++17=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${TAOX11_ROOT}/tests" 2>&1 | tee -a make-all.log

# make tests
"${X11_BASE_ROOT}/bin/brix11" run list -l taox11/bin/taox11_tests.lst -r taox11 2>&1 | tee run-list.log

# install
make -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${X11_BASE_ROOT}" install 2>&1 | tee make-install.log

#XXX find "${INSTALL_PREFIX}/include" -type d -name home -prune -print0 | xargs -0 tree
#XXX find "${INSTALL_PREFIX}/include" -type d -name home -prune -print0 | xargs -0 rm -rf

#FIXME: remove the installed include garbage! CK
#XXX rm -rf "${INSTALL_PREFIX}/include"

exit 0
