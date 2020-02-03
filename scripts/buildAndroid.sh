#!/bin/sh

QT_DIR=/opt/Qt/5.14.1
PLATFORM=android-28

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

runQmake() {
    QMAKE_BIN=$1
    echo ">> $QMAKE_BIN -o Makefile $SOURCE_DIR/src/src.pro -spec android-clang CONFIG+=qtquickcompiler $2"
    $QMAKE_BIN $SOURCE_DIR/src/src.pro -o Makefile -spec android-clang CONFIG+=qtquickcompiler $2
    if [ $? -ne 0 ]; then
    echo "Error building Baugeschichte"
    exit 1
    fi
}

runMake() {
    MAKE=$ANDROID_NDK_ROOT/prebuilt/linux-x86_64/bin/make
    echo ">> $MAKE -f Makefile"
    $MAKE -f Makefile
    if [ $? -ne 0 ]; then
    echo "Error building Baugeschichte"
    exit 1
    fi
}

runMakeInstall() {
    ANDROID_BUILD_DIR=$1/android-build
    echo ">> $MAKE INSTALL_ROOT=$ANDROID_BUILD_DIR -f Makefile install"
    $MAKE INSTALL_ROOT=$ANDROID_BUILD_DIR -f Makefile install
    if [ $? -ne 0 ]; then
    echo "Error building Baugeschichte"
    exit 1
    fi
}

createAPK() {
    ANDROID_BUILD_DIR=$1/android-build
    DEPLOY_TOOL=$2
    SETTING=$BUILD_DIR/android-Baugeschichte-deployment-settings.json
    # Option --aab  not possible as ANDROID_EXTRA_LIBS isn ot picking up the armv7 version of SSL
    echo ">> $DEPLOY_TOOL --input $SETTING --output $ANDROID_BUILD_DIR --android-platform $PLATFORM --jdk $JDK --gradle --release ..."
    $DEPLOY_TOOL --input $SETTING --output $ANDROID_BUILD_DIR --android-platform $PLATFORM --jdk $JDK --gradle --release $SIGN_OPTIONS
    if [ $? -ne 0 ]; then
    echo "Error building Baugeschichte"
    exit 1
    fi
}


#
# build ARM 32 bit
#
BUILD_DIR=$BUILD_BASE/armeabi-v7a
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
mkdir -p $TARGET_DIR
cd $BUILD_DIR
export ANDROID_TARGET_ARCH=armeabi-v7a # workaround for https://bugreports.qt.io/browse/QTBUG-80938

runQmake $QT_DIR/android/bin/qmake 'ANDROID_ABIS=armeabi-v7a'
runMake
runMakeInstall $BUILD_DIR
createAPK $BUILD_DIR $QT_DIR/android/bin/androiddeployqt

# copy file
APK=$BUILD_DIR/android-build/build/outputs/apk/release/android-build-release-unsigned.apk
if [ ! -z "$SIGN_OPTIONS" ]; then
   APK=$BUILD_DIR/android-build/build/outputs/apk/release/android-build-release-signed.apk
fi
DESTINATION=$TARGET_DIR/Baugeschichte_$VERSION-$SIGN_STATUS\_android_$TIMESTAMP.apk
echo ">> cp $APK $DESTINATION"
cp $APK $DESTINATION
if [ $? -ne 0 ]; then
  echo "Error building Baugeschichte"
  exit 1
fi


#
# build ARM 64 bit
#
BUILD_DIR=$BUILD_BASE/arm64
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cd $BUILD_DIR
export ANDROID_TARGET_ARCH=arm64-v8a # workaround for https://bugreports.qt.io/browse/QTBUG-80938

runQmake $QT_DIR/android/bin/qmake 'ANDROID_ABIS=arm64-v8a'
runMake
runMakeInstall $BUILD_DIR
createAPK $BUILD_DIR $QT_DIR/android/bin/androiddeployqt

# copy file
APK64=$BUILD_DIR/android-build/build/outputs/apk/release/android-build-release-unsigned.apk
if [ ! -z "$SIGN_OPTIONS" ]; then
   APK64=$BUILD_DIR/android-build/build/outputs/apk/release/android-build-release-signed.apk
fi
DESTINATION64=$TARGET_DIR/Baugeschichte_$VERSION-$SIGN_STATUS\_arm64_$TIMESTAMP.apk
cp $APK64 $DESTINATION64
if [ $? -ne 0 ]; then
  echo "Error building Baugeschichte"
  exit 1
fi


echo " "
echo "Copied result to $DESTINATION"
echo "Copied result to $DESTINATION64"
echo " "
 
exit 0
