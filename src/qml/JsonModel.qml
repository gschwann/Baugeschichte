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

Item {
    id: root

    property variant model: jsonModel
    property string phrase : ""
    property string searchString: ""
    property bool shouldEncode: true//default. due to problems with encoding on serverside. switched off in routesearch

    readonly property int status: internal.status
    readonly property bool isLoading: status === XMLHttpRequest.LOADING
    readonly property bool wasLoading: internal.wasLoading

    // String describing the last error
    // Is empty if the last request was successful
    readonly property string error: internal.error

    signal isLoaded
    signal newobject(var magneto)

    function clear() {
        jsonModel.clear();
        internal.error = "";
    }

    onPhraseChanged: {
        internal.reload();
    }

    ListModel { id: jsonModel }

    QtObject {
        id: internal

        property int status: XMLHttpRequest.UNSENT
        property bool wasLoading: false
        property string error: ""

        function encodePhrase(x) {
            return (shouldEncode) ? encodeURIComponent(x) : x;
        }

        function reload() {
            root.clear();

            if (phrase == "") {
                return;
            }

            status = XMLHttpRequest.LOADING;

            var req = new XMLHttpRequest;
            var searchPhrase = searchString.trim() + encodePhrase(phrase.trim()) //escape(phrase)
            req.open("GET", searchPhrase);

            req.onreadystatechange = function() {
                if (req.readyState === XMLHttpRequest.DONE) {
                    if (req.status == 200)
                    {
                        var responseText = req.responseText;
//                        console.log("responseText: "+responseText)

                        try {
                            var searchResult = JSON.parse(responseText);
                            if (searchResult.errors !== undefined) {
                                error = qsTr("Error fetching searchresults: ") + searchResult.errors[0].message;
                                console.log(error);
                            } else {
                               newobject(searchResult)
                            }
                        } catch (e) {
                            error = qsTr("Json parse error for fetched URL: ") + searchPhrase +
                                    "\n" + qsTr("Fetched text was: ") + responseText;
                            console.log(error);
                        }
                    } else {
                        error = qsTr("Error loading from URL: ") + searchPhrase
                        console.log(error);
                    }

                    if (wasLoading == true)
                        root.isLoaded()
                }
                status = req.readyState;
                wasLoading = (status === XMLHttpRequest.LOADING);
            }

            req.send();
        }
    }
}
