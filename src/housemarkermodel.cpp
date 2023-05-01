/**
 ** This file is part of the Baugeschichte.at project.
 **
 ** The MIT License (MIT)
 **
 ** Copyright (c) 2015 primeMover2011
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

#include "housemarkermodel.h"

#include <QDebug>
#include <QGeoCoordinate>
#include <QString>

#include <set>

HouseMarkerModel::HouseMarkerModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_maxSize(10000)
{
}

HouseMarkerModel::~HouseMarkerModel()
{
    clear();
}

void HouseMarkerModel::append(const QVector<HouseMarker>& aHouseTrail)
{
    limitSize();

    std::set<HouseMarker> newHouses; // use a set to eliminate duplicates
    for (const HouseMarker& house : aHouseTrail) {
        if (!this->contains(house)) {
            newHouses.insert(house);
        }
    }

    int insertEnd = rowCount() + static_cast<int>(newHouses.size()) - 1;

    if (insertEnd < rowCount()) {
        return;
    }

    beginInsertRows(QModelIndex(), rowCount(), insertEnd);
    for (const HouseMarker& house : newHouses) {
        HouseMarker* newHouse = new HouseMarker(house);
        m_contained.insert(house.title(), newHouse);
        m_housetrails.append(newHouse);
    }
    endInsertRows();
}

void HouseMarkerModel::clear()
{
    beginResetModel();
    qDeleteAll(m_housetrails);
    m_housetrails.clear();
    m_contained.clear();
    endResetModel();
}

int HouseMarkerModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_housetrails.count();
}

bool HouseMarkerModel::contains(const HouseMarker& marker) const
{
    return m_contained.contains(marker.title());
}

QVariant HouseMarkerModel::data(const QModelIndex& index, int role) const
{
    if (index.row() < 0 || index.row() >= m_housetrails.count())
        return QVariant();

    HouseMarker* aHousetrail = m_housetrails[index.row()];
    if (role == HouseTitleRole)
        return aHousetrail->title();
    else if (role == CoordinateRole)
        return QVariant::fromValue(aHousetrail->location());
    else if (role == CategoryRole)
        return aHousetrail->categories();

    qWarning() << Q_FUNC_INFO << "Unkown role requested: " << role;
    return QVariant();
}

const HouseMarker* HouseMarkerModel::get(int idx) const
{
    return m_housetrails.at(idx);
}

HouseMarker* HouseMarkerModel::getHouseByTitle(const QString& title) const
{
    for (auto house : m_housetrails) {
        if (house->title() == title) {
            return house;
        }
    }
    return nullptr;
}

QHash<int, QByteArray> HouseMarkerModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[HouseTitleRole] = "title";
    roles[CoordinateRole] = "coord";
    roles[CategoryRole] = "category";
    return roles;
}

void HouseMarkerModel::limitSize()
{
    int size = m_housetrails.size();
    if (size > m_maxSize) {
        beginRemoveRows(QModelIndex(), 0, size - m_maxSize - 1);
        while (m_housetrails.size() > m_maxSize) {
            int i = m_contained.remove(m_housetrails[0]->title());
            if (i != 1) {
                qWarning() << "m_Contained.remove returned" << i << "but should be 1";
            }
            delete m_housetrails[0];
            m_housetrails.removeFirst();
        }
        endRemoveRows();
    }
}
