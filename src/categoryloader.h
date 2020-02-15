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

#ifndef CATEGORYLOADER_H
#define CATEGORYLOADER_H

#include "housemarker.h"

#include <QObject>
#include <QString>
#include <QVector>

class QByteArray;
class QNetworkReply;

class CategoryLoaderPrivate;
/**
 * Class to load all houses of one category
 */
class CategoryLoader : public QObject
{
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_OBJECT
public:
    explicit CategoryLoader(QObject* parent = nullptr);
    ~CategoryLoader();

    Q_INVOKABLE void loadCategory(QString category);

    bool isLoading() const;

    void loadFromJsonText(const QByteArray& jsonText);

Q_SIGNALS:
    void isLoadingChanged(bool loading);
    void newHousetrail(QVector<HouseMarker> aNewHouseTrail);

private Q_SLOTS:
    void categoryLoaded(QNetworkReply* theReply);

private:
    void setLoading(bool loading);

    Q_DISABLE_COPY(CategoryLoader)
    Q_DECLARE_PRIVATE(CategoryLoader)
    CategoryLoaderPrivate* const d_ptr;
};

#endif // CATEGORYLOADER_H
