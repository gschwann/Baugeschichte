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

import Baugeschichte 1.0
import QtQuick 2.4
import QtQuick.Controls 2.0
import "./"

Item {
    id: root

    Rectangle {
        id: textBackground
        anchors.fill: root
        color: "white"
    }

    Flickable {
        id: textArea

        anchors.fill: root

        contentWidth: textItem.paintedWidth
        contentHeight: textItem.paintedHeight
        clip: true

        flickableDirection: Flickable.VerticalFlick
        ScrollBar.vertical: ScrollBar {}

        Item {
            width: textArea.width
            height: textArea.height

            Text {
                id: textItem
                anchors.fill: parent
                anchors.margins: Theme.smallMargin

                wrapMode: TextEdit.WordWrap
                textFormat: TextEdit.RichText
                font.pixelSize: Theme.smallFontSize

                text: (detailText.length > 0) ? detailText : qsTr("No text")

                onLinkActivated: {
                    if (link.substr(0, 11) === "internal://") {
                        var newBuilding = link.substring(11, link.length);
                        console.debug("Open internal link: "+newBuilding);
                        AppCore.selectAndCenterHouse(newBuilding);
                    } else {
                        console.debug("Open external link: "+link);
                        AppCore.openExternalLink(link);
                    }
                }
            }
        }
    }
}
