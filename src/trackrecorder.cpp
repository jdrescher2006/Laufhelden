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

#include <QStandardPaths>
#include <QDir>
#include <QSaveFile>
#include <QXmlStreamWriter>
#include <QDebug>
#include "trackrecorder.h"

TrackRecorder::TrackRecorder(QObject *parent) :
    QObject(parent)
{
    qDebug()<<"TrackRecorder constructor";
    m_distance = 0.0;
    m_accuracy = -1;
    m_tracking = false;
    m_isEmpty = true;
    m_applicationActive = true;

    m_posSrc = QGeoPositionInfoSource::createDefaultSource(0);
        if (m_posSrc) {
            m_posSrc->setUpdateInterval(1000);
            connect(m_posSrc, SIGNAL(positionUpdated(QGeoPositionInfo)),
                    this, SLOT(positionUpdated(QGeoPositionInfo)));
            m_posSrc->startUpdates();
        } else {
            qDebug()<<"Failed initializing PositionInfoSource";
        }
}

TrackRecorder::~TrackRecorder() {
    qDebug()<<"TrackRecorder destructor";
    exportGpx();    // Panic autosave
}

void TrackRecorder::positionUpdated(const QGeoPositionInfo &newPos) {
    if(newPos.hasAttribute(QGeoPositionInfo::HorizontalAccuracy)) {
        m_accuracy = newPos.attribute(QGeoPositionInfo::HorizontalAccuracy);
    } else {
        m_accuracy = -1;
    }
    emit accuracyChanged();

    if(newPos.hasAttribute(QGeoPositionInfo::HorizontalAccuracy) &&
            (newPos.attribute(QGeoPositionInfo::HorizontalAccuracy) > 30.0)) {
        return;
}

    if(m_tracking) {
        m_points.append(newPos);
        emit pointsChanged();
        emit timeChanged();
        if(m_isEmpty) {
            m_isEmpty = false;
            emit isEmptyChanged();
        }

        if(m_points.size() > 1) {
            // Next line triggers following compiler warning?
            // \usr\include\qt5\QtCore\qlist.h:452: warning: assuming signed overflow does not occur when assuming that (X - c) > X is always false [-Wstrict-overflow]
            m_distance += m_points.at(m_points.size()-2).coordinate().distanceTo(m_points.at(m_points.size()-1).coordinate());
            emit distanceChanged();
            }
    }
}

void TrackRecorder::exportGpx(QString name, QString desc) {
    qDebug()<<"Exporting track to gpx";
    if(m_points.size() < 1) {
        qDebug()<<"Nothing to save";
        return; // Nothing to save
    }
    QString homeDir = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    QString subDir = "Rena";
    QString filename;
    if(!name.isEmpty()) {
        filename = m_points.at(0).timestamp().toUTC().toString(Qt::ISODate)
                + " - " + name + ".gpx";
    } else {
        filename = m_points.at(0).timestamp().toUTC().toString(Qt::ISODate)
                + ".gpx";
    }
    qDebug()<<"File:"<<homeDir<<"/"<<subDir<<"/"<<filename;

    QDir home = QDir(homeDir);
    if(!home.exists(subDir)) {
        qDebug()<<"Directory does not exist, creating";
        if(home.mkdir(subDir)) {
            qDebug()<<"Directory created";
        } else {
            qDebug()<<"Directory creation failed, aborting";
            return;
        }
    }

    QSaveFile file;
    file.setFileName(homeDir + "/" + subDir + "/" + filename);
    if(!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qDebug()<<"File opening failed, aborting";
        return;
    }

    QXmlStreamWriter xml;
    xml.setDevice(&file);
    xml.setAutoFormatting(true);    // Human readable output
    xml.writeStartDocument();
    xml.writeDefaultNamespace("http://www.topografix.com/GPX/1/1");
    xml.writeStartElement("gpx");
    xml.writeAttribute("version", "1.1");
    xml.writeAttribute("Creator", "Rena for Sailfish");

    if(!name.isEmpty() || !desc.isEmpty()) {
        xml.writeStartElement("metadata");
        if(!name.isEmpty()) {
            xml.writeTextElement("name", name);
        }
        if(!desc.isEmpty()) {
            xml.writeTextElement("desc", desc);
        }
        xml.writeEndElement(); // metadata
    }

    xml.writeStartElement("trk");
    xml.writeStartElement("trkseg");

    for(int i=0 ; i < m_points.size(); i++) {
        if(m_points.at(i).coordinate().type() == QGeoCoordinate::InvalidCoordinate) {
            break; // No position info, skip this point
        }
        xml.writeStartElement("trkpt");
        xml.writeAttribute("lat", QString::number(m_points.at(i).coordinate().latitude(), 'g', 15));
        xml.writeAttribute("lon", QString::number(m_points.at(i).coordinate().longitude(), 'g', 15));

        xml.writeTextElement("time", m_points.at(i).timestamp().toUTC().toString(Qt::ISODate));
        if(m_points.at(i).coordinate().type() == QGeoCoordinate::Coordinate3D) {
            xml.writeTextElement("ele", QString::number(m_points.at(i).coordinate().altitude(), 'g', 15));
        }

        xml.writeStartElement("extensions");
        if(m_points.at(i).hasAttribute(QGeoPositionInfo::Direction)) {
            xml.writeTextElement("dir", QString::number(m_points.at(i).attribute(QGeoPositionInfo::Direction), 'g', 15));
        }
        if(m_points.at(i).hasAttribute(QGeoPositionInfo::GroundSpeed)) {
            xml.writeTextElement("g_spd", QString::number(m_points.at(i).attribute(QGeoPositionInfo::GroundSpeed), 'g', 15));
        }
        if(m_points.at(i).hasAttribute(QGeoPositionInfo::VerticalSpeed)) {
            xml.writeTextElement("v_spd", QString::number(m_points.at(i).attribute(QGeoPositionInfo::VerticalSpeed), 'g', 15));
        }
        if(m_points.at(i).hasAttribute(QGeoPositionInfo::MagneticVariation)) {
            xml.writeTextElement("m_var", QString::number(m_points.at(i).attribute(QGeoPositionInfo::MagneticVariation), 'g', 15));
        }
        if(m_points.at(i).hasAttribute(QGeoPositionInfo::HorizontalAccuracy)) {
            xml.writeTextElement("h_acc", QString::number(m_points.at(i).attribute(QGeoPositionInfo::HorizontalAccuracy), 'g', 15));
        }
        if(m_points.at(i).hasAttribute(QGeoPositionInfo::VerticalAccuracy)) {
            xml.writeTextElement("v_acc", QString::number(m_points.at(i).attribute(QGeoPositionInfo::VerticalAccuracy), 'g', 15));
        }
        xml.writeEndElement(); // extensions

        xml.writeEndElement(); // trkpt
    }

    xml.writeEndElement(); // trkseg
    xml.writeEndElement(); // trk

    xml.writeEndElement(); // gpx
    xml.writeEndDocument();

    file.commit();
    if(file.error()) {
        qDebug()<<"Error in writing to a file";
        qDebug()<<file.errorString();
    }
}

