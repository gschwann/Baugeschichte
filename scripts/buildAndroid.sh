#!/bin/sh

QT_DIR=/opt/Qt/5.12.4
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
    echo ">> $QMAKE_BIN -o Makefile $SOURCE_DIR/src/src.pro -spec android-clang CONFIG+=qtquickcompiler"
    $QMAKE_BIN $SOURCE_DIR/src/src.pro -o Makefile -spec android-clang CONFIG+=qtquickcompiler
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
    SETTING=$BUILD_DIR/android-libBaugeschichte.so-deployment-settings.json
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
BUILD_DIR=$BUILD_BASE/arm32
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
mkdir -p $TARGET_DIR
cd $BUILD_DIR

runQmake $QT_DIR/android_armv7/bin/qmake
runMake
runMakeInstall $BUILD_DIR
createAPK $BUILD_DIR $QT_DIR/android_armv7/bin/androiddeployqt

# copy file
APK32=$BUILD_DIR/android-build/build/outputs/apk/android-build-release-unsigned.apk
if [ ! -z "$SIGN_OPTIONS" ]; then
   APK32=$BUILD_DIR/android-build/build/outputs/apk/android-build-release-signed.apk
fi
DESTINATION32=$TARGET_DIR/Baugeschichte_$SIGN_STATUS\_arm32_$TIMESTAMP.apk
cp $APK32 $DESTINATION32
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

runQmake $QT_DIR/android_arm64_v8a/bin/qmake
runMake
runMakeInstall $BUILD_DIR
createAPK $BUILD_DIR $QT_DIR/android_arm64_v8a/bin/androiddeployqt

# copy file
APK64=$BUILD_DIR/android-build/build/outputs/apk/android-build-release-unsigned.apk
if [ ! -z "$SIGN_OPTIONS" ]; then
   APK64=$BUILD_DIR/android-build/build/outputs/apk/android-build-release-signed.apk
fi
DESTINATION64=$TARGET_DIR/Baugeschichte_$SIGN_STATUS\_arm64_$TIMESTAMP.apk
cp $APK64 $DESTINATION64
if [ $? -ne 0 ]; then
  echo "Error building Baugeschichte"
  exit 1
fi


echo " "
echo "Copied result to $DESTINATION32"
echo "Copied result to $DESTINATION64"
echo " "
 
exit 0
