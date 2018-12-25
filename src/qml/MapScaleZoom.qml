import QtQuick 2.11
import QtQuick.Controls 2.0

Item {
    id: root

    implicitWidth: 30
    implicitHeight: 80

    // The Map item needs to be set here
    property var mapItem

    function adaptSliderVisibility() {
        zoomSlider.visible = mapItem.width > (scaleItem.width * 12)
    }

    Button {
        anchors.fill: scaleItem
        anchors.margins: -5
        opacity: 0.5
        onClicked: {
            zoomSlider.visible = !zoomSlider.visible;
        }
    }

    MapScale {
        id: scaleItem
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: 10

        mapItem: root.mapItem
    }

    Slider {
        id: zoomSlider
        from: mapItem.minimumZoomLevel
        to: mapItem.maximumZoomLevel
        live: true
        anchors.top: parent.top
        anchors.bottom: scaleItem.top
        anchors.bottomMargin: 10
        anchors.right: parent.right
        orientation: Qt.Vertical
        onValueChanged: {
            mapItem.zoomLevel = value;
        }
    }

    Connections{
        target: mapItem
        onZoomLevelChanged: {
            if (!zoomSlider.pressed) {
                zoomSlider.value = mapItem.zoomLevel;
            }
            scaleItem.calculateScale();
        }
        onWidthChanged: {
            scaleItem.calculateScale();
            root.adaptSliderVisibility();
        }
        onHeightChanged: {
            scaleItem.calculateScale();
            root.adaptSliderVisibility();
        }
    }

    Component.onCompleted: {
        zoomSlider.value = mapItem.zoomLevel;
        scaleItem.calculateScale();
        root.adaptSliderVisibility();
    }
}
