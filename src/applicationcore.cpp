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

#include "applicationcore.h"
#include "categoryloader.h"
#include "houselocationfilter.h"
#include "housemarker.h"
#include "housemarkermodel.h"
#include "mainwindow.h"
#include "markerloader.h"

#include <QApplication>
#include <QByteArray>
#include <QDateTime>
#include <QDebug>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QJsonValue>
#include <QJsonValueRef>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickView>
#include <QSettings>
#include <QSslSocket>
#include <QStandardPaths>
#include <QUrl>
#include <QVariant>
#include <QVector>
#include <QtQml>

ApplicationCore::ApplicationCore(QObject* parent)
    : QObject(parent)
    , m_view(new MainWindow())
    , m_houseMarkerModel(new HouseMarkerModel(this))
    , m_markerLoader(new MarkerLoader(this))
    , m_selectedHouse("")
    , m_selectedHousePosition(-1.0, -1.0)
    , m_currentMapPosition(-1.0, -1.0)
    , m_showDetails(false)
    , m_housePositionLoader(new QNetworkAccessManager(this))
    , m_categoryLoader(new CategoryLoader(this))
    , m_categoryMarkerModel(new HouseMarkerModel(this))
    , m_showPosition(false)
    , m_followPosition(false)
    , m_detailsLanguage("DE")
    , m_settings(new QSettings(this))
    , m_extraScaling(false)
{
    qRegisterMetaType<HouseMarker>("HouseMarker");
    qRegisterMetaType<QVector<HouseMarker>>("QVector<HouseMarker>");
    qmlRegisterType<HouseLocationFilter>("Baugeschichte", 1, 0, "HouseLocationFilter");
    qmlRegisterUncreatableType<HouseMarkerModel>("HouseMarkerModel", 1, 0, "HouseMarkerModel", "");

    m_extraScaling = m_settings->value("MapExtraScaling", false).toBool();
    QPointF lastPos = m_settings->value("CurrentMapPosition", QVariant::fromValue(QPointF(47.0667, 15.45))).toPointF();
    m_currentMapPosition.setLatitude(lastPos.x());
    m_currentMapPosition.setLongitude(lastPos.y());

    m_view->setWidth(1024);
    m_view->setHeight(800);
    m_view->setResizeMode(QQuickView::SizeRootObjectToView);

    QQmlEngine* engine = m_view->engine();
    connect(engine, &QQmlEngine::quit, qApp, &QApplication::quit);
    QQmlContext* context = engine->rootContext();
    context->setContextProperty(QStringLiteral("appCore"), this);
    context->setContextProperty(QStringLiteral("markerLoader"), m_markerLoader);
    context->setContextProperty(QStringLiteral("houseTrailModel"), m_houseMarkerModel);
    context->setContextProperty(QStringLiteral("categoryLoader"), m_categoryLoader);
    context->setContextProperty(QStringLiteral("mainView"), m_view);

    connect(m_markerLoader, &MarkerLoader::newHousetrail, m_houseMarkerModel, &HouseMarkerModel::append);

    connect(m_categoryLoader, &CategoryLoader::newHousetrail, m_categoryMarkerModel, &HouseMarkerModel::append);

    connect(
        m_housePositionLoader, &QNetworkAccessManager::finished, this, &ApplicationCore::handleLoadedHouseCoordinates);

    loadMarkers();
}

ApplicationCore::~ApplicationCore()
{
    saveMapPosition();
    saveMarkers();
    delete (m_view);
    m_settings->sync();
}

void ApplicationCore::showView()
{
    m_view->setSource(mainQMLFile());
    m_view->show();
}

void ApplicationCore::reloadUI()
{
    QMetaObject::invokeMethod(this, "doReloadUI", Qt::QueuedConnection);
}

QString ApplicationCore::mapProvider() const
{
#ifdef Q_OS_IOS
    static QVariant defaultProvider = QVariant("osm");
#else
    static QVariant defaultProvider = QVariant("mapboxGl");
    const QString sslVersion = QSslSocket::sslLibraryVersionString();
    if (sslVersion.startsWith("OpenSSL") && sslVersion.mid(8, 6) == "1.0.1e") {
        // An old system version of ssl is used?
        // Use MapBox, as this does not use SSL
        qDebug() << "Old SSL version using Mapbox as map provider";
        defaultProvider = QVariant("mapbox");
    }
#endif
    return m_settings->value("MapProvider", defaultProvider).toString();
}

void ApplicationCore::setMapProvider(QString mapProvider)
{
    if (mapProvider == this->mapProvider()) {
        return;
    }

    saveMapPosition();
    m_settings->setValue("MapProvider", mapProvider);
    m_settings->sync();
    emit mapProviderChanged(mapProvider);
}

QString ApplicationCore::selectedHouse() const
{
    return m_selectedHouse;
}

