#!/bin/sh
CC=gcc-4.0
APPBUNDLE=rtcwcoop.app
BINARY=rtcwcoop.ub
DEDBIN=rtcwcoopded.ub
PKGINFO=APPLCOOP
ICNS=misc/rtcwcoop.icns
DESTDIR=build/release-darwin-ub
BASEDIR=coopmain

BIN_OBJ="
	build/release-darwin-x86_64/rtcwcoop.x86_64
	build/release-darwin-x86/rtcwcoop.x86
	build/release-darwin-ppc/rtcwcoop.ppc
"
BIN_DEDOBJ="
	build/release-darwin-x86_64/rtcwcoopded.x86_64
	build/release-darwin-x86/rtcwcoopded.x86
	build/release-darwin-ppc/rtcwcoopded.ppc
"
BASE_OBJ="
	build/release-darwin-x86_64/$BASEDIR/cgame.coop.x86_64.dylib
	build/release-darwin-x86/$BASEDIR/cgame.coop.i386.dylib
	build/release-darwin-ppc/$BASEDIR/cgame.coop.ppc.dylib
	build/release-darwin-x86_64/$BASEDIR/ui.coop.x86_64.dylib
	build/release-darwin-x86/$BASEDIR/ui.coop.i386.dylib
	build/release-darwin-ppc/$BASEDIR/ui.coop.ppc.dylib
	build/release-darwin-x86_64/$BASEDIR/qagame.coop.x86_64.dylib
	build/release-darwin-x86/$BASEDIR/qagame.coop.i386.dylib
	build/release-darwin-ppc/$BASEDIR/qagame.coop.ppc.dylib
"
RENDER_OBJ="
	build/release-darwin-x86_64/renderer_coop_opengl1_x86_64.dylib
	build/release-darwin-x86/renderer_coop_opengl1_i386.dylib
	build/release-darwin-ppc/renderer_coop_opengl1_ppc.dylib
	build/release-darwin-x86_64/renderer_coop_rend2_x86_64.dylib
	build/release-darwin-x86/renderer_coop_rend2_i386.dylib
	build/release-darwin-ppc/renderer_coop_rend2_ppc.dylib
"

cd `dirname $0`
if [ ! -f Makefile ]; then
	echo "This script must be run from the rtcwcoop build directory"
	exit 1
fi

Q3_VERSION=`grep '^VERSION=' Makefile | sed -e 's/.*=\(.*\)/\1/'`

# we want to use the oldest available SDK for max compatiblity. However 10.4 and older
# can not build 64bit binaries, making 10.5 the minimum version.   This has been tested 
# with xcode 3.1 (xcode31_2199_developerdvd.dmg).  It contains the 10.5 SDK and a decent
# enough gcc to actually compile rtcwcoop
# For PPC macs, G4's or better are required to run rtcwcoop.

unset X86_64_SDK
unset X86_64_CFLAGS
unset X86_SDK
unset X86_CFLAGS
unset PPC_SDK
unset PPC_CFLAGS

if [ -d /Developer/SDKs/MacOSX10.5.sdk ]; then
	PPC_SDK=/Developer/SDKs/MacOSX10.5.sdk
	PPC_CFLAGS="-arch ppc -isysroot /Developer/SDKs/MacOSX10.5.sdk"
fi

if [ -d /Developer/SDKs/MacOSX10.6.sdk ]; then
	X86_64_SDK=/Developer/SDKs/MacOSX10.6.sdk
	X86_64_CFLAGS="-arch x86_64 -isysroot /Developer/SDKs/MacOSX10.6.sdk"

	X86_SDK=/Developer/SDKs/MacOSX10.6.sdk
	X86_CFLAGS="-arch i386 -isysroot /Developer/SDKs/MacOSX10.6.sdk"
fi

if [ -z $X86_64_SDK ] || [ -z $X86_SDK ] || [ -z $PPC_SDK ]; then
       echo "\
ERROR: This script is for building a Universal Binary.  You cannot build
       for a different architecture unless you have the proper Mac OS X SDKs
       installed.  If you just want to to compile for your own system run
       'make-macosx.sh' instead of this script.

       In order to build a binary with maximum compatibility you must
       build on Mac OS X 10.6 and have the MacOSX10.5 and MacOSX10.6
       SDKs installed from the Xcode install disk Packages folder."
       exit 1
