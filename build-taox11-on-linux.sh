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

export WORKSPACE=$(realpath ..)
export X11_BASE_ROOT="${WORKSPACE}/axcioma"
export INSTALL_PREFIX="${X11_BASE_ROOT}/stage"
rm -rf "${INSTALL_PREFIX}"

source .env_add.sh

set -x

export BRIX11_VERBOSE=1
export BRIX11_NUMBER_OF_PROCESSORS=6

# TODO: force to build only taox11! CK
rm -rf ciaox11 dancex11
rm -f ./*.log

"${X11_BASE_ROOT}/bin/brix11" bootstrap taox11 || echo ignored

############################################################
# patch to build ACE with -std=c++17
cd "${ACE_ROOT}" && git stash && patch -N -p2 -i ../../ACE_Auto_Ptr.patch
cd "${TAOX11_ROOT}" && git stash && patch -N -p2 -i ../taox11-system_exception.patch
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
"${X11_BASE_ROOT}/bin/brix11" gen build workspace.mwc -- gen build "${TAOX11_ROOT}/examples" -- gen build "${TAOX11_ROOT}/orbsvcs/tests" -- gen build "${TAOX11_ROOT}/tests"
############################################################

# ACE/ACE/ace/config.h
# patch to build ACE with -std=c++20
echo '#define throw() noexcept' >> ${ACE_ROOT}/ace/config.h

#NO! "${X11_BASE_ROOT}/bin/brix11" make -N -d ${X11_BASE_ROOT} -- make -N -d ${TAOX11_ROOT}/examples -- make -N -d ${TAOX11_ROOT}/orbsvcs/tests -- make -N -d ${TAOX11_ROOT}/tests 2>&1 | tee make-all.log

# make all
make c++17=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${X11_BASE_ROOT}" 2>&1 | tee make-all.log
make c++17=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${TAOX11_ROOT}/orbsvcs/tests" 2>&1 | tee -a make-all.log
make c++17=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${TAOX11_ROOT}/examples" 2>&1 | tee -a make-all.log
make c++17=1 -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${TAOX11_ROOT}/tests" 2>&1 | tee -a make-all.log

#TODO: workaround to prevent problems with WSL and windows firewall! CK
#XXX grep -E "^127.0.1.1\s+$HOSTNAME" /etc/hosts && echo "change to 127.0.0.1!" && exit 1

# make tests
"${X11_BASE_ROOT}/bin/brix11" run list -l taox11/bin/taox11_tests.lst -r taox11 2>&1 | tee run-list.log

# install
#XXX make -j ${BRIX11_NUMBER_OF_PROCESSORS} -C "${X11_BASE_ROOT}" install 2>&1 | tee make-install.log

#XXX find "${INSTALL_PREFIX}/include" -type d -name home -prune -print0 | xargs -0 tree
#XXX find "${INSTALL_PREFIX}/include" -type d -name home -prune -print0 | xargs -0 rm -rf

#FIXME: remove the installed include garbage! CK
#XXX rm -rf "${INSTALL_PREFIX}/include"

exit 0
