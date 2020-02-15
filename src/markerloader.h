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

#ifndef MARKERLOADER
#define MARKERLOADER

#include "housemarker.h"

#include <QObject>
#include <QVector>

class MarkerLoaderPrivate;
class QNetworkReply;

/**
 * Loads markers for it's given position and radius
 * The loading is triggered (after a short delay) automaticly when the position/radius changes
 */
class MarkerLoader : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double latitude READ latitude NOTIFY latitudeChanged)
    Q_PROPERTY(double longitude READ longitude NOTIFY longitudeChanged)
    Q_PROPERTY(double radius READ radius WRITE setRadius NOTIFY radiusChanged)
    Q_PROPERTY(bool loadAll READ loadAll WRITE setLoadAll NOTIFY loadAllChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)

public:
    explicit MarkerLoader(QObject* parent = 0);
    ~MarkerLoader();

    double latitude() const;
    double longitude() const;
    Q_INVOKABLE void setLocation(double latitude, double longitude);

    double radius() const;
    void setRadius(double radius);

    bool loadAll() const;
    void setLoadAll(bool loadAll);

    bool loading() const;

Q_SIGNALS:
    void latitudeChanged(double);
    void longitudeChanged(double);
    void locationChanged(double, double);
    void radiusChanged(double);
    void newHousetrail(QVector<HouseMarker> aNewHouseTrail);
    void loadingChanged(bool loading);

    void loadAllChanged(bool loadAll);

private Q_SLOTS:
    void loadMarkers();
    void poisFinished(QNetworkReply* theReply);
    void createModelAsync(QNetworkReply* theReply);

private:
    void setLoading(bool loading);

    Q_DISABLE_COPY(MarkerLoader)
    Q_DECLARE_PRIVATE(MarkerLoader)
    MarkerLoaderPrivate* const d_ptr;
};

#endif // MARKERLOADER