fi

echo "Building X86_64 Client against \"$X86_64_SDK\""
echo "Building X86 Client against \"$X86_SDK\""
echo "Building PPC Client against \"$PPC_SDK\""
echo

if [ ! -d $DESTDIR ]; then
	mkdir -p $DESTDIR
fi

# For parallel make on multicore boxes...
NCPU=`sysctl -n hw.ncpu`

# x86_64 client
if [ -d build/release-release-x86_64 ]; then
	rm -r build/release-darwin-x86_64
fi
(ARCH=x86_64 CC=gcc-4.0 CFLAGS=$X86_64_CFLAGS make -j$NCPU) || exit 1;

echo;echo

# x86 client
if [ -d build/release-darwin-x86 ]; then
	rm -r build/release-darwin-x86
fi
(ARCH=x86 CC=gcc-4.0 CFLAGS=$X86_CFLAGS make -j$NCPU) || exit 1;

echo;echo

# PPC client
if [ -d build/release-darwin-ppc ]; then
	rm -r build/release-darwin-ppc
fi
(ARCH=ppc CC=gcc-4.0 CFLAGS=$PPC_CFLAGS make -j$NCPU) || exit 1;

echo;echo

echo "Creating .app bundle $DESTDIR/$APPBUNDLE"
if [ ! -d $DESTDIR/$APPBUNDLE/Contents/MacOS/$BASEDIR ]; then
	mkdir -p $DESTDIR/$APPBUNDLE/Contents/MacOS/$BASEDIR || exit 1;
fi
if [ ! -d $DESTDIR/$APPBUNDLE/Contents/Resources ]; then
	mkdir -p $DESTDIR/$APPBUNDLE/Contents/Resources
fi
cp $ICNS $DESTDIR/$APPBUNDLE/Contents/Resources/rtcwcoop.icns || exit 1;
echo $PKGINFO > $DESTDIR/$APPBUNDLE/Contents/PkgInfo
echo "
	<?xml version=\"1.0\" encoding=\"UTF-8\"?>
	<!DOCTYPE plist
		PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\"
		\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
	<plist version=\"1.0\">
	<dict>
		<key>LSMinimumSystemVersion</key>
		<string>10.5.0</string>
		<key>LSMinimumSystemVersionByArchitecture</key>
		<dict>
			<key>i386</key>
			<string>10.6.0</string>
			<key>x86_64</key>
			<string>10.6.0</string>
		</dict>
		<key>CFBundleDevelopmentRegion</key>
		<string>English</string>
		<key>CFBundleExecutable</key>
		<string>$BINARY</string>
		<key>CFBundleGetInfoString</key>
		<string>rtcwcoop $Q3_VERSION</string>
		<key>CFBundleIconFile</key>
		<string>rtcwcoop.icns</string>
		<key>CFBundleIdentifier</key>
		<string>com.rtcwcoop.www</string>
		<key>CFBundleInfoDictionaryVersion</key>
		<string>6.0</string>
		<key>CFBundleName</key>
		<string>rtcwcoop</string>
		<key>CFBundlePackageType</key>
		<string>APPL</string>
		<key>CFBundleShortVersionString</key>
		<string>$Q3_VERSION</string>
		<key>CFBundleSignature</key>
		<string>$PKGINFO</string>
		<key>CFBundleVersion</key>
		<string>$Q3_VERSION</string>
		<key>NSExtensions</key>
		<dict/>
		<key>NSPrincipalClass</key>
		<string>NSApplication</string>
	</dict>
	</plist>
	" > $DESTDIR/$APPBUNDLE/Contents/Info.plist


# Make UB's from previous builds of x86, x86_64 and ppc binaries
lipo -create -o $DESTDIR/$APPBUNDLE/Contents/MacOS/$BINARY $BIN_OBJ
lipo -create -o $DESTDIR/$APPBUNDLE/Contents/MacOS/$DEDBIN $BIN_DEDOBJ

cp $RENDER_OBJ $DESTDIR/$APPBUNDLE/Contents/MacOS/
cp $BASE_OBJ $DESTDIR/$APPBUNDLE/Contents/MacOS/$BASEDIR/
cp code/libs/macosx/*.dylib $DESTDIR/$APPBUNDLE/Contents/MacOS/

