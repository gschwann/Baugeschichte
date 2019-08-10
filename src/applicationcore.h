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

class CategoryLoader;
class HouseMarkerModel;
class MainWindow;
class MarkerLoader;

class QNetworkAccessManager;
class QNetworkReply;
class QSettings;
class QQuickView;

/**
 * The central hub for QML <-> C++ communication
 */
class ApplicationCore : public QObject
{
    Q_PROPERTY(QString mapProvider READ mapProvider WRITE setMapProvider NOTIFY mapProviderChanged)
    Q_PROPERTY(QString selectedHouse READ selectedHouse WRITE setSelectedHouse NOTIFY selectedHouseChanged)
    Q_PROPERTY(QGeoCoordinate selectedHousePosition READ selectedHousePosition NOTIFY selectedHousePositionChanged)
    Q_PROPERTY(QGeoCoordinate currentMapPosition READ currentMapPosition WRITE setCurrentMapPosition NOTIFY
            currentMapPositionChanged)
    Q_PROPERTY(bool showDetails READ showDetails WRITE setShowDetails NOTIFY showDetailsChanged)
    Q_PROPERTY(QString routeKML READ routeKML WRITE setRouteKML NOTIFY routeKMLChanged)
    Q_PROPERTY(HouseMarkerModel* categoryHouses READ categoryHouses NOTIFY categoryHousesChanged)
    Q_PROPERTY(bool showPosition READ showPosition WRITE setShowPosition NOTIFY showPositionChanged)
    Q_PROPERTY(bool followPosition READ followPosition WRITE setFollowPosition NOTIFY followPositionChanged)
    Q_PROPERTY(QString detailsLanguage READ detailsLanguage WRITE setDetailsLanguage NOTIFY detailsLanguageChanged)
    Q_PROPERTY(bool extraScaling READ extraScaling WRITE setExtraScaling NOTIFY extraScalingChanged)
    Q_PROPERTY(QString versionString READ versionString CONSTANT)
    Q_OBJECT
public:
    explicit ApplicationCore(QObject* parent = nullptr);
    ~ApplicationCore();

    void showView();
    Q_INVOKABLE void reloadUI();

    QString mapProvider() const;
    void setMapProvider(QString mapProvider);

    QString selectedHouse() const;
    Q_INVOKABLE void clearHouseSelection();
    const QGeoCoordinate& selectedHousePosition() const;

    const QGeoCoordinate& currentMapPosition() const;

    bool showDetails() const;

    Q_INVOKABLE void selectAndCenterHouse(const QString& selectedHouse);
    Q_INVOKABLE void centerSelectedHouse();

    Q_INVOKABLE void loadCategory(QString category);

    QString routeKML() const;

    HouseMarkerModel* categoryHouses() const;

    bool showPosition() const;
    void setShowPosition(bool showPosition);

    bool followPosition() const;
    void setFollowPosition(bool followPosition);

    QString detailsLanguage() const;
    void setDetailsLanguage(QString detailsLanguage);

    Q_INVOKABLE void openExternalLink(const QString& link);

    bool extraScaling() const;
    void setExtraScaling(bool extraScaling);

    QString versionString() const;

public slots:
    void handleApplicationStateChange(Qt::ApplicationState state);

    void setSelectedHouse(const QString& selectedHouse);
    void setCurrentMapPosition(const QGeoCoordinate& currentMapPosition);

    void setShowDetails(bool showDetails);

    void setRouteKML(const QString& routeKML);

    void saveMapPosition();

signals:
    void mapProviderChanged(QString mapProvider);
    void selectedHouseChanged(QString selectedHouse);
    void selectedHousePositionChanged(QGeoCoordinate selectedHousePosition);
    void currentMapPositionChanged(QGeoCoordinate currentMapPosition);
    void showDetailsChanged(bool showDetails);
    void requestFullZoomIn();
    void routeKMLChanged(QString routeKML);
    void categoryHousesChanged(HouseMarkerModel* categoryHouses);
    void showPositionChanged(bool showPosition);
    void followPositionChanged(bool followPosition);
    void detailsLanguageChanged(QString detailsLanguage);
    void extraScalingChanged(bool extraScaling);

private slots:
    void doReloadUI();
    void handleLoadedHouseCoordinates(QNetworkReply* reply);

private:
    QString mainQMLFile() const;
    void saveMarkers();
    void loadMarkers();

    MainWindow* m_view;
    HouseMarkerModel* m_houseMarkerModel;
    MarkerLoader* m_markerLoader;
    QString m_selectedHouse;
    QGeoCoordinate m_selectedHousePosition;
    QGeoCoordinate m_currentMapPosition;
    bool m_showDetails;
    QNetworkAccessManager* m_housePositionLoader;
    QString m_routeKML;
    CategoryLoader* m_categoryLoader;
    HouseMarkerModel* m_categoryMarkerModel;
    bool m_showPosition;
    bool m_followPosition;
    QString m_detailsLanguage;
    QSettings* m_settings;
    bool m_extraScaling;
};

#endif // APPLICATIONCORE_H
