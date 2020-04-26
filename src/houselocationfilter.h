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

#ifndef HOUSELOCATIONFILTER_H
#define HOUSELOCATIONFILTER_H

#include <QGeoCoordinate>
#include <QSortFilterProxyModel>
#include <QString>

class QModelIndex;
class QVariant;

class HouseLocationFilterPrivate;
/**
 * @brief The HouseLocationFilter filters the HouseTrailModel by location and radius
 */
class HouseLocationFilter : public QSortFilterProxyModel
{
    Q_OBJECT

    Q_PROPERTY(QGeoCoordinate location READ location WRITE setLocation NOTIFY locationChanged)
    Q_PROPERTY(double radius READ radius WRITE setRadius NOTIFY radiusChanged)
    Q_PROPERTY(double minDistance READ minDistance WRITE setMinDistance NOTIFY minDistanceChanged)
    Q_PROPERTY(QString unfilteredHouseTitle READ unfilteredHouseTitle WRITE setUnfilteredHouseTitle NOTIFY
            unfilteredHouseTitleChanged)

public:
    HouseLocationFilter(QObject* parent = nullptr);
    ~HouseLocationFilter();

    const QGeoCoordinate& location() const;
    double radius() const;
    double minDistance() const;

    void setUnfilteredHouseTitle(const QString& houseTitle);
    QString unfilteredHouseTitle() const;

    Q_INVOKABLE void setRouteHouses(QVariant variant);

public Q_SLOTS:
    /**
     * @param radius in meters
     */
    void setLocation(const QGeoCoordinate& location);
    void setRadius(double radius);
    /**
     * Sets the minimal distance between markers in meters
     */
    void setMinDistance(double minDistance);

Q_SIGNALS:
    void radiusChanged(double radius);
    void locationChanged(const QGeoCoordinate& location);
    void minDistanceChanged(double minDistance);
    void unfilteredHouseTitleChanged(QString unfilteredHouseTitle);

protected:
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const;

private Q_SLOTS:
    void triggerRefiltering();

private:
    bool isCloseToOtherPosition(const QGeoCoordinate& coord) const;

    Q_DISABLE_COPY(HouseLocationFilter)
    Q_DECLARE_PRIVATE(HouseLocationFilter)
    HouseLocationFilterPrivate* const d_ptr;
};

#endif // HOUSELOCATIONFILTER_H
