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

import Baugeschichte 1.0
import QtQuick 2.5
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1

Item {
    id: root

    property MapComponent mapItem: null
    property var stackView: null

    property bool loading: false

    height: Theme.toolButtonHeight
    
    Rectangle {
        id: toolBarBackground
        anchors.fill: parent
        color: "#f8f8f8"
    }
    
    RowLayout {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: menuButton.left
        anchors.rightMargin: Theme.largeMargin
        
        ToolbarButton {
            id: mapButton
            source: "qrc:/resources/icon-map.svg"
            onClicked: {
                if (AppCore.showDetails) {
                    AppCore.showDetails = false;
                    return;
                }
                
                mapItem.resetToMainModel();
                stackView.pop(null);
                AppCore.routeKML = "";
                routeLoader.reset();
            }
        }
        
        ToolbarButton {
            id: searchButton
            source: "qrc:/resources/icon-search.svg"
            onClicked: {
                mapItem.resetToMainModel();
                AppCore.clearHouseSelection();
                AppCore.showDetails = false;
                AppCore.routeKML = "";
                routeLoader.routeHouses = [];
                stackView.pop(null);
                stackView.push(Qt.resolvedUrl("SearchPage.qml"));
            }
        }
        
        ToolbarButton {
            id: categoriesButton
            source: "qrc:/resources/icon-categories.svg"
            onClicked: {
                mapItem.useCategoryModel();
                AppCore.clearHouseSelection();
                AppCore.showDetails = false;
                AppCore.routeKML = "";
                routeLoader.routeHouses = [];
                stackView.pop(null);
                stackView.push(Qt.resolvedUrl("CategoryselectionView.qml"));
            }
        }
        
        ToolbarButton {
            id: routesButton
            source: "qrc:/resources/icon-route.svg"
            onClicked: {
                mapItem.resetToMainModel();
                AppCore.clearHouseSelection();
                AppCore.showDetails = false;
                AppCore.routeKML = "";
                routeLoader.routeHouses = [];
                stackView.push(Qt.resolvedUrl("RouteView.qml"));
            }
        }
        
        ToolbarButton {
            id: followMeButton
            source: iconFromState()
            enabled: positionCheck.valid
            
            onClicked: {
                if (!AppCore.showPosition) {
                    AppCore.showPosition = true;
                    AppCore.followPosition = false;
                } else {
                    if (AppCore.followPosition) {
                        AppCore.showPosition = false;
                    } else {
                        AppCore.followPosition = true;
                    }
                }
            }
            
            function iconFromState() {
                if (!AppCore.showPosition) {
                    return "qrc:/resources/gps_off.svg"
                } else {
                    if (AppCore.followPosition) {
                        return "qrc:/resources/gps_follow.svg"
                    } else {
                        return "qrc:/resources/gps_on.svg"
                    }
                }
            }
        }
    }

    ToolbarButton {
        id: menuButton

        anchors.top: parent.top
        anchors.right: parent.right

        source: "qrc:/resources/menu.svg"
        rotation: menuPopup.visible ? 90 : 0
        onClicked: {
            menuPopup.open();
        }
    }

    Popup {
        id: menuPopup

        x: parent.width - width
        y: menuButton.height

        modal: true
        focus: true

        background: Rectangle{
            color:"white"
            border.color: "darkgray"
            border.width: 1
        }

        Item {
            width: Math.max(settingsItem.width, 100)
            height: settingsItem.height
            implicitWidth: width
            implicitHeight: height

            Text {
                id: settingsItem
                text: qsTr("Settings")
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -Theme.smallMargin
                onClicked: {
                    stackView.push(Qt.resolvedUrl("SettingsView.qml"));
                    menuPopup.close();
                }
            }
        }
    }
    
    Item {
        height: root.height
        width: height
        anchors.right: parent.right
        anchors.rightMargin: width * 1.05
        anchors.top: parent.top
        
        LoadIndicator {
            id: busyIndicator
            
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: root.height * 0.1
            
            height: root.height * 0.8
            width: height
            
            running: root.loading
        }
    }
}
