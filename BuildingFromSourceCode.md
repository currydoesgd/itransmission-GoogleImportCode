# Building dependencies #

  1. Get build.sh from source repository, e.g. https://raw.github.com/ccp0101/iTransmission/master/make_depend/build.sh
  1. Edit $ARCH in build.sh to either i386 for simulator or armv7 for device
  1. Edit package versions in build.sh
  1. Execute build.sh will automatically fetch required source code, patch and build them
  1. If successfully built, output files will be in $PWD/out, including transmission-daemon and libtransmission.a

# Building iTransmission #

If you built the dependencies yourself, move output directory (e.g.: $PWD/out) to project root and rename it to "libraries"

If you use prebuilt binaries, this has been taken care of.

Then build IPAs in Xcode.