#include "applicationcore.h"
#include "houselocationfilter.h"
#include "housetrailimages.h"
#include "markerloader.h"

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickView>
#include <QScreen>
#include <QSortFilterProxyModel>
#include <QStandardPaths>
#include <QVector>
#include <QtQml>

#if defined(Q_OS_ANDROID)
#include <QAndroidJniObject>
#endif

#include <cmath>

ApplicationCore::ApplicationCore(QObject* parent)
    : QObject(parent)
    , m_view(new QQuickView())
    , m_houseTrailModel(new HousetrailModel(this))
    , m_markerLoader(new MarkerLoader(this))
    , m_detailsProxyModel(new QSortFilterProxyModel(this))
    , m_screenDpi(calculateScreenDpi())
    , m_mapProvider("osm")
    , m_selectedHouse("")
    , m_currentMapPosition(-1.0, -1.0)
    , m_showDetails(false)
    , m_housePositionLoader(new QNetworkAccessManager(this))
{
    qRegisterMetaType<HouseMarker>("HouseTrail");
    qRegisterMetaType<QVector<HouseMarker>>("QVector<HouseTrail>");
    qmlRegisterType<HouseLocationFilter>("Baugeschichte", 1, 0, "HouseLocationFilter");

    m_view->setWidth(1024);
    m_view->setHeight(800);
    m_view->setResizeMode(QQuickView::SizeRootObjectToView);

    m_detailsProxyModel->setFilterRole(HousetrailModel::HousetrailRoles::CategoryRole);
    m_detailsProxyModel->setSourceModel(m_houseTrailModel);

    QQmlEngine* engine = m_view->engine();
    QQmlContext* context = engine->rootContext();
    context->setContextProperty(QStringLiteral("appCore"), this);
    context->setContextProperty(QStringLiteral("markerLoader"), m_markerLoader);
    context->setContextProperty(QStringLiteral("houseTrailModel"), m_houseTrailModel);
    context->setContextProperty(QStringLiteral("filteredTrailModel"), m_detailsProxyModel);
    context->setContextProperty(QStringLiteral("screenDpi"), m_screenDpi);

    connect(m_markerLoader, SIGNAL(newHousetrail(QVector<HouseMarker>)), m_houseTrailModel,
        SLOT(append(QVector<HouseMarker>)));

    connect(
        m_housePositionLoader, &QNetworkAccessManager::finished, this, &ApplicationCore::handleLoadedHouseCoordinates);

    loadMarkers();
}

ApplicationCore::~ApplicationCore()
{
    saveMarkers();
    delete (m_view);
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
    return m_mapProvider;
}

void ApplicationCore::setMapProvider(QString mapProvider)
{
    if (mapProvider == m_mapProvider) {
        return;
    }

    m_mapProvider = mapProvider;
    emit mapProviderChanged(m_mapProvider);
}

QString ApplicationCore::selectedHouse() const
{
    return m_selectedHouse;
}

const QGeoCoordinate& ApplicationCore::currentMapPosition() const
{
    return m_currentMapPosition;
}

bool ApplicationCore::showDetails() const
{
    return m_showDetails;
}

void ApplicationCore::centerSelectedHouse()
{
    HouseMarker* house = m_houseTrailModel->getHouseByTitle(m_selectedHouse);
    if (house != nullptr) {
        setCurrentMapPosition(house->theLocation());
        emit requestFullZoomIn();
    } else {
        QString requestString
            = QString(
                  "http://baugeschichte.at/api.php?action=ask&query=[[%1]]|%3FKoordinaten|%3FPostleitzahl&format=json")
                  .arg(m_selectedHouse);
        QNetworkRequest request = QNetworkRequest(QUrl(requestString));
        m_housePositionLoader->get(request);
    }
}

QString ApplicationCore::routeKML() const
{
    return m_routeKML;
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
    QFileInfo mainFile(QStringLiteral("../../Baugeschichte/MapPrototype/src/main.qml"));
    if (mainFile.exists()) {
        qDebug() << "Load UI from" << mainFile.absoluteFilePath();
        return mainFile.absoluteFilePath();
    } else {
        qDebug() << "Load UI from embedded resource";
        return QStringLiteral("qrc:/main.qml");
    }
}

int ApplicationCore::calculateScreenDpi() const
{
#if defined(Q_OS_ANDROID)
    QAndroidJniObject qtActivity = QAndroidJniObject::callStaticObjectMethod(
        "org/qtproject/qt5/android/QtNative", "activity", "()Landroid/app/Activity;");
    QAndroidJniObject resources = qtActivity.callObjectMethod("getResources", "()Landroid/content/res/Resources;");
    QAndroidJniObject displayMetrics
        = resources.callObjectMethod("getDisplayMetrics", "()Landroid/util/DisplayMetrics;");
    int density = displayMetrics.getField<int>("densityDpi");
    return density;
#else
    QGuiApplication* uiApp = qobject_cast<QGuiApplication*>(qApp);
    qreal dpi = uiApp->primaryScreen()->physicalDotsPerInch() * uiApp->devicePixelRatio();
    if (uiApp) {
        return static_cast<int>(floor(dpi));
    } else {
        return 96;
    }
#endif
}

void ApplicationCore::saveMarkers()
{
    if (m_houseTrailModel->rowCount() == 0) {
        return;
    }

    QJsonArray markerArray;
    for (int i = 0; i < m_houseTrailModel->rowCount(); ++i) {
        QJsonObject object;
        object["dbId"] = m_houseTrailModel->get(i)->dbId();
        object["title"] = m_houseTrailModel->get(i)->houseTitle();
        object["coord_lat"] = m_houseTrailModel->get(i)->theLocation().latitude();
        object["coord_lon"] = m_houseTrailModel->get(i)->theLocation().longitude();
        object["category"] = m_houseTrailModel->get(i)->categories();
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
        qWarning() << Q_FUNC_INFO << "file does not exist" << markerFile;
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
        house.setDbId(object["dbId"].toInt());
        house.setHouseTitle(object["title"].toString());
        QGeoCoordinate coord(object["coord_lat"].toDouble(), object["coord_lon"].toDouble());
        house.setTheLocation(coord);
        house.setCategories(object["category"].toString());
        houses.push_back(house);
    }

    m_houseTrailModel->append(houses);
}
