#!/bin/bash

# Need to be run on debian jessie!
# gcc-4.9 need to be installed ( apt-get install )
# Be sure that gcc is as simlink to gcc-4.9
# Make sure $AST_INSTALL_PATH does not exsist.
# Enable jessie-backports repos ( https://backports.debian.org/Instructions/ ) and update

if [[ $EUID -ne 0 ]]; then
    echo "This script require root privileges."
    exit 1
fi

ROOT_DIRECTORY=$(pwd)
WORKING_DIRECTORY=$ROOT_DIRECTORY/working_directory

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

apt-get install -y build-essential autoconf libtool pkg-config

build_speex speexdsp
build_speex speex

# Pour menuselect
apt-get install -y libncurses5-dev

#uuid-dev -> libuuid1
#libjansson4-dev -> libjansson4
#libxml2-dev -> libxml2
#libsqlite3-dev -> libsqlite3-0
apt-get install -y uuid-dev libjansson-dev libxml2-dev libsqlite3-dev

# -> (stretch and newer) libssl1.0.2, (jessie) libssl1.0.0 (from jessie backport)
apt-get install -y libssl-dev -t jessie-backports

apt-get install -y unixodbc-dev
# Pour res_srtp
apt-get install -y libsrtp0-dev

# Pour res_config_sqlite
#apt-get install libsqlite0-dev

AST_INSTALL_PATH=/usr/share/asterisk_semasim

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

tar -czf $ROOT_DIRECTORY/asterisk_$(uname -m).tar.gz -C $WORKING_DIRECTORY .

echo "DONE"