void TrackRecorder::clearTrack() {
    m_points.clear();
    m_distance = 0;
    m_isEmpty = true;
    emit distanceChanged();
    emit timeChanged();
    emit isEmptyChanged();
    emit pointsChanged();
}

qreal TrackRecorder::accuracy() const {
    return m_accuracy;
}

int TrackRecorder::points() const {
    return m_points.size();
}

qreal TrackRecorder::distance() const {
    return m_distance;
}

QString TrackRecorder::time() const {
    uint hours, minutes, seconds;

    if(m_points.size() < 2) {
        hours = 0;
        minutes = 0;
        seconds = 0;
    } else {
        QDateTime first = m_points.at(0).timestamp();
        QDateTime last = m_points.at(m_points.size()-1).timestamp();
        qint64 difference = first.secsTo(last);
        hours = difference / (60*60);
        minutes = (difference - hours*60*60) / 60;
        seconds = difference - hours*60*60 - minutes*60;
    }

    QString timeStr = QString("%1h %2m %3s")
            .arg(hours, 2, 10, QLatin1Char('0'))
            .arg(minutes, 2, 10, QLatin1Char('0'))
            .arg(seconds, 2, 10, QLatin1Char('0'));

    return timeStr;
}

bool TrackRecorder::isTracking() const {
    return m_tracking;
}

void TrackRecorder::setIsTracking(bool tracking) {
    if(m_tracking == tracking) {
        return; // No change
    }
    m_tracking = tracking;

    if(m_posSrc) {  // If we have positioning
        if(m_tracking && !m_applicationActive) {
            // Start tracking when application at background -> positioning has to be enabled
            m_posSrc->startUpdates();
        }
        if(!m_tracking && !m_applicationActive) {
            // Stop tracking when application at background -> disable positioning
            m_posSrc->stopUpdates();
        }
    }

    emit isTrackingChanged();
}

bool TrackRecorder::isEmpty() const {
    return m_isEmpty;
}

bool TrackRecorder::applicationActive() const {
    return m_applicationActive;
}

void TrackRecorder::setApplicationActive(bool active) {
    if(m_applicationActive == active) {
        return; // No change
    }
    m_applicationActive = active;

    if(m_posSrc) {  // If we have positioning
        if(m_applicationActive && !m_tracking) {
            // Application became active without tracking
            m_posSrc->startUpdates();
        }
        if(!m_applicationActive && !m_tracking) {
            // Application went to background without tracking
            m_posSrc->stopUpdates();
        }
    }

    emit applicationActiveChanged();
}
