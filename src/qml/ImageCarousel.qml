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

import QtQuick 2.5
import "."

/**
 Carousel in the details view showing the fotos of the building
 */
ListView {
    id: root

    property bool fullscreen: false

    focus: true
    clip: true

    Keys.onLeftPressed: {
        decrementCurrentIndex();
    }

    Keys.onRightPressed: {
        incrementCurrentIndex();
    }

    orientation: ListView.Horizontal
    snapMode: ListView.SnapToItem

    flickDeceleration: 2 * width
    maximumFlickVelocity: width
    highlightFollowsCurrentItem: true
    highlightMoveVelocity: 2 * width

    onMovementEnded: {
        currentIndex = indexAt(contentX + width / 2, height / 2);
    }
    delegate: Item {
        id: imageContainer

        width: root.width
        height: root.height

        SingleImageView {
            id:myImage
            width: parent.width
            height: parent.height
            source: imageUrl(imageName)
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            smooth: true

            function imageUrl(imageName) {
                var isRemote = imageName.substring(0, 4) === "http";
                if (isRemote) {
                    return imageName;
                } else {
                    var url = "http://baugeschichte.at/" + imageName;
                    return url;
                }
            }

            onZoomedChanged: {
                root.interactive = !zoomed;
            }

            Text {
                id: loadError
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                color: "red"
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                text:qsTr("Failure loading image from")+"\n" + myImage.source
                visible: myImage.status === Image.Error
            }
        }
        Rectangle {
            id: textRect
            width: textItem.width
            height: textItem.height
            anchors.bottom: myImage.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#ffffff"
            smooth: true
            Text {
                id: textItem
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(implicitWidth, imageContainer.width)
                text: imageDescription
                smooth: true
                font.pixelSize: Theme.smallFontSize
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }

    Image {
        id: previousButton

        width: height
        height: Theme.buttonHeight
        sourceSize: Qt.size(width, height)
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        source: "qrc:/resources/arrow-left.svg"
        opacity: previousClickArea.pressed ? 0.8 : 0.6
        visible: root.currentIndex > 0

        MouseArea {
            id: previousClickArea
            anchors.fill: parent
            anchors.margins: -Theme.smallMargin

            onClicked: {
                decrementCurrentIndex();
            }
        }
    }

    Image {
        id: nextButton

        width: height
        height: Theme.buttonHeight
        sourceSize: Qt.size(width, height)
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right

        source: "qrc:/resources/arrow-right.svg"
        opacity: previousClickArea.pressed ? 0.8 : 0.6
        visible: root.currentIndex < root.model.count - 1

        MouseArea {
            id: nextClickArea
            anchors.fill: parent
            anchors.margins: -Theme.smallMargin

            onClicked: {
                incrementCurrentIndex();
            }
        }
    }

    Rectangle {
        anchors.fill: fullViewButton

        radius: width / 3
        opacity: 0.3
    }

    Image {
        id: fullViewButton

        width: height
        height: Theme.buttonHeight
        sourceSize: Qt.size(width, height)
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Theme.tinyMargin

        source: root.fullscreen ? "qrc:/resources/fullscreen_exit.svg" : "qrc:/resources/fullscreen.svg"
        opacity: fullViewButton.pressed ? 0.8 : 0.6

        MouseArea {
            anchors.fill: parent
            anchors.margins: -Theme.smallMargin

            onClicked: {
                root.fullscreen = !root.fullscreen;
            }
        }
    }
}
