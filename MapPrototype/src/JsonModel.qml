import QtQuick 2.4

Item {
    id: root

    property variant model: housetrailDetails
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

    onPhraseChanged: internal.reload();

    ListModel { id: housetrailDetails }

    QtObject {
        id: internal

        property int status: XMLHttpRequest.UNSENT
        property bool wasLoading: false
        property string error: ""

        function encodePhrase(x) {
            return (shouldEncode) ? encodeURIComponent(x) : x;
        }

        function reload() {
            model.clear();
            error = "";

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
                        try {
                            var searchResult = JSON.parse(req.responseText);
                            if (searchResult.errors !== undefined) {
                                error = qsTr("Error fetching searchresults: ") + searchResult.errors[0].message;
                                console.log(error);
                            } else {
                               newobject(searchResult)
                            }
                        } catch (e) {
                            error = qsTr("Jason parse error for fetched URL: ") + searchPhrase +
                                    "\n" + qsTr("Fetched text was: ") + req.responseText;
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