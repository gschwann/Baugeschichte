import QtQuick 2.12

//Item to view a single image (including zoome, flick, etc.)
FocusScope {
    id: root

    property alias source: imageItem.source
    readonly property bool zoomed: flick.interactive

    function scaleImage(posX, posY, scaleFactor) {
        var pt = Qt.point(posX, posY);
        var w = Math.max(flick.contentWidth * scaleFactor, flick.width);
        var h = Math.max(flick.contentHeight * scaleFactor, flick.height);
        flick.resizeContent(w, h, pt);
        flick.returnToBounds();
    }

    Flickable {
        id: flick
        anchors.fill: parent

        contentWidth: width
        contentHeight: height

        interactive: Math.abs(contentWidth - width) > 10

        rebound: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 100
                easing.type: Easing.InOutCubic
            }
        }

        Image {
            id: imageItem
            width: flick.contentWidth
            height: flick.contentHeight
            fillMode: Image.PreserveAspectFit
            antialiasing: true
            asynchronous: true
        }

        Item {
            id: scaleTarget
        }

        PinchArea {
            id: pinchArea
            anchors.fill: parent

            pinch.target: scaleTarget
            pinch.maximumScale: 300
            pinch.minimumScale: 0.001
            onPinchStarted: {
                scaleTarget.width = imageItem.width;
                scaleTarget.height = imageItem.height;
            }

            onPinchUpdated: {
                flick.contentX += pinch.previousCenter.x - pinch.center.x;
                flick.contentY += pinch.previousCenter.y - pinch.center.y;
                var w = Math.max(scaleTarget.width * scaleTarget.scale, flick.width);
                var h = Math.max(scaleTarget.height * scaleTarget.scale, flick.height);
                flick.resizeContent(w, h, pinch.center);
            }

            onPinchFinished: {
                scaleTarget.width = imageItem.width;
                scaleTarget.height = imageItem.height;
                scaleTarget.scale = 1;
                flick.returnToBounds();
            }

            MouseArea {
                anchors.fill: parent

                property var lastClick: 0
                property point lastPosition: Qt.point(-999, -999)

                function clickDistance(position) {
                    var dx = lastPosition.x - position.x;
                    var dy = lastPosition.y - position.y;
                    return Math.sqrt(dx*dx + dy*dy);
                }

                onPressed: {
                    var now = Date.now();
                    var clickDelay = now - lastClick;
                    var position = Qt.point(mouseX, mouse.y);
                    if (clickDelay < 200 && clickDistance(position) < 50) {
                        if (flick.interactive) {
                            root.scaleImage(mouseX, mouseY, 0.5);
                        } else {
                            root.scaleImage(mouseX, mouseY, 1.9);
                        }
                    }
                    lastClick = now;
                    lastPosition = position;
                    mouse.accepted = false;
                }

                onWheel: {
                    var scale = (1.0 + wheel.angleDelta.y / 720);;
                    root.scaleImage(wheel.x, wheel.y, scale);
                }
            }
        }
    }
}
