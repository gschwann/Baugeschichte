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

#include "categoryloader.h"
#include "housemarker.h"

#include <QByteArray>
#include <QCoreApplication>
#include <QFile>
#include <QFileInfo>
#include <QGeoCoordinate>
#include <QList>
#include <QSignalSpy>
#include <QTest>
#include <QVector>

class tst_CategoryLoader : public QObject
{
    Q_OBJECT
public:
    tst_CategoryLoader(QObject* parent = 0);

private Q_SLOTS:
    void initTestCase();

    void testFail();

private:
    QString m_testDataDir;
};

tst_CategoryLoader::tst_CategoryLoader(QObject* parent)
    : QObject(parent)
{
    qRegisterMetaType<HouseMarker>("HouseMarker");
    qRegisterMetaType<QVector<HouseMarker>>("QVector<HouseMarker>");
}

void tst_CategoryLoader::initTestCase()
{
    m_testDataDir = QFileInfo(QFINDTESTDATA("category.json")).absolutePath();
    if (m_testDataDir.isEmpty()) {
        m_testDataDir = QCoreApplication::applicationDirPath();
    }
}

void tst_CategoryLoader::testFail()
{
    QFile file(m_testDataDir + "/category.json");
    file.open(QIODevice::ReadOnly);
    QByteArray buffer = file.readAll();
    file.close();

    CategoryLoader loader;
    QSignalSpy spy(&loader, SIGNAL(newHousetrail(QVector<HouseMarker>)));

    loader.loadFromJsonText(buffer);

    QCOMPARE(spy.size(), 1);
    QList<QVariant> arguments = spy.takeFirst();
    QVector<HouseMarker> markers = arguments.at(0).value<QVector<HouseMarker>>();

    QCOMPARE(markers.size(), 99);

    HouseMarker house1 = markers[0];
    QCOMPARE(house1.title(), QString("Adolf-Kolping-Gasse 14"));
    QCOMPARE(house1.location().latitude(), 47.0627202);
    QCOMPARE(house1.location().longitude(), 15.4411055);
}

QTEST_MAIN(tst_CategoryLoader)
#include "tst_categoryloader.moc"
