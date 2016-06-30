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

#ifndef APPLICATIONCORE_H
#define APPLICATIONCORE_H

#include <QGeoCoordinate>
#include <QObject>
#include <QString>

class MarkerLoader;
class HouseMarkerModel;

class QNetworkAccessManager;
class QNetworkReply;
class QQuickView;
class QSortFilterProxyModel;

/**
 * The central hub for QML <-> C++ communication
 */
class ApplicationCore : public QObject
{
    Q_PROPERTY(QString mapProvider READ mapProvider WRITE setMapProvider NOTIFY mapProviderChanged)
    Q_PROPERTY(QString selectedHouse READ selectedHouse WRITE setSelectedHouse NOTIFY selectedHouseChanged)
    Q_PROPERTY(QGeoCoordinate currentMapPosition READ currentMapPosition WRITE setCurrentMapPosition NOTIFY
            currentMapPositionChanged)
    Q_PROPERTY(bool showDetails READ showDetails WRITE setShowDetails NOTIFY showDetailsChanged)
    Q_PROPERTY(QString routeKML READ routeKML WRITE setRouteKML NOTIFY routeKMLChanged)
    Q_OBJECT
public:
    explicit ApplicationCore(QObject* parent = 0);
    ~ApplicationCore();

    void showView();
    Q_INVOKABLE void reloadUI();

    QString mapProvider() const;
    void setMapProvider(QString mapProvider);

    QString selectedHouse() const;
    const QGeoCoordinate& currentMapPosition() const;

    bool showDetails() const;

    Q_INVOKABLE void centerSelectedHouse();

    QString routeKML() const;

public slots:
    void handleApplicationStateChange(Qt::ApplicationState state);

    void setSelectedHouse(const QString& selectedHouse);
    void setCurrentMapPosition(const QGeoCoordinate& currentMapPosition);

    void setShowDetails(bool showDetails);

    void setRouteKML(const QString& routeKML);

signals:
    void mapProviderChanged(QString mapProvider);
    void selectedHouseChanged(QString selectedHouse);
    void currentMapPositionChanged(QGeoCoordinate currentMapPosition);
    void showDetailsChanged(bool showDetails);
    void requestFullZoomIn();
    void routeKMLChanged(QString routeKML);

private slots:
    void doReloadUI();
    void handleLoadedHouseCoordinates(QNetworkReply* reply);

private:
    QString mainQMLFile() const;
    int calculateScreenDpi() const;
    void saveMarkers();
    void loadMarkers();

    QQuickView* m_view;
    HouseMarkerModel* m_houseMarkerModel;
    MarkerLoader* m_markerLoader;
    QSortFilterProxyModel* m_detailsProxyModel;
    int m_screenDpi;
    QString m_mapProvider;
    QString m_selectedHouse;
    QGeoCoordinate m_currentMapPosition;
    bool m_showDetails;
    QNetworkAccessManager* m_housePositionLoader;
    QString m_routeKML;
};

#endif // APPLICATIONCORE_H
