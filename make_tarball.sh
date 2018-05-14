#!/bin/bash

ROOT_DIRECTORY=$(pwd)
WORKING_DIRECTORY=$ROOT_DIRECTORY/working_directory

rm -rf $WORKING_DIRECTORY && mkdir $WORKING_DIRECTORY

function build_speex(){

    SRC_DIR=$WORKING_DIRECTORY/$1_src
    INST_DIR=$WORKING_DIRECTORY/$1

    git clone https://github.com/garronej/$1 $SRC_DIR

    cd $SRC_DIR
    
    ./autogen.sh

    ./configure --prefix=$INST_DIR

    mkdir $INST_DIR

    make

    make install

    cd $WORKING_DIRECTORY && rm -rf $SRC_DIR

}

sudo apt-get update

sudo apt-get install build-essential
sudo apt-get install autoconf
sudo apt-get install libtool

build_speex speexdsp
build_speex speex

sudo apt-get install uuid-dev libjansson-dev libxml2-dev libsqlite3-dev

# Pour menuselect
sudo apt-get install libncurses5-dev
# Pour res_srtp
sudo apt-get install libsrtp0-dev

# Pour res_config_sqlite
#sudo apt-get install libsqlite0-dev

AST_INSTALL_PATH=$WORKING_DIRECTORY/asterisk

cd $ROOT_DIRECTORY

./configure \
        --with-pjproject-bundled \
        --with-speex=$WORKING_DIRECTORY/speex \
        --with-speexdsp=$WORKING_DIRECTORY/speexdsp \
        --prefix=$AST_INSTALL_PATH

make

mkdir $AST_INSTALL_PATH

make install

cp -r contrib $WORKING_DIRECTORY

tar -czf $ROOT_DIRECTORY/asterisk_$(uname -m).tar.gz -C $WORKING_DIRECTORY .

echo "DONE"

