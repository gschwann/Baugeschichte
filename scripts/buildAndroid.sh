#!/bin/sh

QT_DIR=/opt/Qt/5.14.2
PLATFORM=android-29

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

VERSION=`awk /^VERSION/ src/src.pro | sed s/VERSION=//g`

SIGN_OPTIONS=
ANDROID_KEYSTORE=$SOURCE_DIR/GrazWikiKeyStore.jks
if [ -f "$ANDROID_KEYSTORE" ]; then 
    SIGN_OPTIONS="--sign $ANDROID_KEYSTORE grazwiki"
else
    ANDROID_KEYSTORE=$SOURCE_DIR/../GrazWikiKeyStore.jks
    if [ -f "$ANDROID_KEYSTORE" ]; then 
        SIGN_OPTIONS="--sign $ANDROID_KEYSTORE grazwiki"
    fi
fi

# Google keystore password - saved in Gitlab CI settings
if [ ! -z "$SIGN_OPTIONS" ]; then
    if [ ! -z "$GRAZWIKI_PASSWORD" ]; then
        SIGN_OPTIONS="$SIGN_OPTIONS --storepass $GRAZWIKI_PASSWORD"
    fi
fi

SIGN_STATUS="unsigned"
if [ ! -z "$SIGN_OPTIONS" ]; then
    SIGN_STATUS="google_signed"
fi
TIMESTAMP=`date +%Y%m%d`

# setup some enviroment variables
export ANDROID_NDK_HOST=linux-x86_64
export ANDROID_HOME=$ANDROID_SDK_ROOT
export JAVA_HOME=$JDK


BUILD_DIR=$BUILD_BASE
ANDROID_BUILD_DIR=$BUILD_DIR/android-build
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
mkdir -p $TARGET_DIR
cd $BUILD_BASE

# Run QMake
QMAKE_BIN=$QT_DIR/android/bin/qmake
$QMAKE_BIN $SOURCE_DIR/src/src.pro -o Makefile -spec android-clang CONFIG+=qtquickcompiler 'ANDROID_ABIS=armeabi-v7a arm64-v8a'
 
# Run Make
MAKE=$ANDROID_NDK_ROOT/prebuilt/linux-x86_64/bin/make
$MAKE -f Makefile
#$MAKE -f Makefile.Armeabi-v7a all
#$MAKE -f Makefile.Arm64-v8a all

# Install (to prepare package build)
$MAKE INSTALL_ROOT=$ANDROID_BUILD_DIR -f Makefile install

# Create package
DEPLOY_TOOL=$QT_DIR/android/bin/androiddeployqt
SETTING=$BUILD_DIR/android-Baugeschichte-deployment-settings.json
$DEPLOY_TOOL --input $SETTING --output $ANDROID_BUILD_DIR --android-platform $PLATFORM --jdk $JDK --gradle --aab --release $SIGN_OPTIONS
echo "$DEPLOY_TOOL --input $SETTING --output $ANDROID_BUILD_DIR --android-platform $PLATFORM --jdk $JDK --gradle --aab --release $SIGN_OPTIONS"
 
# Copy file
APK=$BUILD_DIR/android-build/build/outputs/apk/release/android-build-release-unsigned.apk
if [ ! -z "$SIGN_OPTIONS" ]; then
   APK=$BUILD_DIR/android-build/build/outputs/apk/release/android-build-release-signed.apk
fi
APK_DESTINATION=$TARGET_DIR/Baugeschichte_$VERSION-$SIGN_STATUS\_android_$TIMESTAMP.apk
echo ">> cp $APK $APK_DESTINATION"
cp $APK $APK_DESTINATION

AAB=$BUILD_DIR/android-build/build/outputs/bundle/release/android-build-release.aab
AAB_DESTINATION=$TARGET_DIR/Baugeschichte_$VERSION-$SIGN_STATUS\_android_$TIMESTAMP.aab
echo ">> cp $AAB $AAB_DESTINATION"
cp $AAB $AAB_DESTINATION

echo " "
echo "Copied result to $APK_DESTINATION"
echo "Copied result to $AAB_DESTINATION"
echo " "
 
exit 0
