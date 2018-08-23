#!/bin/bash -e
# Copyright 2016 C.S.I.R. Meraka Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Check build script for Open SSL.
. /etc/profile.d/modules.sh
module add ci
cd ${WORKSPACE}/${NAME}-${VERSION}
echo "What are the permissions on cpam"
ls -lht /bin/cpanm
/bin/cpanm --local-lib=~/perl5 Module::Load::Conditional
make test
#  in Issue #4 we noted that some of the variables seem messed up - the install script tries
# to install the development files (target 'install_dev') , but the shared libraries gain a static
# suffix (.so.{VERSION}.a). this is wierd, since the builds complete fine. We are doing something
##### VERY VERY BAD #########
# here, but it doesn't seemw worth the effort to chase this down. Just let make go about it's business
# and ignore errors.

make install

# OpenSSL test needs a couple of  perl  modules, one of which is Test::More. (version 0.96)
# We need to check if this is available and has the right version.
# Refs:
#  * http://stackoverflow.com/questions/1039107/how-can-i-check-if-a-perl-module-is-installed-on-my-system-from-the-command-line
#  * http://www.perlhowto.com/check_if_a_module_is_installed

mkdir -p ${SOFT_DIR}
mkdir -p modules
(
cat <<MODULE_FILE
#%Module1.0
## $NAME modulefile
##
proc ModulesHelp { } {
    puts stderr "       This module does nothing but alert the user"
    puts stderr "       that the [module-info name] module is not available"
}

module-whatis   "$NAME $VERSION."
setenv       OPENSSL_VERSION       $VERSION
setenv       OPENSSL_DIR          /data/ci-build/$::env(SITE)/$::env(OS)/$::env(ARCH)/$NAME/$VERSION
prepend-path LD_LIBRARY_PATH       $::env(OPENSSL_DIR)/lib
prepend-path PATH                  $::env(OPENSSL_DIR)/bin
prepend-path LDFLAGS               "-L$::env(OPENSSL_DIR)/lib"
prepend-path CFLAGS                "-I$::env(OPENSSL_DIR)/include/"

MODULE_FILE
) > modules/$VERSION

mkdir -p ${LIBRARIES}/${NAME}
cp modules/$VERSION ${LIBRARIES}/${NAME}

# check the module
module avail ${NAME}
#which openssl
echo "adding module"
module add ${NAME}/${VERSION}
echo "what is  in ${SOFT_DIR}? "
tree ${SOFT_DIR}

which openssl

echo "getting sample code"
wget http://fm4dd.com/openssl/source/sslconnect.c

echo "trying to compile sample application"
export CFLAGS=${CFLAGS}
export LDFLAGS=${LDFLAGS}
echo "CFLAGS  : $CFLAGS"
echo "LDFLAGS : $LDFLAGS"
gcc -o sslconnect sslconnect.c -L${OPENSSL_DIR}/lib -I${OPENSSL_DIR}/include  -lssl -lcrypto
./sslconnect
