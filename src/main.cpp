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

#include "applicationcore.h"

#include <QDebug>
#include <QGuiApplication>
#include <QLocale>
#include <QSslSocket>
#include <QString>
#include <QTranslator>
#include <QtGlobal>

int main(int argc, char* argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling, true);

    // style for Controls2
    qputenv("QT_QUICK_CONTROLS_STYLE", "Material");

    QCoreApplication::setOrganizationName("GrazWiki");
    QCoreApplication::setOrganizationDomain("baugeschichte.at");
    QCoreApplication::setApplicationName("Baugeschichte");

    QGuiApplication app(argc, argv);
    app.setApplicationDisplayName(QStringLiteral("Baugeschichte.at"));

    QTranslator appTranslator;
    bool ok = appTranslator.load(
        QLocale(), QStringLiteral("Baugeschichte"), QStringLiteral("_"), QStringLiteral(":/"), QStringLiteral(".qm"));
    if (ok) {
        app.installTranslator(&appTranslator);
    } else {
        qDebug() << "cannot load app translator " << QLocale::system().name() << " check content of translations.qrc";
    }
    QTranslator qtTranslator;
    qtTranslator.load(
        QLocale(), QStringLiteral("qtbase"), QStringLiteral("_"), QStringLiteral(":/"), QStringLiteral(".qm"));
    if (ok) {
        app.installTranslator(&qtTranslator);
    } else {
        qDebug() << "cannot load qtbase translator " << QLocale::system().name()
                 << " check content of translations.qrc";
    }

    ApplicationCore appCore;
    QObject::connect(
        &app, &QGuiApplication::applicationStateChanged, &appCore, &ApplicationCore::handleApplicationStateChange);

    appCore.showView();

    qDebug() << Q_FUNC_INFO;
    qDebug() << "QSslSocket::sslLibraryBuildVersionNumber()" << QSslSocket::sslLibraryBuildVersionNumber();
    qDebug() << "QSslSocket::sslLibraryBuildVersionString()" << QSslSocket::sslLibraryBuildVersionString();
    qDebug() << "QSslSocket::sslLibraryVersionNumber()" << QSslSocket::sslLibraryVersionNumber();
    qDebug() << "QSslSocket::sslLibraryVersionString()" << QSslSocket::sslLibraryVersionString();
    qDebug() << "QSslSocket::supportsSsl()" << QSslSocket::supportsSsl();

    return app.exec();
}
