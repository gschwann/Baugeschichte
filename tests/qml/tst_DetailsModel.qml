

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
import QtTest

TestCase {
    name: "DetailsModelTests"

    DetailsModel {
        id: detailsModel
        //        searchString: "../../../Baugeschichte/tests/qml/data/"
        searchString: "/home/travis/build/gschwann/Baugeschichte/tests/qml/data/"
    }

    function cleanup() {
        detailsModel.clear()
        detailsModel.phrase = ""
        detailsModel.title = ""
    }

    function test_load() {
        detailsModel.title = "Hauptplatz_1"
        detailsModel.phrase = "details01.json"
        tryCompare(detailsModel, "isLoading", false, 1000,
                   "Timed out readong json file")

        compare(detailsModel.modelDE.count, 3)
        compare(detailsModel.modelEN.count, 3)
        compare(detailsModel.modelS1.count, 0)

        compare(detailsModel.imagesModel.count, 5)
        compare(detailsModel.imagesModel.get(0).section, 0)
        compare(detailsModel.imagesModel.get(3).section, 1)
        compare(detailsModel.imagesModel.get(4).section, 2)
    }

    function test_prevent_double_load() {
        detailsModel.title = "Hauptplatz_1"
        detailsModel.phrase = "details01.json"
        detailsModel.title = ""
        detailsModel.phrase = ""
        detailsModel.title = "Hauptplatz_1"
        detailsModel.phrase = "details01.json"
        tryCompare(detailsModel, "isLoading", false, 1000,
                   "Timed out readong json file")

        compare(detailsModel.modelDE.count, 3)
        compare(detailsModel.imagesModel.count, 5)
    }

    function test_do_not_load_other_details() {
        detailsModel.title = "Hauptplatz_2"
        detailsModel.phrase = "details01.json"
        tryCompare(detailsModel, "isLoading", false, 1000,
                   "Timed out readong json file")

        compare(detailsModel.modelDE.count, 0)
        compare(detailsModel.modelEN.count, 0)
        compare(detailsModel.modelS1.count, 0)
    }

    function test_convert_to_html_external_link() {
        detailsModel.title = "Liebiggasse_9"
        detailsModel.phrase = "details_external_link.json"
        tryCompare(detailsModel, "isLoading", false, 1000,
                   "Timed out readong json file")

        var detailText = detailsModel.modelDE.get(0).detailText
        var linkStart = detailText.indexOf("<a ")
        verify(linkStart > -1)

        var link = detailText.substr(linkStart, 115)
        var origLink = "<a href=\"http://www.gat.st/pages/de/nachrichten/5178.htm\">Artikel zur Aufstockung auf gat.st Artikel auf gat.st</a>"
        compare(link, origLink)
    }

    function test_convert_to_html_internal_link() {
        detailsModel.title = "Schillerstra\u00dfe_27"
        detailsModel.phrase = "details_internal_link.json"
        tryCompare(detailsModel, "isLoading", false, 1000,
                   "Timed out readong json file")

        var detailText = detailsModel.modelDE.get(0).detailText
        var linkStart = detailText.indexOf("<a ")
        verify(linkStart > -1)

        var link = detailText.substr(linkStart, 60)
        var origLink = "<a href=\"internal://Schillerstra\u00dfe 29\">Schillerstra\u00dfe 29</a>"
        compare(link, origLink)
    }

    function test_convert_to_html_bold() {
        detailsModel.title = "Dummystreet_1"
        detailsModel.phrase = "details_formats.json"
        tryCompare(detailsModel, "isLoading", false, 1000,
                   "Timed out readong json file")

        var detailText = detailsModel.modelDE.get(0).detailText
        var linkStart = detailText.indexOf("<b>")
        verify(linkStart > -1)

        var boldText = detailText.substr(linkStart, 22)
        var origText = "<b>Wolfgang Alkier</b>"
        compare(boldText, origText)
    }

    function test_convert_to_html_italic() {
        detailsModel.title = "Dummystreet_1"
        detailsModel.phrase = "details_formats.json"
        tryCompare(detailsModel, "isLoading", false, 1000,
                   "Timed out readong json file")

        var detailText = detailsModel.modelDE.get(0).detailText
        var linkStart = detailText.indexOf("<i>")
        verify(linkStart > -1)

        var boldText = detailText.substr(linkStart, 21)
        var origText = "<i>Lisenenordnung</i>"
        compare(boldText, origText)
    }

    function test_convert_to_html_bold_italic() {
        detailsModel.title = "Dummystreet_1"
        detailsModel.phrase = "details_formats.json"
        tryCompare(detailsModel, "isLoading", false, 1000,
                   "Timed out readong json file")

        var detailText = detailsModel.modelDE.get(0).detailText
        var linkStart = detailText.indexOf("<b><i>")
        verify(linkStart > -1)

        var boldText = detailText.substr(linkStart, 26)
        var origText = "<b><i>Parapetzonen</i></b>"
        compare(boldText, origText)
    }
}
