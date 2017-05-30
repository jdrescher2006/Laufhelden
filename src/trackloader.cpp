/*
 * Copyright (C) 2017 Jens Drescher, Germany
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <QStandardPaths>
#include <QFile>
#include <QGeoCoordinate>
#include <QDebug>
#include <qmath.h>
#include "trackloader.h"

TrackLoader::TrackLoader(QObject *parent) :
    QObject(parent)
{
    m_loaded = false;
    m_error = false;
    m_name = "";
    m_speed = 0;
    m_maxSpeed = 0;
    m_pace = 0;
    m_duration = 0;
    m_distance = 0;
    m_heartRate = 0;
    m_heartRatePoints = 0;
    m_heartRateMin = 9999999;
    m_heartRateMax = 0;
}

void TrackLoader::load() {
    if(m_filename.isEmpty()) {
        // No filename set, nothing to do
        //qDebug()<<"No filename set";
        return;
    }
    QString dirName = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/Rena";
    QString fullFilename = dirName + "/" + m_filename;
    QFile file(fullFilename);

    if(!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug()<<"Error opening"<<fullFilename;
        m_error = true;
        return;
    }
    QXmlStreamReader xml(&file);
    if(!xml.readNextStartElement()) {
        qDebug()<<m_filename<<"is not xml file?";
        m_error = true;
        return;
    }
    if( !(xml.name() == "gpx" && xml.attributes().value("version") == "1.1") ) {
        qDebug()<<m_filename<<"is not gpx 1.1 file";
        m_error = true;
        return;
    }

    // Loading considered succeeded at this point
    m_loaded = true;
    emit loadedChanged();

    while(xml.readNextStartElement()) {
        if(xml.name() == "metadata") {
            while(xml.readNextStartElement()) {
                if(xml.name() == "name") {
                    m_name = xml.readElementText();
                    emit nameChanged();
                } else if(xml.name() == "desc") {
                    m_description = xml.readElementText();
                    emit descriptionChanged();
                } else {
                    xml.skipCurrentElement();
                }
            }
        } else if(xml.name() == "trk") {
            while(xml.readNextStartElement()) {
                if(xml.name() == "trkseg") {
                    while(xml.readNextStartElement()) {
                        if(xml.name() == "trkpt") {
                            TrackPoint point;

                            point.elevation = 0;
                            point.direction = 0;
                            point.groundSpeed = 0;
                            point.verticalSpeed = 0;
                            point.magneticVariation = 0;
                            point.horizontalAccuracy = 0;
                            point.verticalAccuracy = 0;
                            point.heartrate = 0;

                            point.latitude = xml.attributes().value("lat").toDouble();
                            point.longitude = xml.attributes().value("lon").toDouble();

                            while(xml.readNextStartElement()) {
                                if(xml.name() == "time") {
                                    point.time = QDateTime::fromString(xml.readElementText(),Qt::ISODate);
                                } else if(xml.name() == "ele") {
                                    point.elevation = xml.readElementText().toDouble();
                                } else if(xml.name() == "extensions") {
                                    while(xml.readNextStartElement())
                                    {                                        
                                        if(xml.name() == "dir")
                                        {
                                            point.direction = xml.readElementText().toDouble();
                                        }
                                        else if(xml.name() == "g_spd")
                                        {
                                            point.groundSpeed = xml.readElementText().toDouble();
                                        }
                                        else if(xml.name() == "v_spd")
                                        {
                                            point.verticalSpeed = xml.readElementText().toDouble();
                                        }
                                        else if(xml.name() == "m_var")
                                        {
                                            point.magneticVariation = xml.readElementText().toDouble();
                                        }
                                        else if(xml.name() == "h_acc")
                                        {
                                            point.horizontalAccuracy = xml.readElementText().toDouble();
                                        }
                                        else if(xml.name() == "v_acc")
                                        {
                                            point.verticalAccuracy = xml.readElementText().toDouble();
                                        }
                                        else if(xml.name() == "TrackPointExtension")
                                        {
                                            while(xml.readNextStartElement())
                                            {
                                                if(xml.name() == "hr")
                                                {
                                                    point.heartrate = xml.readElementText().toInt();
                                                }
                                                else
                                                    xml.skipCurrentElement();
                                            }
                                        }
                                        else
                                            xml.skipCurrentElement();
                                    }
                                }
                            }
                            m_points.append(point);
                        }
                    }
                }
            }
        } else {
            xml.skipCurrentElement();
        }
    }

    if(m_points.size() > 1)
    {
        QDateTime firstTime(m_points.at(0).time);
        QDateTime secondTime(m_points.at(m_points.size()-1).time);
        m_duration = firstTime.secsTo(secondTime);
        emit durationChanged();
        m_time = firstTime.toLocalTime();
        emit timeChanged();
        m_distance = 0;
        for(int i=1;i<m_points.size();i++)
        {
            QGeoCoordinate first(m_points.at(i-1).latitude,m_points.at(i-1).longitude);
            QGeoCoordinate second(m_points.at(i).latitude,m_points.at(i).longitude);
            m_distance += first.distanceTo(second);
            if(m_points.at(i).groundSpeed > m_maxSpeed) {
                m_maxSpeed = m_points.at(i).groundSpeed;
            }
            //If this point has a heart rate
            if (m_points.at(i).heartrate > 0)
            {
                m_heartRatePoints++;
                m_heartRate += m_points.at(i).heartrate;

                if (m_points.at(i).heartrate > m_heartRateMax)
                    m_heartRateMax = m_points.at(i).heartrate;
                if (m_points.at(i).heartrate < m_heartRateMin)
                    m_heartRateMin = m_points.at(i).heartrate;
            }
        }
        emit heartRateMinChanged();
        emit heartRateMaxChanged();
        emit distanceChanged();
        emit maxSpeedChanged();
        m_speed = m_distance / m_duration;
        emit speedChanged();
        m_pace = m_duration / m_distance * 1000 / 60;
        emit paceChanged();        
        m_heartRate = m_heartRate / m_heartRatePoints;
        emit heartRateChanged();
    } else {
        qDebug()<<"Not enough trackpoints to calculate duration, distance and speed";
        if(m_points.size() > 0) {
            QDateTime firstTime(m_points.at(0).time);
            m_time = firstTime.toLocalTime();
            emit timeChanged();
        }
    }

    emit trackChanged();
}

QString TrackLoader::filename() const {
    return m_filename;
}

void TrackLoader::setFilename(QString filename) {
    if((m_filename == filename)) {
        qDebug()<<"No change in filename";
        return;
    }
    qDebug()<<"Setting filename"<<filename;
    m_filename = filename;
    emit filenameChanged();
    // Trigger loading
    m_loaded = false;
    m_error = false;
    load();
}

QString TrackLoader::name() {
    if(!m_loaded && !m_error) {
        load();
    }
    if(!m_loaded || m_error) {
        // Nothing to load or error in loading
        return QString();
    }
    return m_name;
}

QString TrackLoader::description() {
    if(!m_loaded && !m_error) {
        load();
    }
    if(!m_loaded || m_error) {
        // Nothing to load or error in loading
        return QString();
    }
    return m_description;
}

QDateTime TrackLoader::time() {
    if(!m_loaded && !m_error) {
        load();
    }
    if(!m_loaded || m_error) {
        // Nothing to load or error in loading
        return QDateTime();
    }
    return m_time;
}

QString TrackLoader::timeStr() {
    if(!m_loaded && !m_error) {
        load();
    }
    if(!m_loaded || m_error) {
        // Nothing to load or error in loading
        return QString();
    }
    if(!m_time.isValid()) {
        return QString();
    }
    return m_time.toString(Qt::SystemLocaleShortDate);
}

uint TrackLoader::duration() {
    if(!m_loaded && !m_error) {
        load();
    }
    if(!m_loaded || m_error) {
        // Nothing to load or error in loading
        return 0;
    }
    return m_duration;
}

QString TrackLoader::durationStr() {
    if(!m_loaded && !m_error) {
        load();
    }
    if(!m_loaded || m_error) {
        // Nothing to load or error in loading
        return QString();
    }

    uint hours = m_duration / (60*60);
    uint minutes = (m_duration - hours*60*60) / 60;
    uint seconds = m_duration - hours*60*60 - minutes*60;
    if(hours == 0) {
        if(minutes == 0) {
            return QString("%3s").arg(seconds);
        }
        return QString("%2m %3s")
                .arg(minutes)
                .arg(seconds, 2, 10, QLatin1Char('0'));
    }
    return QString("%1h %2m %3s")
            .arg(hours)
            .arg(minutes, 2, 10, QLatin1Char('0'))
            .arg(seconds, 2, 10, QLatin1Char('0'));
}

qreal TrackLoader::distance() {
    if(!m_loaded && !m_error) {
        load();
    }
    if(!m_loaded || m_error) {
        // Nothing to load or error in loading
        return 0;
    }
    return m_distance;
}

qreal TrackLoader::speed() {
    if(!m_loaded && !m_error) {
        load();
    }
    if(!m_loaded || m_error) {
        // Nothing to load or error in loading
        return 0;
    }
    return m_speed;
}

qreal TrackLoader::maxSpeed() {
    if(!m_loaded && !m_error) {
        load();
    }
    if(!m_loaded || m_error) {
        // Nothing to load or error in loading
        return 0;
    }
    return m_maxSpeed;
}

qreal TrackLoader::pace() {
    if(!m_loaded && !m_error) {
        load();
    }
    if(!m_loaded || m_error) {
        // Nothing to load or error in loading
        return 0;
    }
    return m_pace;
}

qreal TrackLoader::heartRate() {
    if(!m_loaded && !m_error) {
        load();
    }
    if(!m_loaded || m_error) {
        // Nothing to load or error in loading
        return 0;
    }
    return m_heartRate;
}

uint TrackLoader::heartRateMin() {
    if(!m_loaded && !m_error) {
        load();
    }
    if(!m_loaded || m_error) {
        // Nothing to load or error in loading
        return 0;
    }
    return m_heartRateMin;
}

uint TrackLoader::heartRateMax() {
    if(!m_loaded && !m_error) {
        load();
    }
    if(!m_loaded || m_error) {
        // Nothing to load or error in loading
        return 0;
    }
    return m_heartRateMax;
}

bool TrackLoader::loaded() {
    return m_loaded;
}

int TrackLoader::trackPointCount() {
    if(!m_loaded && !m_error) {
        load();
    }
    if(!m_loaded || m_error) {
        // Nothing to load or error in loading
        return 0;
    }
    return m_points.size();
}

QGeoCoordinate TrackLoader::trackPointAt(int index) {
    return QGeoCoordinate(m_points.at(index).latitude,
                          m_points.at(index).longitude,
                          m_points.at(index).elevation);
}

int TrackLoader::fitZoomLevel(int width, int height) {
    if(m_points.size() < 2 || width < 1 || height < 1) {
        // One point track or zero size map
        return 20;
    }
    qreal minLat, maxLat, minLon, maxLon;
    minLat = maxLat = m_points.at(0).latitude;
    minLon = maxLon = m_points.at(0).longitude;
    for(int i=1;i<m_points.size();i++) {
        if(m_points.at(i).latitude < minLat) {
            minLat = m_points.at(i).latitude;
        } else if(m_points.at(i).latitude > maxLat) {
            maxLat = m_points.at(i).latitude;
        }
        if(m_points.at(i).longitude < minLon) {
            minLon = m_points.at(i).longitude;
        } else if(m_points.at(i).longitude > maxLon) {
            maxLon = m_points.at(i).longitude;
        }
    }

    m_center = QGeoCoordinate((minLat+maxLat)/2, (minLon+maxLon)/2);
    qreal coord, pixel;
    qreal trackMinX = (minLon + 180) / 360;
    qreal trackMaxX = (maxLon + 180) / 360;
    qreal trackMinY = sqrt(1-qLn(minLat*M_PI/180 + 1/qCos(minLat*M_PI/180))/M_PI);
    qreal trackMaxY = sqrt(1-qLn(maxLat*M_PI/180 + 1/qCos(maxLat*M_PI/180))/M_PI);

    qreal trackAR = qAbs((trackMaxX - trackMinX) / (trackMaxY - trackMinY));
    qreal windowAR = (qreal)width/(qreal)height;
    if(trackAR > windowAR ) {
        // Width limits
        coord = qAbs(trackMaxX - trackMinX);
        pixel = width;
    } else {
        // height limits
        coord = qAbs(trackMaxY - trackMinY);
        pixel = height;
    }

    // log2(x) = ln(x)/ln(2)
    int z = qFloor(qLn(pixel/256.0 * 1.0/coord * qCos(m_center.latitude()*M_PI/180))
                   / qLn(2)) + 1;
    return z;
}

QGeoCoordinate TrackLoader::center() {
    return m_center;
}
