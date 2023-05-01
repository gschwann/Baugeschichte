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

import QtQuick
import QtQml.XmlListModel
import QtLocation
import QtPositioning

MapPolyline {
    id: root

    line.width: 3
    line.color: "red"

    // Url for the KML file to show
    property url source
    onSourceChanged: {
        if (source == "") {
            clear();
        }
    }

    property bool loading: false

    XmlListModel {
        id: kmlLoaderV1

        source: root.source

        //namespaceDeclarations: "declare default element namespace 'http://earth.google.com/kml/2.0';"
        query: "/kml/Document/Folder/Placemark/LineString"

        //XmlRole { name: "coordinates"; query: "coordinates/string()" }
        XmlListModelRole { name: "coordinates"; attributeName: "coordinates/string()" }

        onStatusChanged: {
            if (status == XmlListModel.Ready) {
                parseKML();
            }
            if (status == XmlListModel.Error) {
                console.warn(qsTr("Error loading KML file ") + source + " : " + errorString())
            }

            checkLoading();
        }
    }

    XmlListModel {
        id: kmlLoaderV2

        source: root.source

        //namespaceDeclarations: "declare default element namespace 'http://www.opengis.net/kml/2.2';"
        query: "/kml/Document/Folder/Placemark/LineString"

        //XmlRole { name: "coordinates"; query: "coordinates/string()" }
        XmlListModelRole { name: "coordinates"; attributeName: "coordinates/string()" }

        onStatusChanged: {
            if (status == XmlListModel.Ready) {
                parseKML();
            }
            if (status == XmlListModel.Error) {
                console.warn(qsTr("Error loading KML file ") + source + " : " + errorString())
            }

            checkLoading();
        }
    }

    XmlListModel {
        id: kmlLoaderV3

        source: root.source

        //namespaceDeclarations: "declare default element namespace 'http://earth.google.com/kml/2.2';"
        query: "/kml/Document/Placemark/LineString"

        //XmlRole { name: "coordinates"; query: "coordinates/string()" }
        XmlListModelRole { name: "coordinates"; attributeName: "coordinates/string()" }

        onStatusChanged: {
            if (status == XmlListModel.Ready) {
                parseKML();
            }
            if (status == XmlListModel.Error) {
                console.warn(qsTr("Error loading KML file ") + source + " : " + errorString())
            }

            checkLoading();
        }
    }

    function clear()
    {
        while (root.pathLength() > 0) {
            root.removeCoordinate(0);
        }
        root.visible = false;
    }

    function parseKML()
    {
        if (kmlLoaderV1.count === 0 && kmlLoaderV2.count === 0 && kmlLoaderV3.count === 0) {
            checkLoading();
            return;
        }

        clear();

        var separator = " ";
        var kmlLoader = kmlLoaderV1;
        if (kmlLoaderV2.count !== 0) {
            kmlLoader = kmlLoaderV2;
        }
        if (kmlLoaderV3.count !== 0) {
            kmlLoader = kmlLoaderV3;
            separator = "\n";
        }

        for (var line=0; line<kmlLoader.count; ++line) {
            var coordinates = kmlLoader.get(line).coordinates.trim().split(separator);
            for (var i=0; i<coordinates.length; ++i) {
                var coords = coordinates[i].split(",");
                var position = QtPositioning.coordinate(coords[1], coords[0]);
                root.addCoordinate(position);
            }
        }

        checkLoading();
        root.visible = true;
    }

    function checkLoading() {
        root.loading = kmlLoaderV1.status == XmlListModel.Loading ||
                kmlLoaderV1.status == XmlListModel.Loading ||
                kmlLoaderV3.status == XmlListModel.Loading
    }
}
