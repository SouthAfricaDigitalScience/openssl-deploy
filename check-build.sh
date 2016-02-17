#!/bin/bash -e
# Check build script for Open SSL.
. /etc/profile.d/modules.sh
module load ci
cd ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}
make test
make install

echo $?

make test
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
setenv       OPENSSL_DIR           /apprepo/$::env(SITE)/$::env(OS)/$::env(ARCH)/$NAME/$VERSION
prepend-path LD_LIBRARY_PATH   $::env(OPENSSL_DIR)/lib
prepend-path PATH              $::env(OPENSSL_DIR)
prepend-path LDFLAGS           "-L${OPENSSL_DIR}/lib"

MODULE_FILE
) > modules/$VERSION

mkdir -p ${LIBRARIES_MODULES}/${NAME}
cp modules/$VERSION ${LIBRARIES_MODULES}/${NAME}

# check the module
module avail ${NAME}
which openssl
