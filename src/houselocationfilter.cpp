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

#include "houselocationfilter.h"
#include "housemarkermodel.h"

#include <QList>
#include <QStringList>
#include <QTimer>
#include <QVariant>

#include <cmath>

class HouseLocationFilterPrivate
{
public:
    HouseLocationFilterPrivate()
        : m_location()
        , m_radius(200.0)
        , m_minDistance(100.0)
        , m_unfilteredHouseTitle("")
    {
        m_invalidateTimer.setInterval(10);
        m_invalidateTimer.setSingleShot(true);
    }

    QGeoCoordinate m_location;
    double m_radius;
    double m_minDistance;

    mutable QList<QGeoCoordinate> m_usedCoordinates;

    QString m_unfilteredHouseTitle;
    QStringList m_routeHouses;
    QTimer m_invalidateTimer;
};

HouseLocationFilter::HouseLocationFilter(QObject* parent)
    : QSortFilterProxyModel(parent)
    , d_ptr(new HouseLocationFilterPrivate())
{
    Q_D(HouseLocationFilter);
    setDynamicSortFilter(true);
    connect(&(d->m_invalidateTimer), &QTimer::timeout, this, &HouseLocationFilter::triggerRefiltering);
}

HouseLocationFilter::~HouseLocationFilter()
{
    delete d_ptr;
}

const QGeoCoordinate& HouseLocationFilter::location() const
{
    Q_D(const HouseLocationFilter);
    return d->m_location;
}

double HouseLocationFilter::radius() const
{
    Q_D(const HouseLocationFilter);
    return d->m_radius;
}

double HouseLocationFilter::minDistance() const
{
    Q_D(const HouseLocationFilter);
    return d->m_minDistance;
}

QString HouseLocationFilter::unfilteredHouseTitle() const
{
    Q_D(const HouseLocationFilter);
    return d->m_unfilteredHouseTitle;
}

void HouseLocationFilter::setRouteHouses(QVariant variant)
{
    Q_D(HouseLocationFilter);
    d->m_routeHouses.clear();

    QVariantList list = variant.value<QVariantList>();
    if (list.isEmpty()) {
        return;
    }
    for (const QVariant& houseVar : list) {
        d->m_routeHouses << houseVar.toString();
    }

    d->m_invalidateTimer.start();
}

void HouseLocationFilter::setUnfilteredHouseTitle(const QString& houseTitle)
{
    Q_D(HouseLocationFilter);
    if (houseTitle == d->m_unfilteredHouseTitle) {
        return;
    }

    d->m_unfilteredHouseTitle = houseTitle;
    Q_EMIT unfilteredHouseTitleChanged(d->m_unfilteredHouseTitle);
    d->m_invalidateTimer.start();
}

void HouseLocationFilter::setLocation(const QGeoCoordinate& location)
{
    Q_D(HouseLocationFilter);
    if (location == d->m_location) {
        return;
    }

    d->m_location = location;
    Q_EMIT locationChanged(d->m_location);
    d->m_invalidateTimer.start();
}

void HouseLocationFilter::setRadius(double radius)
{
    Q_D(HouseLocationFilter);
    if (std::abs(d->m_radius - radius) < 1e-9)
        return;

    d->m_radius = radius;
    Q_EMIT radiusChanged(radius);
    d->m_invalidateTimer.start();
}

void HouseLocationFilter::setMinDistance(double minDistance)
{
    Q_D(HouseLocationFilter);
    if (std::abs(minDistance - d->m_minDistance) < 1e-9) {
        return;
    }

    d->m_minDistance = minDistance;
    Q_EMIT minDistanceChanged(minDistance);
    d->m_invalidateTimer.start();
}

bool HouseLocationFilter::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    Q_D(const HouseLocationFilter);
    QVariant variant
        = sourceModel()->data(sourceModel()->index(source_row, 0, source_parent), HouseMarkerModel::CoordinateRole);
    if (!variant.canConvert<QGeoCoordinate>()) {
        return false;
    }

    QGeoCoordinate coord = variant.value<QGeoCoordinate>();
    if (coord.distanceTo(d->m_location) > d->m_radius) {
        return false;
    }

    QVariant titleVariant
        = sourceModel()->data(sourceModel()->index(source_row, 0, source_parent), HouseMarkerModel::HouseTitleRole);
    if (titleVariant.canConvert<QString>()) {
        QString title = titleVariant.value<QString>();
        if (title == d->m_unfilteredHouseTitle || d->m_routeHouses.contains(title)) {
            d->m_usedCoordinates.append(coord);
            return true;
        }
    }

    if (isCloseToOtherPosition(coord)) {
        return false;
    }

    d->m_usedCoordinates.append(coord);

    return true;
}

void HouseLocationFilter::triggerRefiltering()
{
    Q_D(HouseLocationFilter);
    d->m_usedCoordinates.clear();
    invalidateFilter();
}

bool HouseLocationFilter::isCloseToOtherPosition(const QGeoCoordinate& coord) const
{
    Q_D(const HouseLocationFilter);
    Q_FOREACH (const QGeoCoordinate& usedCoord, d->m_usedCoordinates) {
        if (coord.distanceTo(usedCoord) < d->m_minDistance) {
            return true;
        }
    }

    return false;
}
