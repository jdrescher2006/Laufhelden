/*
    Copyright 2014 Simo Mattila
    simo.h.mattila@gmail.com

    This file is part of Rena.

    Rena is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    any later version.

    Rena is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Rena.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QtQml>
#include <QGuiApplication>
#include <QQuickView>
#include <sailfishapp.h>
#include "trackrecorder.h"
#include "historymodel.h"
#include "trackloader.h"


int main(int argc, char *argv[]) {
    QGuiApplication *app = SailfishApp::application(argc, argv);

    app->setApplicationName("Rena");
    app->setApplicationVersion(QString(APP_VERSION)+QString(APP_VERSION_SUFFIX));
    QString userAgent(QString("Rena/")+
                      QString(APP_VERSION)+QString(APP_VERSION_SUFFIX)+
                      QString(" (Sailfish)"));

    qDebug()<<app->applicationName()<<" version "<<app->applicationVersion();
    qDebug()<<"User agent: "<<userAgent;

    qmlRegisterType<TrackRecorder>("TrackRecorder", 1, 0, "TrackRecorder");
    qmlRegisterType<HistoryModel>("HistoryModel", 1, 0, "HistoryModel");
    qmlRegisterType<TrackLoader>("TrackLoader", 1, 0, "TrackLoader");

    QQuickView *view = SailfishApp::createView();
    view->rootContext()->setContextProperty("appVersion", app->applicationVersion());
    view->rootContext()->setContextProperty("appUserAgent", userAgent);
    view->setSource(SailfishApp::pathTo("qml/harbour-rena.qml"));
    view->showFullScreen();

    return app->exec();
}

