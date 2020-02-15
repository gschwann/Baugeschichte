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
import QtPositioning 5.5
import QtLocation 5.4

Item {
    id: root
    property string searchFor:""

    onSearchForChanged: simpleMapSearchModel.phrase = searchFor//" "

    readonly property alias loading: simpleMapSearchModel.isLoading

    property var routeHouses: []

    readonly property var routeArea: __routeArea

    function isRouteHouse(title) {
        for (var i=0; i<routeHouses.length; ++i) {
            if (title === routeHouses[i].title) {
                return true;
            }
        }
        return false;
    }

    function reset() {
        routeHouses = [];
        searchFor = "";
    }

    visible: false

    property var __routeArea: QtPositioning.rectangle()

    JsonModel {
        id: simpleMapSearchModel
        shouldEncode: false //due to searchapi problems when encoding routes...
        onNewobject: {
            root.routeHouses = [];
            var minLat = Number.MAX_VALUE;
            var maxLat = -Number.MAX_VALUE;
            var minLon = Number.MAX_VALUE;
            var maxLon = -Number.MAX_VALUE;

            for (var key in magneto.payload) {
                var jsonObject = magneto.payload[key]
                if (jsonObject.lat === 0) continue;
                if (jsonObject.lon === 0) continue;

                var modelObject = {
                    "dbId": jsonObject.id,
                    "title": jsonObject.title,
                    "coord": {"latitude":jsonObject.lat, "longitude": jsonObject.lon}
                }
                routeHouses.push(modelObject)

                minLat = Math.min(jsonObject.lat, minLat);
                maxLat = Math.max(jsonObject.lat, maxLat);
                minLon = Math.min(jsonObject.lon, minLon);
                maxLon = Math.max(jsonObject.lon, maxLon);

                var area = QtPositioning.rectangle(
                            QtPositioning.coordinate(maxLat, minLon),
                            QtPositioning.coordinate(minLat, maxLon));
                __routeArea = QtPositioning.rectangle(area.center,
                                                      area.width * 1.1,
                                                      area.height * 1.1);
            }

            AppCore.routeKML = magneto.kml;
        }
        searchString: "http://baugeschichte.at/app/v1/getData.php?action=getRoutePoints&name="

        onIsLoadingChanged: {
            if (isLoading) {
                root.routeHouses = [];
            }
        }
    }
}
