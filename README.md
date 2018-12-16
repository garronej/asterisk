
# Asterisk *for semasim*

This is a fork of Asterisk 14.5 that enable
path sip header when dialing specific contact  
with pjsip channel driver.

It is the version of asterisk bundled with Semasim.

## Building, bundle and publishing

### Prepare host

* Need to be compiled on debian jessie.  
* gcc-4.9 need to be installed ( apt-get install )  
  Be sure that gcc is as simlink to gcc-4.9
* Make sure ``$AST_INSTALL_PATH`` does not exsist.  
  ( see in bundle.sh what is the value the shell variable )
* Enable jessie-backports repos ( https://backports.debian.org/Instructions/ ) and ``apt-get update``

### Build and bundle

Run  
```bash
sudo ./bundle.sh
```
This will create a file: 

``asterisk_[arch].tar.gz`` in ./docs *arch* beeing the  
current architecture it is beeing compiled against ( ``uname -m`` )  

### Publish

Simply add, the tarball to the repo and commit.


## Usage

The tarball is automatically downloaded and bundled to semasim_gateway.  
The package that must be installed on the client in order to run the build
are detailed in the ``bundle.sh`` script.

