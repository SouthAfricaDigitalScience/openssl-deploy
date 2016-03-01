#!/bin/bash -e
# Deploy script for openssl.
. /etc/profile.d/modules.sh
echo ${SOFT_DIR}
module add deploy
echo ${SOFT_DIR}
cd ${WORKSPACE}/${NAME}-${VERSION}/
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

echo "Creating the modules file directory ${LIBRARIES_MODULES}"
mkdir -p ${LIBRARIES_MODULES}/${NAME}
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
) > ${LIBRARIES_MODULES}/${NAME}/${VERSION}

# test the module
module avail ${NAME}
which openssl
echo "adding module"
module add ${NAME}/${VERSION}
which openssl

echo "getting sample code"
wget http://fm4dd.com/openssl/source/sslconnect.c
echo "trying to compile sample application"
echo "CFLAGS  : $CFLAGS"
echo "LDFLAGS : $LDFLAGS"
export ${CFLAGS} ${LDFLAGS}
gcc -lssl -lcrypto -o sslconnect sslconnect.c
./sslconnect
