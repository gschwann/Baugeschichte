

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
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.3
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.0
import QtPositioning 5.5
import QtLocation 5.5
import Qt.labs.settings 1.0
import "./"

Item {
    id: root

    width: 1024
    height: 800

    visible: true

    Material.accent: Material.LightBlue

    readonly property bool loading: (uiStack.currentItem
                                     && uiStack.currentItem.loading)
                                    || MarkerLoader.loading
                                    || CategoryLoader.isLoading
                                    || routeLoader.loading

    property MapComponent mainMap: null

    function goBack() {
        console.log("uiStack Depth:" + uiStack.depth)
        if (uiStack.currentItem.detailsOpen) {
            AppCore.showDetails = false
        } else {
            if (uiStack.depth > 1) {
                uiStack.pop()
            } else {
                shutDownDialog.open()
            }
        }
    }

    PositionSource {
        id: positionCheck
        preferredPositioningMethods: PositionSource.AllPositioningMethods
        active: false
    }

    Shortcut {
        id: reloadAction
        sequence: "Ctrl+R"
        onActivated: {
            AppCore.reloadUI()
        }
    }
    Shortcut {
        id: settingsMenuAction
        sequence: "Ctrl+M"
        onActivated: {
            uiStack.push(Qt.resolvedUrl("SettingsView.qml"))
        }
    }

    ToolBar {
        id: toolBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        mapItem: root.mainMap
        stackView: uiStack

        loading: root.loading
    }

    ShutDownDialog {
        id: shutDownDialog
    }

    Connections {
        target: AppCore
        function onBackKeyPressed() {
            root.goBack()
        }
    }

    Rectangle {
        id: background
        color: "#060606"
        anchors.fill: parent
        anchors.topMargin: toolBar.height

        focus: true
        Keys.onReleased: {
            console.log("Keys.onrelease")
            if (event.key === Qt.Key_Menu) {
                event.accepted = true
                uiStack.push(Qt.resolvedUrl("SettingsView.qml"))
            }
        }
    }

    RouteLoader {
        id: routeLoader
    }

    StackView {
        id: uiStack
        anchors.fill: background
        objectName: "theStackView"

        initialItem: loader_mapOfEurope

        Component {
            id: component_mapOfEurope

            BaseView {
                id: mapItem

                property bool splitScreen: width > height
                readonly property bool detailsOpen: details.visible

                property alias center: mapOfEurope.center
                property alias zoomLevel: mapOfEurope.zoomLevel

                loading: details.item ? details.item.loading : false

                MapComponent {
                    id: mapOfEurope

                    width: splitScreen ? details.x : parent.width
                    height: parent.height

                    visible: parent.splitScreen || !details.visible

                    center: QtPositioning.coordinate(settings.lastSeenLat,
                                                     settings.lastSeenLon)
                    zoomLevel: settings.lastZoomLevel
                    Component.onCompleted: {
                        root.mainMap = mapOfEurope
                    }
                    Component.onDestruction: {
                        settings.lastSeenLat = mapOfEurope.center.latitude
                        settings.lastSeenLon = mapOfEurope.center.longitude
                        settings.lastZoomLevel = mapOfEurope.zoomLevel
                    }

                    Timer {
                        // workaround for bug QTBUG-52030 / QTBUG-55424
                        interval: 5
                        running: true
                        onTriggered: {
                            mapOfEurope.center = QtPositioning.coordinate(
                                        settings.lastSeenLat,
                                        settings.lastSeenLon)
                        }
                    }
                }

                Loader {
                    id: details

                    property bool fullscreen: item ? item.fullscreen : false

                    x: visible ? (parent.splitScreen
                                  && !fullscreen ? parent.width / 2 : 0) : parent.width
                    width: parent.splitScreen
                           && !fullscreen ? parent.width / 2 : parent.width
                    height: parent.height

                    clip: true
                    visible: AppCore.showDetails
                    onVisibleChanged: {
                        if (visible && source == "") {
                            setSource("DetailsView.qml")
                        }
                    }
                }
            }
        }
        Loader {
            id: loader_mapOfEurope
            sourceComponent: component_mapOfEurope
            readonly property bool loading: item ? item.loading : false
            readonly property bool detailsOpen: item ? item.detailsOpen : false

            function reloadMapItem() {
                posRestore.latitude = item.center.latitude
                posRestore.longitude = item.center.longitude
                posRestore.zoom = item.zoomLevel
                posRestore.start()

                settings.lastSeenLat = item.center.latitude
                settings.lastSeenLon = item.center.longitude
                settings.lastZoomLevel = item.zoomLevel

                loader_mapOfEurope.sourceComponent = undefined
                loader_mapOfEurope.sourceComponent = component_mapOfEurope
            }

            Connections {
                target: AppCore
                function onMapProviderChanged() {
                    loader_mapOfEurope.reloadMapItem()
                }
            }
        }
    }

    // used as workaround to restore the map position and zoom after the map provider changed
    Timer {
        id: posRestore
        property double latitude: 0
        property double longitude: 0
        property double zoom: 0

        interval: 200
        onTriggered: {
            loader_mapOfEurope.item.center = QtPositioning.coordinate(latitude,
                                                                      longitude)
            loader_mapOfEurope.item.zoomLevel = zoom
        }
    }

    Settings {
        id: settings
        property double lastSeenLat: 47.0666667 // graz
        property double lastSeenLon: 15.45
        property double lastZoomLevel: 16 // default zoom level
    }
}
