
# Asterisk *for semasim*

This is a fork of Asterisk 14.5 that enable
path sip header when dialing specific contact  
with pjsip channel driver.

It is the version of asterisk bundled with Semasim.

## Build, bundle and publishing

### Prepare host

* PUTASSET_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx need to be defined.
  It must be github oAuth token that let upload release asset file to garrone/assets.
* Need to be compiled on debian jessie.  
* gcc-4.9 need to be installed ( apt-get install )  
  Be sure that gcc is as simlink to gcc-4.9
* Make sure ``$AST_INSTALL_PATH`` does not exsist.  
  ( should be /usr/share/asterisk_semasim )

### run the script

Run  
```bash
sudo su
./build_bundle_and_release.sh
```

## Usage

The tarball is automatically downloaded and bundled to semasim_gateway.  
The package that must be installed on the client in order to run the build
are detailed in the ``build_bundle_and_release.sh`` script.

