/**
 ** This file is part of the Baugeschichte.at project.
 **
 ** The MIT License (MIT)
 **
 ** Copyright (c) 2016 Guenter Schwann
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

import QtQuick 2.4

/**
 Indicator for the Map to show the scale/distances
 */
Item {
    id: root

    // The Map item needs to be set here
    property var mapItem
    property variant scaleLengths: [5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000, 500000, 1000000, 2000000]

    function smartDistanceString(meters) {
        if (meters > 1000) {
            return Math.round(meters / 1000) + " km";
        } else {
            return Math.round(meters) + " m";
        }
    }

    function calculateScale() {
        var coord1, coord2, dist, text, f
        f = 0
        coord1 = mapItem.toCoordinate(Qt.point(0, 0))
        coord2 = mapItem.toCoordinate(
                    Qt.point(0 + scaleImage.sourceSize.width, 0))
        dist = Math.round(coord1.distanceTo(coord2) / mapItem.scale)

        if (dist !== 0) {
            for (var i = 0; i < scaleLengths.length - 1; i++) {
                if (dist < (scaleLengths[i] + scaleLengths[i + 1]) / 2) {
                    f = scaleLengths[i] / dist
                    dist = scaleLengths[i]
                    break
                }
            }
            if (f === 0) {
                f = dist / scaleLengths[i]
                dist = scaleLengths[i]
            }
        }

        text = smartDistanceString(dist)
        scaleImage.width = (scaleImage.sourceSize.width * f) - 2 * scaleImageLeft.sourceSize.width
        scaleText.text = text
    }

    visible: scaleText.text != "0 m"

    height: scaleText.height * 1.8
    width: scaleImage.width

    Image {
        id: scaleImageLeft
        source: "qrc:/resources/scale_end.png"
        anchors.bottom: parent.bottom
        anchors.right: parent.left
    }
    Image {
        id: scaleImage
        source: "qrc:/resources/scale.png"
        anchors.bottom: parent.bottom
        anchors.right: scaleImageRight.left
    }
    Image {
        id: scaleImageRight
        source: "qrc:/resources/scale_end.png"
        anchors.bottom: parent.bottom
        anchors.right: parent.right
    }
    Text {
        id: scaleText
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -5
        color: "#004EAE"
        text: "0 m"
    }
}
