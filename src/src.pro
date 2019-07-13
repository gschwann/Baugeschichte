TEMPLATE = app

TARGET = Baugeschichte

QT += qml quick location positioning concurrent sensors svg xml sql
android {
    QT += androidextras

    equals(ANDROID_TARGET_ARCH, arm64-v8a) {
        LIBPATH = $$absolute_path($$OUT_PWD/openssl-android/arm64-v8a)
        !exists($$LIBPATH/libssl_1_1.so) {
            system("mkdir -p $$LIBPATH")
            system("cd $$LIBPATH && wget https://github.com/KDAB/android_openssl/raw/master/arm64/libssl_1_1.so")
            system("cd $$LIBPATH && wget https://github.com/KDAB/android_openssl/raw/master/arm64/libcrypto_1_1.so")
        }
    }

    equals(ANDROID_TARGET_ARCH, armeabi-v7a) {
        LIBPATH = $$absolute_path($$OUT_PWD/openssl-android/armeabi-v7a)
        !exists($$LIBPATH/libssl_1_1.so) {
            system("mkdir -p $$LIBPATH")
            system("cd $$LIBPATH && wget https://github.com/KDAB/android_openssl/raw/master/arm/libssl_1_1.so")
            system("cd $$LIBPATH && wget https://github.com/KDAB/android_openssl/raw/master/arm/libcrypto_1_1.so")
        }
    }

    # correct ssl lib filenames
    system("cd $$LIBPATH && cp libssl_1_1.so libssl.so && cp libcrypto_1_1.so libcrypto.so")

    ANDROID_EXTRA_LIBS += \
        $$LIBPATH/libssl.so \
        $$LIBPATH/libcrypto.so \
        $$LIBPATH/libssl_1_1.so \
        $$LIBPATH/libcrypto_1_1.so
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


CONFIG += c++11
CONFIG += qtquickcompiler

RESOURCES += qml.qrc \
    images.qrc \
    ../translations/translations.qrc

SOURCES += main.cpp \
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
    android/gradle/wrapper/gradle-wrapper.jar \
    android/gradlew \
    android/res/values/libs.xml \
    android/build.gradle \
    android/gradle/wrapper/gradle-wrapper.properties \
    android/gradlew.bat \
    qml/qmldir \
    qml/BaseView.qml \
    qml/CategoryselectionView.qml \
    qml/DetailsModel.qml \
    qml/DetailsTextArea.qml \
    qml/DetailsView.qml \
    qml/ImageCarousel.qml \
    qml/JsonModel.qml \
    qml/LineInput.qml \
    qml/LoadIndicator.qml \
    qml/main.qml \
    qml/MapComponent.qml \
    qml/MapScale.qml \
    qml/MapScaleZoom.qml \
    qml/PositionIndicator.qml \
    qml/RouteLine.qml \
    qml/RouteLoader.qml \
    qml/RouteView.qml \
    qml/SearchModel.qml \
    qml/SearchPage.qml \
    qml/SearchResultDelegate.qml \
    qml/SettingsView.qml \
    qml/ShutDownDialog.qml \
    qml/SizeTracer.qml \
    qml/Theme.qml \
    qml/ToolBar.qml \
    qml/ToolBarButton.qml \

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android

include(deployment.pri)


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
