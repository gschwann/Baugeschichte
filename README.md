[![Build Status](https://api.travis-ci.org/gschwann/Baugeschichte.png)](https://travis-ci.org/gschwann/Baugeschichte)
[![BCH compliance](https://bettercodehub.com/edge/badge/gschwann/Baugeschichte?branch=master)](https://bettercodehub.com/)

# Baugeschichte
This app is from the project "www.housetrails.org" (also known as "Baugeschichte" or "Grazwiki").

It does the communication with the server and displayes objects that are linked to coordinates
and also contain images and descriptions. It makes use of the Wikimedia API.

![Screenshot](doc/Screenshot.jpg)

## Build instructions
### Android
For building the Andoird use src/src.pro as the project.

For MapBoxGL support openssl is needed (Google removed it since Android 7?)
Best use [https://github.com/akontsevich/openssl-android-build](https://github.com/akontsevich/openssl-android-build)

This repo is cloned/built next to Baugeschichte.

Another guide is in [http://doc.qt.io/qt-5/opensslsupport.html](http://doc.qt.io/qt-5/opensslsupport.html)

### iOS
