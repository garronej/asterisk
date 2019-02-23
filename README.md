
# Asterisk *for semasim*

This is a fork of Asterisk 14.5 that enable
path sip header when dialing specific contact  
with pjsip channel driver.

It is the version of asterisk bundled with Semasim.

## Build, bundle and publishing

### Prepare host

* node must be installed.
* $PUTASSET_TOKEN need to be defined. 
  It must be github oAuth token that let upload release asset file to garrone/assets.
  (find the current one at the bottom of Semasim README ).
* Need to be compiled on debian jessie.  
* gcc-4.9 need to be installed ( apt-get install )  
  Be sure that gcc is a simlink to gcc-4.9
* Make sure ``$AST_INSTALL_PATH``(/usr/share/asterisk_semasim) does not exsist.  

### run the script

Run  
```bash
sudo su
./build_bundle_and_release.sh
```

## Side notes

The package that must be installed on the client in order to run the build
are detailed in the ``build_bundle_and_release.sh`` script.

