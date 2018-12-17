#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script require root privileges."
    exit 1
fi

ROOT_DIRECTORY=$(pwd)
WORKING_DIRECTORY=$ROOT_DIRECTORY/working_directory
AST_INSTALL_PATH=/usr/share/asterisk_semasim

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
# libssl-dev -> (stretch and newer) libssl1.0.2, (jessie) libssl1.0.0 (from jessie backport)
apt-get install -y uuid-dev libjansson-dev libxml2-dev libsqlite3-dev unixodbc-dev libsrtp0-dev
apt-get install -y --force-yes libssl-dev -t jessie-backports

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

tar -czf $ROOT_DIRECTORY/docs/asterisk_$(uname -m).tar.gz -C $WORKING_DIRECTORY .

echo "DONE"

