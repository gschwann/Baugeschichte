!versionAtLeast(QT_VERSION, "5.12.4") {
    warning("Qt 5.12.4 or above is required.")
}

TEMPLATE = subdirs

SUBDIRS = src

android: {
} else {
ios: {
} else {
SUBDIRS += tests
}
}