void ApplicationCore::clearHouseSelection()
{
    setSelectedHouse(QStringLiteral(""));
}

const QGeoCoordinate& ApplicationCore::selectedHousePosition() const
{
    return m_selectedHousePosition;
}

const QGeoCoordinate& ApplicationCore::currentMapPosition() const
{
    return m_currentMapPosition;
}

bool ApplicationCore::showDetails() const
{
    return m_showDetails;
}

void ApplicationCore::selectAndCenterHouse(const QString& selectedHouse)
{
    setSelectedHouse(selectedHouse);
    centerSelectedHouse();
}

void ApplicationCore::centerSelectedHouse()
{
    HouseMarker* house = m_houseMarkerModel->getHouseByTitle(m_selectedHouse);
    if (house != nullptr) {
        setCurrentMapPosition(house->location());
        emit requestFullZoomIn();
    } else {
        QString requestString = QString(
            "http://baugeschichte.at/api.php?action=ask&query=[[%1]]|%3FKoordinaten|%3FPostleitzahl&format=json")
                                    .arg(m_selectedHouse);
        QNetworkRequest request = QNetworkRequest(QUrl(requestString));
        m_housePositionLoader->get(request);
    }
}

void ApplicationCore::loadCategory(QString category)
{
    m_categoryMarkerModel->clear();
    m_categoryLoader->loadCategory(category);
}

QString ApplicationCore::routeKML() const
{
    return m_routeKML;
}

HouseMarkerModel* ApplicationCore::categoryHouses() const
{
    return m_categoryMarkerModel;
}

bool ApplicationCore::showPosition() const
{
    return m_showPosition;
}

void ApplicationCore::setShowPosition(bool showPosition)
{
    if (m_showPosition == showPosition) {
        return;
    }

    m_showPosition = showPosition;
    emit showPositionChanged(m_showPosition);
}

bool ApplicationCore::followPosition() const
{
    return m_followPosition;
}

void ApplicationCore::setFollowPosition(bool followPosition)
{
    if (m_followPosition == followPosition) {
        return;
    }

    m_followPosition = followPosition;
    emit followPositionChanged(m_followPosition);
}

QString ApplicationCore::detailsLanguage() const
{
    return m_detailsLanguage;
}

void ApplicationCore::setDetailsLanguage(QString detailsLanguage)
{
    if (m_detailsLanguage == detailsLanguage) {
        return;
    }

    m_detailsLanguage = detailsLanguage;
    emit detailsLanguageChanged(m_detailsLanguage);
}

void ApplicationCore::openExternalLink(const QString& link)
{
    QDesktopServices::openUrl(QUrl(link));
}

bool ApplicationCore::extraScaling() const
{
    return m_extraScaling;
}

void ApplicationCore::setExtraScaling(bool extraScaling)
{
    if (m_extraScaling == extraScaling) {
        return;
    }

    m_extraScaling = extraScaling;
    m_settings->sync();
    emit extraScalingChanged(m_extraScaling);
}

void ApplicationCore::handleApplicationStateChange(Qt::ApplicationState state)
{
    switch (state) {
    case Qt::ApplicationHidden:
    case Qt::ApplicationInactive:
        saveMarkers();
        break;
    case Qt::ApplicationActive:
        loadMarkers();
        break;
    default:
        break;
    }
}

void ApplicationCore::setSelectedHouse(const QString& selectedHouse)
{
    if (m_selectedHouse == selectedHouse) {
        return;
    }

    m_selectedHouse = selectedHouse;
    emit selectedHouseChanged(selectedHouse);

    HouseMarker* house = m_houseMarkerModel->getHouseByTitle(m_selectedHouse);
    if (house != nullptr) {
        m_selectedHousePosition = house->location();
        emit selectedHousePositionChanged(m_selectedHousePosition);
    }

    if (m_selectedHouse.isEmpty()) {
        setShowDetails(false);
    }
}

void ApplicationCore::setCurrentMapPosition(const QGeoCoordinate& currentMapPosition)
{
    if (m_currentMapPosition == currentMapPosition) {
        return;
    }

    m_currentMapPosition = currentMapPosition;
    emit currentMapPositionChanged(currentMapPosition);
}

void ApplicationCore::setShowDetails(bool showDetails)
{
    if (m_showDetails == showDetails) {
        return;
    }

    m_showDetails = showDetails;
    emit showDetailsChanged(showDetails);
}

void ApplicationCore::setRouteKML(const QString& routeKML)
{
    if (m_routeKML == routeKML) {
        return;
    }

    m_routeKML = routeKML;
    emit routeKMLChanged(routeKML);
}

void ApplicationCore::saveMapPosition()
{
    QVariant pos = QVariant::fromValue(QPointF(m_currentMapPosition.latitude(), m_currentMapPosition.longitude()));
    m_settings->setValue("CurrentMapPosition", pos);
    m_settings->setValue("MapExtraScaling", m_extraScaling);
}

