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

#ifndef HOUSEMARKERIMAGES_H
#define HOUSEMARKERIMAGES_H

#include "housemarker.h"

#include <QAbstractListModel>
#include <QHash>
#include <QList>
#include <QString>
#include <QVariant>
#include <QVector>

class QByteArray;
class QModelIndex;

class HouseMarkerModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum HousetrailRoles {
        HouseTitleRole = Qt::UserRole + 1,
        CoordinateRole,
        CategoryRole,
    };

    HouseMarkerModel(QObject* parent = 0);
    ~HouseMarkerModel();

    Q_SLOT void append(const QVector<HouseMarker>& aHouseTrail);
    Q_INVOKABLE void clear();

    int rowCount(const QModelIndex& parent = QModelIndex()) const;

    bool contains(const HouseMarker& marker) const;

    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const;

    const HouseMarker* get(int idx) const;
    HouseMarker* getHouseByTitle(const QString& title) const;

protected:
    QHash<int, QByteArray> roleNames() const;

private:
    /**
     * Removes the first (oldes) entries, so that only m_maxSize items are left in the container
     */
    void limitSize();

    QList<HouseMarker*> m_housetrails;
    QHash<QString, HouseMarker*> m_contained;
    int m_maxSize;
};

#endif // HOUSEMARKERIMAGES_H
