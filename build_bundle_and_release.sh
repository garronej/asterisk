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

    SRC_DIR=/tmp/$1
    INST_DIR=$WORKING_DIRECTORY/$1

    rm -rf $SRC_DIR

    git clone https://github.com/garronej/$1 $SRC_DIR

    cd $SRC_DIR
    
    ./autogen.sh

    ./configure --prefix=$INST_DIR

    mkdir $INST_DIR

    make

    make install

    cd $WORKING_DIRECTORY && rm -rf $SRC_DIR

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
# libsrtp0-dev -> libsrtp0 
# libssl-dev -> NOTHING ( libssl1.0.0 bundled )
apt-get install -y uuid-dev libjansson-dev libxml2-dev libsqlite3-dev unixodbc-dev libsrtp0-dev libssl-dev

cd $ROOT_DIRECTORY

./configure \
        --with-pjproject-bundled \
        --with-speex=$WORKING_DIRECTORY/speex \
        --with-speexdsp=$WORKING_DIRECTORY/speexdsp \
        --prefix=$AST_INSTALL_PATH

make

rm -rf $AST_INSTALL_PATH

mkdir $AST_INSTALL_PATH

make install

mv $AST_INSTALL_PATH $WORKING_DIRECTORY/asterisk

cp -p $(dpkg -L libssl1.0.0 | grep libssl.so.1.0.0) $(dpkg -L libssl1.0.0 | grep libcrypto.so.1.0.0) $WORKING_DIRECTORY/asterisk/lib/

TARBALL_FILE_PATH=$ROOT_DIRECTORY/asterisk_$(uname -m).tar.gz

tar -czf $TARBALL_FILE_PATH -C $WORKING_DIRECTORY .

PUTASSET_PATH=$ROOT_DIRECTORY/node-putasset

rm -rf $PUTASSET_PATH

cd $ROOT_DIRECTORY && git clone https://github.com/garronej/node-putasset

cd $PUTASSET_PATH && git checkout 5.0.0 && npm install --production

echo "Start uploading..."

DOWNLOAD_URL=$(node $PUTASSET_PATH/bin/putasset.js -k $PUTASSET_TOKEN -r releases -o garronej -t asterisk -f "$TARBALL_FILE_PATH" --force)

rm -rf $PUTASSET_PATH $TARBALL_FILE_PATH

COMMAND=$(cat <<EOF
(function(){

        const path= require("path");

        const releases_file_path= path.join("$ROOT_DIRECTORY", "docs", "releases.json");

        require("fs").writeFileSync(
            releases_file_path,
            JSON.stringify({
              ...require(releases_file_path),
              [ "$(uname -m)" ]: "$DOWNLOAD_URL"
            } ,null, 2)
        );

})();
EOF
)

node -e "${COMMAND}"

echo "DONE"