void ApplicationCore::doReloadUI()
{
    QQmlEngine* engine = m_view->engine();
    engine->clearComponentCache();
    m_view->setSource(mainQMLFile());
}

void ApplicationCore::handleLoadedHouseCoordinates(QNetworkReply* reply)
{
    if (reply == nullptr) {
        return;
    }

    if (reply->error() != QNetworkReply::NoError) {
        qDebug() << Q_FUNC_INFO << "network error";
        reply->deleteLater();
        return;
    }

    const qint64 available = reply->bytesAvailable();
    if (available <= 0) {
        qDebug() << Q_FUNC_INFO << "No data in network reply";
        reply->deleteLater();
        return;
    }

    const QByteArray buffer = QString::fromUtf8(reply->readAll()).toLatin1();
    reply->deleteLater();
    QJsonParseError parseError;
    QJsonDocument jsonDoc = QJsonDocument::fromJson(buffer, &parseError);
    if (QJsonParseError::NoError != parseError.error) {
        qDebug() << Q_FUNC_INFO << parseError.errorString();
        return;
    }
    if (!jsonDoc.isObject()) {
        qDebug() << Q_FUNC_INFO << "no object..." << jsonDoc.toVariant();
        return;
    }

    QJsonObject infoObject = jsonDoc.object();

    QJsonObject resultsObject = infoObject["query"].toObject()["results"].toObject();
    if (resultsObject.isEmpty()) {
        qDebug() << Q_FUNC_INFO << "Error parsing the JSON object";
        return;
    }
    QJsonObject mainObject = (*resultsObject.begin()).toObject();
    QJsonObject printoutsObject = mainObject["printouts"].toObject();
    QJsonArray coordsArray = printoutsObject["Koordinaten"].toArray();

    if (coordsArray.isEmpty()) {
        qDebug() << Q_FUNC_INFO << "Error parsing the JSON object coords";
        return;
    }

    QJsonObject coordObject = coordsArray.at(0).toObject();
    QGeoCoordinate coord(coordObject["lat"].toDouble(), coordObject["lon"].toDouble());

    setCurrentMapPosition(coord);
    emit requestFullZoomIn();
}

QString ApplicationCore::mainQMLFile() const
{
    QFileInfo mainFile(QStringLiteral("../../Baugeschichte/src/qml/main.qml"));
    if (mainFile.exists()) {
        qDebug() << "Load UI from" << mainFile.absoluteFilePath();
        return mainFile.absoluteFilePath();
    } else {
        qDebug() << "Load UI from embedded resource";
        return QStringLiteral("qrc:/qml/main.qml");
    }
}

void ApplicationCore::saveMarkers()
{
    if (m_houseMarkerModel->rowCount() == 0) {
        return;
    }

    QJsonArray markerArray;
    for (int i = 0; i < m_houseMarkerModel->rowCount(); ++i) {
        QJsonObject object;
        object["title"] = m_houseMarkerModel->get(i)->title();
        object["coord_lat"] = m_houseMarkerModel->get(i)->location().latitude();
        object["coord_lon"] = m_houseMarkerModel->get(i)->location().longitude();
        object["category"] = m_houseMarkerModel->get(i)->categories();
        markerArray.append(object);
    }

    QString markerFile = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    QDir dir;
    dir.mkpath(markerFile);
    markerFile += QStringLiteral("/markers.json");

    QJsonDocument doc(markerArray);
    QFile file(markerFile);
    file.open(QIODevice::WriteOnly);
    if (!file.isOpen()) {
        qWarning() << Q_FUNC_INFO << "unable to open file" << markerFile;
    }
    file.write(doc.toJson());
}

void ApplicationCore::loadMarkers()
{
    QString markerFile = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    markerFile += QStringLiteral("/markers.json");

    QFile file(markerFile);
    if (!file.exists()) {
        return;
    }

    // Some weired error with old markers leads to a crash when filtering them
    QFileInfo fi(file);
    QDateTime roughBuild(QDate(2016, 12, 9));
    if (fi.lastModified() > roughBuild) {
        return;
    }

    file.open(QIODevice::ReadOnly);
    if (!file.isOpen()) {
        qWarning() << Q_FUNC_INFO << "unable to open file" << markerFile;
        return;
    }

    QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    QJsonArray array = doc.array();

    QVector<HouseMarker> houses;
    houses.reserve(array.size());
    Q_FOREACH (const QJsonValue& value, array) {
        QJsonObject object = value.toObject();
        HouseMarker house;
        house.setTitle(object["title"].toString());
        QGeoCoordinate coord(object["coord_lat"].toDouble(), object["coord_lon"].toDouble());
        house.setLocation(coord);
        house.setCategories(object["category"].toString());
        houses.push_back(house);
    }

    m_houseMarkerModel->append(houses);
}
