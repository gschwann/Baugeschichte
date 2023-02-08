

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
import QtQuick 2.5
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property bool __reloadUI: false

    Rectangle {
        id: background
        anchors.fill: parent
        color: "#f8f8f8"
    }
    MouseArea {
        id: clickCatcher
        anchors.fill: parent
    }

    TabBar {
        id: bar
        width: parent.width
        TabButton {
            text: qsTr("Settings")
        }
        TabButton {
            text: qsTr("Version")
        }
        TabButton {
            text: qsTr("Privacy")
        }
    }

    StackLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: bar.bottom
        anchors.bottom: closeButton.top
        anchors.margins: Theme.defaultMargin
        currentIndex: bar.currentIndex
        Item {
            Column {
                width: parent.width
                spacing: mapText.height / 4

                Text {
                    id: mapText
                    text: qsTr("Map provider")
                }

                ComboBox {
                    width: mapText.width * 2
                    textRole: "key"
                    model: ListModel {
                        id: providerModel
                        ListElement {
                            key: qsTr("OpenStreetMap")
                            value: "osm"
                        }
                        ListElement {
                            key: qsTr("MapBox")
                            value: "mapbox"
                        }
                        ListElement {
                            key: qsTr("MapBoxGL")
                            value: "mapboxGl"
                        }
                    }
                    currentIndex: AppCore.mapProvider
                                  === "osm" ? 0 : (AppCore.mapProvider === "mapbox" ? 1 : 2)
                    onCurrentIndexChanged: {
                        var newValue = providerModel.get(currentIndex).value
                        if (newValue !== AppCore.mapProvider) {
                            AppCore.mapProvider = newValue
                            __reloadUI = true
                        }
                    }
                }

                Text {
                    width: parent.width
                    color: "gray"
                    text: qsTr("The app might crash, and needs to be restarted to work.")
                    wrapMode: Text.WordWrap
                }

                CheckBox {
                    id: extraScaleItem
                    text: qsTr("Do extra scaling")
                    checked: AppCore.extraScaling
                    onClicked: {
                        AppCore.extraScaling = checked
                    }
                }
            }
        }
        Item {
            id: versionTab
            Text {
                text: qsTr("Version: ") + AppCore.versionString
            }
        }
        Item {
            id: privacyTab
            Button {
                text: qsTr("Open data privacy in browser")
                onClicked: {
                    AppCore.openExternalLink(
                                "https://baugeschichte.at/App-Datenschutzerkl%C3%A4rung")
                }
            }
        }
    }

    Button {
        id: closeButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.defaultMargin
        text: qsTr("Close")
        onClicked: {
            uiStack.pop()
        }
    }
    Component.onDestruction: {
        if (__reloadUI) {
            __reloadUI = false
            AppCore.reloadUI()
        }
    }
}
