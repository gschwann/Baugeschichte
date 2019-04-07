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

import QtQuick 2.4
import "./"

JsonModel {
    id: root

    // Even "unlimited" results show only 100 items - bot protection of the server
    property bool limitResults: true
    onLimitResultsChanged: console.log("limitResults:" + limitResults)

    onNewobject: {
        if (magneto.length < 2) {
            console.warn("Wrong search result from " + searchString + " : " + magneto);
            return;
        }

        var titles = magneto[1];
        var idx = 0;
        for (var key in titles) {
            var jsonObject = {};
            jsonObject.title = titles[key];

            var url = magneto[3][idx];
            jsonObject.url = url;
            jsonObject.isBuilding = url != "";

            model.append(jsonObject);
        }
    }

    readonly property string __url: "http://baugeschichte.at/api.php?action=opensearch&"
    readonly property string __format: "format=json&formatversion=2"
    readonly property string __namespace: "&namespace=0"
    readonly property string __resultLimit: "&limit=" + (limitResults ? "20" : "100")
    searchString: __url + __format + __namespace + __resultLimit + "&search="
}
