TEMPLATE = app

TARGET = Baugeschichte

# No spaces here - for the android build script
VERSION=2.2.0

DEFINES += APP_VERSION='\'"$$VERSION"\''

QT += qml quick location positioning concurrent sensors svg xml sql
android {
    QT += androidextras

    equals(ANDROID_TARGET_ARCH, arm64-v8a) {
        LIBPATH64 = $$absolute_path($$OUT_PWD/openssl-android/arm64-v8a)
        !exists($$LIBPATH64/libssl_1_1.so) {
            system("mkdir -p $$LIBPATH64")
            system("cd $$LIBPATH64 && wget https://github.com/KDAB/android_openssl/raw/master/arm64/libssl_1_1.so")
            system("cd $$LIBPATH64 && wget https://github.com/KDAB/android_openssl/raw/master/arm64/libcrypto_1_1.so")
            # correct ssl lib filenames
            system("cd $$LIBPATH64 && cp libssl_1_1.so libssl.so && cp libcrypto_1_1.so libcrypto.so")
        }
        ANDROID_EXTRA_LIBS += \
            $$LIBPATH64/libssl.so \
            $$LIBPATH64/libcrypto.so \
            $$LIBPATH64/libssl_1_1.so \
            $$LIBPATH64/libcrypto_1_1.so
    }

    equals(ANDROID_TARGET_ARCH, armeabi-v7a) {
        LIBPATH32 = $$absolute_path($$OUT_PWD/openssl-android/armeabi-v7a)
        !exists($$LIBPATH32/libssl_1_1.so) {
            system("mkdir -p $$LIBPATH32")
            system("cd $$LIBPATH32 && wget https://github.com/KDAB/android_openssl/raw/master/arm/libssl_1_1.so")
            system("cd $$LIBPATH32 && wget https://github.com/KDAB/android_openssl/raw/master/arm/libcrypto_1_1.so")
            # correct ssl lib filenames
            system("cd $$LIBPATH32 && cp libssl_1_1.so libssl.so && cp libcrypto_1_1.so libcrypto.so")
        }
        ANDROID_EXTRA_LIBS += \
            $$LIBPATH32/libssl.so \
            $$LIBPATH32/libcrypto.so \
            $$LIBPATH32/libssl_1_1.so \
            $$LIBPATH32/libcrypto_1_1.so
    }

    defineReplace(droidVersionCode) {
            segments = $$split(1, ".")
            for (segment, segments): vCode = "$$first(vCode)$$format_number($$segment, width=3 zeropad)"

            contains(ANDROID_TARGET_ARCH, arm64-v8a): \
                suffix = 1
            else:contains(ANDROID_TARGET_ARCH, armeabi-v7a): \
                suffix = 0
            # add more cases as needed

            return($$first(vCode)$$first(suffix))
    }

    ANDROID_VERSION_NAME = $$VERSION
    ANDROID_VERSION_CODE = $$droidVersionCode($$ANDROID_VERSION_NAME)

    ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
}

ios {
    QMAKE_INFO_PLIST = $$PWD/iOS/Info.plist
    BUNDLEID = at.bitschmiede.grazwiki
    QMAKE_ASSET_CATALOGS = $$PWD/ios/Images.xcassets
    QMAKE_ASSET_CATALOGS_APP_ICON = "AppIcon"
    #ios_icon.files = $$files($$PWD/iOS/AppIcons/*.png)
    #QMAKE_BUNDLE_DATA += ios_icon
    ios_artwork.files = $$files($$PWD/iOS/Screenshots/*.png)
    QMAKE_BUNDLE_DATA += ios_artwork
    app_launch_images.files = $$files($$PWD/iOS/splash*.png)
    QMAKE_BUNDLE_DATA += app_launch_images
    app_launch_screen.files = $$files($$PWD/iOS/LaunchScreen.xib)
    QMAKE_BUNDLE_DATA += app_launch_screen

    QMAKE_IOS_DEPLOYMENT_TARGET = 11.0
    # Note for devices: 1=iPhone, 2=iPad, 1,2=Universal.
    QMAKE_APPLE_TARGETED_DEVICE_FAMILY = 1,2
}

CONFIG += c++14
CONFIG += qtquickcompiler

# The following define makes your compiler emit warnings if you use
# any Qt feature that has been marked deprecated (the exact warnings
# depend on your compiler). Refer to the documentation for the
# deprecated API to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

RESOURCES += qml.qrc \
    images.qrc \
    ../translations/translations.qrc

SOURCES += \
    main.cpp \
    houselocationfilter.cpp \
    applicationcore.cpp \
    markerloader.cpp \
    housemarker.cpp \
    housemarkermodel.cpp \
    categoryloader.cpp \
    mainwindow.cpp

HEADERS += \
    houselocationfilter.h \
    applicationcore.h \
    markerloader.h \
    housemarker.h \
    housemarkermodel.h \
    categoryloader.h \
    mainwindow.h

DISTFILES += \
    android/AndroidManifest.xml \
    android/build.gradle \
    android/res/values/libs.xml

include(deployment.pri)

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Supported languages
# qml sources
lupdate_only {
    SOURCES += qml/*.qml
}
LANGUAGES = de en
# used to create .ts files
 defineReplace(prependAll) {
     for(a,$$1):result += $$2$${a}$$3
     return($$result)
 }
# Available translations
TSNAME = Baugeschichte
tsroot = $$join(TSNAME,,,.ts)
tstarget = $$join(TSNAME,,,_)
TRANSLATIONS = $$PWD/../translations/$$tsroot
TRANSLATIONS += $$prependAll(LANGUAGES, $$PWD/../translations/$$tstarget, .ts)

# run LRELEASE to generate the qm files
qtPrepareTool(LRELEASE, lrelease)
message($$TRANSLATIONS)
for(tsfile, TRANSLATIONS) {
    message($$tsfile)
    command = $$LRELEASE $$tsfile
    system($$command)|error("Failed to run: $$command")
}
