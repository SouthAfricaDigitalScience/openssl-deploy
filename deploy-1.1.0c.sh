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

# Deploy script for openssl.
. /etc/profile.d/modules.sh
echo ${SOFT_DIR}
module add deploy
echo ${SOFT_DIR}
cd ${WORKSPACE}/${NAME}-${VERSION}
make clean
echo "All tests have passed, will now build into ${SOFT_DIR}"
./config \
--prefix=${SOFT_DIR} \
--shared
make depend
make -j2
touch libcrypto.so.1.1.a
touch libssl.so.1.1.a
make -i install

echo "Creating the modules file directory ${LIBRARIES}"
mkdir -p ${LIBRARIES}/${NAME}
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
setenv       OPENSSL_DIR           $::env(CVMFS_DIR)/$::env(SITE)/$::env(OS)/$::env(ARCH)/$NAME/$VERSION
prepend-path LD_LIBRARY_PATH       $::env(OPENSSL_DIR)/lib
prepend-path PATH                  $::env(OPENSSL_DIR)/bin
prepend-path LDFLAGS               "-L$::env(OPENSSL_DIR)/lib"
prepend-path CFLAGS                "-I$::env(OPENSSL_DIR)/include"
MODULE_FILE
) > ${LIBRARIES}/${NAME}/${VERSION}

# test the module
module avail ${NAME}
which openssl
echo "adding module"
module add ${NAME}/${VERSION}
which openssl
find ${OPENSSL_DIR}/lib -name "libssl.so*"

echo "getting sample code"
wget http://fm4dd.com/openssl/source/sslconnect.c
gcc -o sslconnect sslconnect.c -L${OPENSSL_DIR}/lib -I${OPENSSL_DIR}/include  -lssl -lcrypto
./sslconnect
