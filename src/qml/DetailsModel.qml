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

JsonModel {
    id: root

    property string title: ""

    property variant modelDE: model
    property ListModel modelEN: ListModel {}
    property ListModel modelS1: ListModel {}

    property ListModel imagesModel: ListModel {}

    function clear() {
        modelDE.clear();
        modelEN.clear();
        modelS1.clear();
        imagesModel.clear();
    }

    searchString: "http://baugeschichte.at/app/v1/getData.php?action=getBuildingDetail&name="

    onPhraseChanged: {
        clear();
    }

    onNewobject: {
        if (magneto.version !== "1") {
            console.warn("Unknown version for details: "+magneto.version)
        }

        if (magneto.title !== root.title) {
            // reply is from annother (old) request
            console.warn("Title do not match: "+magneto.title + " != " + root.title)
            return;
        }

        clear();
        var section = -1;

        for (var key in magneto.payload) {
            var jsonObject = magneto.payload[key];
            if (jsonObject.title === null) {
                jsonObject.title = ""
            }

            var resultObject = {}
            resultObject.title = jsonObject.title;

            if (jsonObject.title.trim() !== "Info") {
                resultObject.detailText = convertToHTML(jsonObject.text);

                if (jsonObject.lang === undefined) {
                    jsonObject.lang = ""
                }

                if (jsonObject.lang === "de") {
                    ++section;
                    model.append(resultObject);
                } else if (jsonObject.lang === "en") {
                    modelEN.append(resultObject);
                } else {
                    modelS1.append(resultObject);
                }

                for (var idx in jsonObject.images) {
                    var img = jsonObject.images[idx];
                    img.section = section;
                    imagesModel.append(img);
                }
            }
        }
    }
    onErrorChanged: {
        console.log("Error: " + error);
        title = "";
        if (error !== "") {
            console.log("Error: " + error);
            var jsonObject = {"detailText": error, "title": qsTr("Load error")};
            model.append(jsonObject);
        }
    }

    function convertToHTML(input) {
        input = filterUnused(input);
        input = convertInternalLink(input, 0);
        input = convertExternalLink(input, 0);
        input = convertBoldItalicText(input, 0);
        input = convertBoldText(input, 0);
        input = convertItalicText(input, 0);
        input = convertHeading1Text(input, 0);
        input = convertHeading2Text(input, 0);
        input = convertHeading3Text(input, 0);
        input = convertHeading4Text(input, 0);
        return "<HTML><BODY>"+input+"</BODY></HTML>";
    }

    function filterUnused(input) {
        var unusedTags = ["<ref>", "</ref>"];
        for (var idx in unusedTags) {
            var tag = unusedTags[idx];

            var startIdx = 0;
            while (startIdx >= 0) {
                startIdx = input.indexOf(tag, startIdx);
                if (startIdx >= 0) {
                    input = input.substring(0, startIdx) + input.substring(startIdx + tag.length, input.length);
                }
            }
        }
        return input;
    }

    function getTokenSplit(input, startIdx, startTag, endTag) {
        var tagIdx = input.indexOf(startTag, startIdx)
        if (tagIdx === -1) {
            return [];
        }

        var tagEndIdx = input.indexOf(endTag, tagIdx + startTag.length)
        if (tagEndIdx === -1) {
            return [];
        }

        var preToken = input.substring(0, tagIdx);
        var tocken = input.substring(tagIdx + startTag.length, tagEndIdx)
        var postToken = input.substring(tagEndIdx + endTag.length, input.length)

        return [preToken, tocken, postToken];
    }

    function convertExternalLink(input, startIdx) {
        var splitup = getTokenSplit(input, startIdx, "[", "]")
        if (splitup.length === 3) {
            var preLink = splitup[0];
            var link = splitup[1];
            var postLink = splitup[2];

            var linkText = link;
            var linkLink = link;
            var linkTerm = link.indexOf(" ");
            if (linkTerm > -1) {
                linkLink = link.substring(0, linkTerm);
                linkText = link.substring(linkTerm+1, link.length);
            }
            var output = preLink + "<a href=\"" + linkLink + "\">" + linkText + "</a>" + postLink;
            return convertExternalLink(output, output.length - postLink.length);
        } else {
            return input;
        }
    }

    function convertInternalLink(input, startIdx) {
        var splitup = getTokenSplit(input, startIdx, "[[", "]]")
        if (splitup.length === 3) {
            var preLink = splitup[0];
            var link = splitup[1];
            var postLink = splitup[2];

            if (link.substring(0, 5) === "http:" || link.substring(0, 6) === "https:") {
                // is an  external link
                var linkText = link;
                var linkLink = link;
                var linkTerm = link.indexOf(" ");
                if (linkTerm > -1) {
                    linkLink = link.substring(0, linkTerm);
                    linkText = link.substring(linkTerm+1, link.length);
                }
                var output = preLink + "<a href=\"" + linkLink + "\">" + linkText + "</a>" + postLink;
                return convertExternalLink(output, output.length - postLink.length);
            }

            var output = preLink + "<a href=\"internal://" + link + "\">" + link + "</a>" + postLink;
            return convertInternalLink(output, output.length - postLink.length);
        } else {
            return input;
        }
    }

    function convertBoldText(input, startIdx) {
        var splitup = getTokenSplit(input, startIdx, "'''", "'''")
        if (splitup.length === 3) {
            var preText = splitup[0];
            var text = splitup[1];
            var postText = splitup[2];
            var output = preText + "<b>" + text + "</b>" + postText;
            return convertInternalLink(output, output.length - postText.length);
        } else {
            return input;
        }
    }

    function convertItalicText(input, startIdx) {
        var splitup = getTokenSplit(input, startIdx, "''", "''")
        if (splitup.length === 3) {
            var preText = splitup[0];
            var text = splitup[1];
            var postText = splitup[2];
            var output = preText + "<i>" + text + "</i>" + postText;
            return convertInternalLink(output, output.length - postText.length);
        } else {
            return input;
        }
    }

    function convertBoldItalicText(input, startIdx) {
        var splitup = getTokenSplit(input, startIdx, "'''''", "'''''")
        if (splitup.length === 3) {
            var preText = splitup[0];
            var text = splitup[1];
            var postText = splitup[2];
            var output = preText + "<b><i>" + text + "</i></b>" + postText;
            return convertInternalLink(output, output.length - postText.length);
        } else {
            return input;
        }
    }

    function convertHeading1Text(input, startIdx) {
        var splitup = getTokenSplit(input, startIdx, "==", "==")
        if (splitup.length === 3) {
            var preText = splitup[0];
            var text = splitup[1];
            var postText = splitup[2];
            var output = preText + "<h1>" + text + "</h1>" + postText;
            return convertInternalLink(output, output.length - postText.length);
        } else {
            return input;
        }
    }

    function convertHeading2Text(input, startIdx) {
        var splitup = getTokenSplit(input, startIdx, "===", "===")
        if (splitup.length === 3) {
            var preText = splitup[0];
            var text = splitup[1];
            var postText = splitup[2];
            var output = preText + "<h2>" + text + "</h2>" + postText;
            return convertInternalLink(output, output.length - postText.length);
        } else {
            return input;
        }
    }

    function convertHeading3Text(input, startIdx) {
        var splitup = getTokenSplit(input, startIdx, "====", "====")
        if (splitup.length === 3) {
            var preText = splitup[0];
            var text = splitup[1];
            var postText = splitup[2];
            var output = preText + "<h3>" + text + "</h3>" + postText;
            return convertInternalLink(output, output.length - postText.length);
        } else {
            return input;
        }
    }

    function convertHeading4Text(input, startIdx) {
        var splitup = getTokenSplit(input, startIdx, "=====", "=====")
        if (splitup.length === 3) {
            var preText = splitup[0];
            var text = splitup[1];
            var postText = splitup[2];
            var output = preText + "<h4>" + text + "</h4>" + postText;
            return convertInternalLink(output, output.length - postText.length);
        } else {
            return input;
        }
    }
}
