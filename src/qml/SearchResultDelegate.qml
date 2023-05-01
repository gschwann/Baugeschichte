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

import QtQuick
import "."

Item {
    id: root
    width: parent.width
    height: textitem.height + 2 * Theme.largeMargin

    property alias text: textitem.text
    signal selected(string wot)

    Rectangle {
        anchors.fill: parent
        color: "#d6d6d6"
        visible: mouse.pressed
    }

    Text {
        id: textitem
        wrapMode: Text.Wrap
        color: "white"
        font.pixelSize: Theme.largeFontSize
        text: modelData
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.largeMargin
        anchors.right: arrow.left
        anchors.rightMargin: Theme.defaultMargin
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.defaultMargin
        height: 1
        color: "#424246"
    }

    Image {
        id: arrow
        anchors.right: parent.right
        anchors.rightMargin: Theme.defaultMargin
        anchors.verticalCenter: parent.verticalCenter
        source: "qrc:/resources/navigation_next_item.png"
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        onClicked: {
            selected(textitem.text)
        }
    }
}
