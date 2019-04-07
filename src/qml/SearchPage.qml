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

import QtQuick 2.4
import "./"

BaseView {
    id: root

    loading: searchModel.isLoading

    SearchModel {
        id: searchModel
    }

    LineInput {
        id: searchInput
        width: parent.width
        hint: qsTr("Address ...")
        onTextChanged: {
            resultLimitReset.start();
            searchModel.clear();
            searchModel.phrase = text;
        }
    }

    ListView {
        id: searchResult
        model: searchModel.model
        interactive: true
        clip: true
        anchors  {
            top: searchInput.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        delegate: SearchResultDelegate {
            text: title
            onSelected: {
                if (isBuilding) {
                    appCore.selectedHouse = title;
                    appCore.showDetails = true;
                    appCore.centerSelectedHouse();
                    uiStack.pop(null);
                } else {
                    searchModel.limitResults = false;
                    searchInput.inputText = title;
                }
            }
        }
    }

    Text {
        anchors.bottom: parent.bottom
        width: parent.width
        visible: searchModel.error !== ""

        text: searchModel.error
        color: "red"
        wrapMode: Text.Wrap
    }

    Timer {
        id: resultLimitReset
        interval: 20
        onTriggered: {
            if (searchInput.text == "")
                searchModel.limitResults = true;
        }
    }

    Timer {
        id: focusTimer
        interval: 20
        onTriggered: {
            searchInput.forceActiveFocus();
        }
    }
    Component.onCompleted: {
        focusTimer.start();
    }
}
