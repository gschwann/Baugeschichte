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

#include "markerloader.h"

#include <QByteArray>
#include <QDateTime>
#include <QDebug>
#include <QElapsedTimer>
#include <QGeoCoordinate>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QJsonValue>
#include <QList>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTimer>
#include <QUrl>
#include <QtConcurrent>

#include <cmath>
#include <limits>

class MarkerLoaderPrivate
{
public:
    MarkerLoaderPrivate()
        : m_latitude(-std::numeric_limits<double>::max())
        , m_longitude(-std::numeric_limits<double>::max())
        , m_radius(-1.0)
        , m_loadAll(false)
        , m_manager(nullptr)
        , m_loading(false)
    {
        m_lazyLoadTimer.setSingleShot(true);
        m_lazyLoadTimer.setInterval(100); // 100 ms
    }

    double m_latitude;
    double m_longitude;
    double m_radius;
    bool m_loadAll;

    QNetworkAccessManager* m_manager;
    bool m_loading;

    QList<QNetworkRequest> m_requests;

    QTimer m_lazyLoadTimer;
};

MarkerLoader::MarkerLoader(QObject* parent)
    : QObject(parent)
    , d_ptr(new MarkerLoaderPrivate())
{
    Q_D(MarkerLoader);
    d->m_manager = new QNetworkAccessManager(this);
    connect(&(d->m_lazyLoadTimer), &QTimer::timeout, this, &MarkerLoader::loadMarkers);

    connect(d->m_manager, SIGNAL(finished(QNetworkReply*)), this, SLOT(poisFinished(QNetworkReply*)));
}

MarkerLoader::~MarkerLoader()
{
    delete d_ptr;
}

double MarkerLoader::latitude() const
{
    Q_D(const MarkerLoader);
    return d->m_latitude;
}

double MarkerLoader::longitude() const
{
    Q_D(const MarkerLoader);
    return d->m_longitude;
}

void MarkerLoader::setLocation(double latitude, double longitude)
{
    Q_D(MarkerLoader);
    if (std::abs(latitude - d->m_latitude) < 1e-12 && std::abs(longitude - d->m_longitude) < 1e-12) {
        return;
    }

    d->m_latitude = latitude;
    d->m_longitude = longitude;

    Q_EMIT latitudeChanged(d->m_latitude);
    Q_EMIT longitudeChanged(d->m_longitude);
    Q_EMIT locationChanged(d->m_latitude, d->m_longitude);

    d->m_lazyLoadTimer.start();
}

double MarkerLoader::radius() const
{
    Q_D(const MarkerLoader);
    return d->m_radius;
}

void MarkerLoader::setRadius(double radius)
{
    Q_D(MarkerLoader);
    if (std::abs(radius - d->m_radius) < 1e-12) {
        return;
    }

    d->m_radius = radius;
    Q_EMIT radiusChanged(radius);

    d->m_lazyLoadTimer.start();
}

bool MarkerLoader::loadAll() const
{
    Q_D(const MarkerLoader);
    return d->m_loadAll;
}

void MarkerLoader::setLoadAll(bool loadAll)
{
    Q_D(MarkerLoader);
    if (loadAll == d->m_loadAll) {
        return;
    }

    d->m_loadAll = loadAll;
    Q_EMIT loadAllChanged(d->m_loadAll);

    d->m_lazyLoadTimer.start();
}

bool MarkerLoader::loading() const
{
    Q_D(const MarkerLoader);
    return d->m_loading;
}

void MarkerLoader::loadMarkers()
{
    Q_D(MarkerLoader);
    static double COORD_LIMIT = -9e12;
    if (d->m_latitude < COORD_LIMIT || d->m_longitude < COORD_LIMIT || d->m_radius < 0.0) {
        return;
    }

    QString locationRequest
        = QString("http://baugeschichte.at/app/v1/getData.php?action=getBuildingsBoxed&lat=%1&lon=%2&radius=")
              .arg(d->m_latitude, 0, 'f', 7)
              .arg(d->m_longitude, 0, 'f', 7);
    QString theRequest4Pois = locationRequest + QString::number(d->m_radius, 'f', 7);
    if (d->m_loadAll) {
        theRequest4Pois = theRequest4Pois % "&all=1";
    }

    //    qDebug() << theRequest4Pois;
    QNetworkRequest request = QNetworkRequest(QUrl(theRequest4Pois));
    d->m_requests.append(request);
    d->m_manager->get(request);

    setLoading(!d->m_requests.isEmpty());
}

void MarkerLoader::poisFinished(QNetworkReply* theReply)
{
    Q_D(MarkerLoader);
    QtConcurrent::run(this, &MarkerLoader::createModelAsync, theReply);

    const QNetworkRequest& request = theReply->request();
    d->m_requests.removeOne(request);
    if (!d->m_requests.empty()) {
        d->m_manager->get(d->m_requests.first());
    }

    setLoading(!d->m_requests.isEmpty());
}

void MarkerLoader::createModelAsync(QNetworkReply* theReply)
{
    //    qDebug() << Q_FUNC_INFO;
    QString theResponse;
    if (theReply) {
        if (theReply->error() == QNetworkReply::NoError) {
            const qint64 available = theReply->bytesAvailable();
            if (available > 0) {
                const QByteArray buffer = QString::fromUtf8(theReply->readAll()).toLatin1();
                QJsonParseError anError;
                QJsonDocument aDoc = QJsonDocument::fromJson(buffer, &anError);
                if (QJsonParseError::NoError != anError.error) {
                    qDebug() << anError.errorString();
                    return;
                }

                if (!aDoc.isObject()) {
                    qDebug() << "no object..." << aDoc.toVariant();
                }
                QJsonDocument doc;
                {
                    QJsonObject anInfoObject = aDoc.object();
                    QJsonArray theValueArray = anInfoObject["payload"].toArray();
                    QVector<HouseMarker> markers;
                    markers.reserve(theValueArray.size());
                    foreach (const QJsonValue& theValue, theValueArray) {
                        HouseMarker aHouseTrail;
                        QJsonObject anObj = theValue.toObject();
                        aHouseTrail.setTitle(anObj["title"].toString());
                        aHouseTrail.setLocation(QGeoCoordinate(anObj["lat"].toDouble(), anObj["lon"].toDouble()));

                        doc.setArray(anObj["cats"].toArray());

                        aHouseTrail.setCategories(doc.toJson());
                        markers.push_back(aHouseTrail);
                    }

                    Q_EMIT newHousetrail(markers);
                }
            } else
                theResponse = "empty";
        } else {
            theResponse = tr("Error: %1 status: %2")
                              .arg(theReply->errorString(),
                                  theReply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toString());
        }
        theReply->deleteLater();
    }
}

void MarkerLoader::setLoading(bool loading)
{
    Q_D(MarkerLoader);
    if (loading == d->m_loading) {
        return;
    }

    d->m_loading = loading;
    Q_EMIT loadingChanged(d->m_loading);
}
