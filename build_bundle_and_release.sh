#!/bin/bash

ROOT_DIRECTORY=$(pwd)
WORKING_DIRECTORY=$ROOT_DIRECTORY/working_directory
AST_INSTALL_PATH=/usr/share/asterisk_semasim

if ! cat /etc/debian_version | grep -e '^8\.'; then
    echo "Must be run on Debian Jessie"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "This script require root privileges."
    exit 1
fi

if [[ -z "${PUTASSET_TOKEN}" ]]; then
    echo "PUTASSET_TOKEN environement variable is not defined, aborting"
    exit 1
fi

if ! [ -x "$(command -v node)" ]; then
  	echo "Error: node is not installed"
  	exit 1
fi

if [ -d "$AST_INSTALL_PATH" ]; then
    echo "$AST_INSTALL_PATH cannot exsist, (uninstall semasim)"
    exit 1
fi

gcc -dumpversion | grep 4.9

if [ $? -ne 0 ]; then
  	echo "Error: gcc should point to gcc-4.9"
  	exit 1
fi


rm -rf $WORKING_DIRECTORY && mkdir $WORKING_DIRECTORY

function build_speex(){

    SRC_DIR=$WORKING_DIRECTORY/$1

    rm -rf $SRC_DIR

    git clone https://github.com/garronej/$1 $SRC_DIR

    cd $SRC_DIR
    
    ./autogen.sh

    mkdir -p $AST_INSTALL_PATH

    ./configure --prefix=$AST_INSTALL_PATH

    make

    make install

}

apt-get update

# Package only nesessary to build, libncurses5-dev is for menuselect.
apt-get install -y build-essential autoconf libtool pkg-config libncurses5-dev

build_speex speexdsp
build_speex speex

# Packages that will also need to be installed on the target host.
# [ dev package needed to build ] -> [ assosiated package needed to run ]
#
# uuid-dev -> libuuid1
# libjansson4-dev -> libjansson4
# libxml2-dev -> libxml2
# libsqlite3-dev -> libsqlite3-0
# unixodbc-dev -> unixodbc
# libsrtp0-dev -> NOTHIN ( libsrtp0  bundled )
# libssl-dev -> NOTHING ( libssl1.0.0 bundled )
# ( libncurses5-dev ? ) -> libtinfo5 ( don't quite understand why it's needed but it is, at least on Buster )
apt-get install -y uuid-dev libjansson-dev libxml2-dev libsqlite3-dev unixodbc-dev libsrtp0-dev libssl-dev

cd $ROOT_DIRECTORY

./configure \
        --with-pjproject-bundled \
        --with-speex=$AST_INSTALL_PATH \
        --with-speexdsp=$AST_INSTALL_PATH \
        --prefix=$AST_INSTALL_PATH

make

rm -rf $AST_INSTALL_PATH

mkdir $AST_INSTALL_PATH

make install


#Including problematic shared libraries

LIBSSL_DEB_FILE_PATH=$WORKING_DIRECTORY/libssl.deb
LIBSRTP_DEB_FILE_PATH=$WORKING_DIRECTORY/libsrtp.deb


if [ "$(uname -m)" = "x86_64" ]; then
        ARCH="amd64"
elif [ "$(uname -m)" = "i686" ]; then
        ARCH="i386"
else
        ARCH="armhf"
if


wget \
        http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u11_"$ARCH".deb \
        > $LIBSSL_DEB_FILE_PATH

wget \
        http://ftp.us.debian.org/debian/pool/main/s/srtp/libsrtp0_1.4.5~20130609~dfsg-1.1+deb8u1_"$ARCH".deb \
        > $LIBSRTP_DEB_FILE_PATH


LIBSSL_UNPACKED_DIR_PATH=$WORKING_DIRECTORY/libssl
LIBSRTP_UNPACKED_DIR_PATH=$WORKING_DIRECTORY/libsrtp

mkdir $LIBSSL_UNPACKED_DIR_PATH
mkdir $LIBSRTP_UNPACKED_DIR_PATH

dpkg-deb -R $LIBSSL_DEB_FILE_PATH $LIBSSL_UNPACKED_DIR_PATH
dpkg-deb -R $LIBSRTP_DEB_FILE_PATH $LIBSRTP_UNPACKED_DIR_PATH

rsync -a $LIBSSL_UNPACKED_DIR_PATH/usr/lib $AST_INSTALL_PATH/lib
rsync -a $LIBSRTP_UNPACKED_DIR_PATH/usr/lib $AST_INSTALL_PATH/lib

mv $AST_INSTALL_PATH $WORKING_DIRECTORY/asterisk



TARBALL_FILE_PATH=$ROOT_DIRECTORY/asterisk_$(uname -m)_$(date +%s).tar.gz

tar -czf $TARBALL_FILE_PATH -C $WORKING_DIRECTORY .

PUTASSET_PATH=$ROOT_DIRECTORY/node-putasset

rm -rf $PUTASSET_PATH

cd $ROOT_DIRECTORY && git clone https://github.com/garronej/node-putasset

cd $PUTASSET_PATH && git checkout 5.0.0 && npm install --production

echo "Start uploading..."

DOWNLOAD_URL=$(node $PUTASSET_PATH/bin/putasset.js -k $PUTASSET_TOKEN -r releases -o garronej -t asterisk -f "$TARBALL_FILE_PATH" --force)

RELEASES_INDEX_FILE_PATH=$ROOT_DIRECTORY/index.json

wget -qO- https://github.com/garronej/releases/releases/download/asterisk/index.json > $RELEASES_INDEX_FILE_PATH

COMMAND=$(cat <<EOF
(function(){
        require("fs").writeFileSync(
            "$RELEASES_INDEX_FILE_PATH",
            JSON.stringify({
              ...require("$RELEASES_INDEX_FILE_PATH"),
              [ "$(uname -m)" ]: "$DOWNLOAD_URL"
            } ,null, 2)
        );
})();
EOF
)

node -e "${COMMAND}"

node $PUTASSET_PATH/bin/putasset.js -k $PUTASSET_TOKEN -r releases -o garronej -t asterisk -f "$RELEASES_INDEX_FILE_PATH" --force

rm -rf $PUTASSET_PATH $TARBALL_FILE_PATH $RELEASES_INDEX_FILE_PATH

echo "DONE"

