/**
 ** This file is part of the Baugeschichte.at project.
 **
 ** The MIT License (MIT)
 **
 ** Copyright (c) 2015 primeMover2011
 **
 ** Permission is hereby granted, free of charge, to any person obtaining a copy
 ** of this software and associated documentation files (the "Software"), to deal
 ** in the Software without restriction, including without limitation the rights
 ** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 ** copies of the Software, and to permit persons to whom the Software is
 ** furnished to do so, subject to the following conditions:
 **
 ** The above copyright notice and this permission notice shall be included in all
 ** copies or substantial portions of the Software.
 **
 ** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 ** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 ** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 ** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 ** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 ** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 ** SOFTWARE.
 **/

pragma Singleton

import QtQuick
import QtQuick.Controls
import QtQuick.Window

Item {
    id: root

    readonly property int smallFontSize: Math.floor(fm.font.pixelSize * 1.0 * internal.textScaleFactor)
    readonly property int defaultFontSize: Math.floor(fm.font.pixelSize * 1.2 * internal.textScaleFactor)
    readonly property int largeFontSize: Math.floor(fm.font.pixelSize * 1.6 * internal.textScaleFactor)

    readonly property int tinyMargin: Math.round(fm.font.pixelSize / 7.0)
    readonly property int smallMargin: Math.round(fm.font.pixelSize / 4.0)
    readonly property int defaultMargin: Math.round(fm.font.pixelSize / 2.0)
    readonly property int largeMargin: Math.floor(fm.font.pixelSize)

    readonly property int buttonHeight: button.height
    readonly property int toolButtonHeight: Math.min(buttonHeight, internal.maxToolButtonWidth)

    readonly property int defaultMarkerSize: Math.round(buttonHeight * 0.8)

    // Converts the given value (for mm length) to pixel size on screen
    function mm(lengthInMM) {
        return Math.round(lengthInMM * Screen.pixelDensity);
    }

    FontMetrics {
        id: fm

        Component.onCompleted: {
            console.log("Screen/Layout/sizes info:")
            console.log("Default font height height: "+height);
            console.log("Default font pixelSize: "+fm.font.pixelSize);
            console.log("Default font pointSize: "+fm.font.pointSize);
            console.log("Screen.devicePixelRatio "+Screen.devicePixelRatio)
            console.log("Screen.logicalPixelDensity "+Screen.logicalPixelDensity)
            console.log("Screen.pixelDensity "+Screen.pixelDensity)
            console.log("Screen.height: "+Screen.height)
            console.log("Screen.width: "+Screen.width)
            console.log("buttonHeight: "+buttonHeight);
            console.log("mm(8): "+mm(8));
            console.log("buttonHeight: " + buttonHeight);
            console.log("toolButtonHeight: "+ toolButtonHeight);
            console.log("maxToolButtonWidth: "+ internal.maxToolButtonWidth);
        }
    }

    Button {
        id: button
        visible: false
    }

    QtObject {
        id: internal

        property real textScaleFactor: 1
        readonly property real maxToolButtonWidth: Math.floor(Math.min(Screen.height, Screen.width) / 7)
        readonly property real contentScaleFactor: fm.font.pixelSize / 16.0
    }
}
