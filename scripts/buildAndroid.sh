#!/bin/sh

QT_DIR=/opt/Qt/5.12.4
PLATFORM=android-28
NDK_PLATFORM_32BIT=android-28
NDK_PLATFORM_64BIT=android-28

if [ -z "$ANDROID_NDK_ROOT" ]; then
    echo "Need to set environment variable ANDROID_NDK_ROOT"
    ANDROID_NDK_ROOT=/opt/android/android-ndk
fi
if [ -z "$ANDROID_SDK_ROOT" ]; then
    echo "Need to set environment variable ANDROID_SDK_ROOT"
    ANDROID_SDK_ROOT=/opt/android/android-sdk
fi

SOURCE_DIR=`git rev-parse --show-toplevel`
BUILD_BASE=$SOURCE_DIR/build
TARGET_DIR=$BUILD_BASE/apk

JDK=/usr/lib/jvm/java-8-openjdk-amd64


TIMESTAMP=`date +%Y%m%d`

# setup some enviroment variables
export ANDROID_NDK_HOST=linux-x86_64
export ANDROID_HOME=$ANDROID_SDK_ROOT
export ANDROID_NDK_PLATFORM=$NDK_PLATFORM_32BIT
export JAVA_HOME=$JDK

#
# build ARM 32 bit
#
BUILD_DIR=$BUILD_BASE/arm32
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
mkdir -p $TARGET_DIR
cd $BUILD_DIR

QMAKE=$QT_DIR/android_armv7/bin/qmake
# call qmake
echo ">> $QMAKE -o Makefile $SOURCE_DIR/src/src.pro -spec android-clang CONFIG+=qtquickcompiler"
$QMAKE $SOURCE_DIR/src/src.pro -o Makefile -spec android-clang CONFIG+=qtquickcompiler

MAKE=$ANDROID_NDK_ROOT/prebuilt/linux-x86_64/bin/make
# build & install
echo ">> $MAKE -f Makefile"
$MAKE -f Makefile
echo ">> $MAKE INSTALL_ROOT=$BUILD_DIR/android-build -f Makefile install"
$MAKE INSTALL_ROOT=$BUILD_DIR/android-build -f Makefile install
# create the apk
DEPLOY_TOOL=$QT_DIR/android_armv7/bin/androiddeployqt
SETTING=$BUILD_DIR/android-libBaugeschichte.so-deployment-settings.json
echo ">> $DEPLOY_TOOL --input $SETTING --output $BUILD_DIR/android-build --android-platform $PLATFORM --jdk $JDK --gradle --release"
$DEPLOY_TOOL --input $SETTING --output $BUILD_DIR/android-build --android-platform $PLATFORM --jdk $JDK --gradle --release

# copy file
APK32=$BUILD_DIR/android-build/build/outputs/apk/android-build-release-unsigned.apk
DESTINATION32=$TARGET_DIR/Baugeschichte_signed_arm32_$TIMESTAMP.apk
cp $APK32 $DESTINATION32


#
# build ARM 64 bit
#
export ANDROID_NDK_PLATFORM=$NDK_PLATFORM_64BIT
 
BUILD_DIR=$BUILD_BASE/arm64
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cd $BUILD_DIR

QMAKE=$QT_DIR/android_arm64_v8a/bin/qmake
# call qmake
echo ">> $QMAKE -o Makefile $SOURCE_DIR/src/src.pro -spec android-clang CONFIG+=qtquickcompiler"
$QMAKE -o Makefile $SOURCE_DIR/src/src.pro -spec android-clang CONFIG+=qtquickcompiler
 
MAKE=$ANDROID_NDK_ROOT/prebuilt/linux-x86_64/bin/make
# build & install
echo ">> $MAKE -f Makefile"
$MAKE -f Makefile
echo ">> $MAKE INSTALL_ROOT=$BUILD_DIR/android-build -f Makefile install"
$MAKE INSTALL_ROOT=$BUILD_DIR/android-build -f Makefile install
# create the apk
DEPLOY_TOOL=$QT_DIR/android_arm64_v8a/bin/androiddeployqt
SETTING=$BUILD_DIR/android-libBaugeschichte.so-deployment-settings.json
echo ">> $DEPLOY_TOOL --input $SETTING --output $BUILD_DIR/android-build --android-platform $PLATFORM --jdk $JDK --gradle --release"
$DEPLOY_TOOL --input $SETTING --output $BUILD_DIR/android-build --android-platform $PLATFORM --jdk $JDK --gradle --release

# copy file
APK64=$BUILD_DIR/android-build/build/outputs/apk/android-build-release-unsigned.apk
DESTINATION64=$TARGET_DIR/Baugeschichte_signed_arm64_$TIMESTAMP.apk
cp $APK64 $DESTINATION64


echo " "
echo "Copied result to $DESTINATION32"
echo "Copied result to $DESTINATION64"
echo " "
 
