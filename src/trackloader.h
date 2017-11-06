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

#ifndef TRACKLOADER_H
#define TRACKLOADER_H

#include <QObject>
#include <QDateTime>
#include <QGeoCoordinate>
#include <QXmlStreamReader>

class TrackLoader : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString filename READ filename WRITE setFilename NOTIFY filenameChanged)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(QString workout READ workout NOTIFY workoutChanged)
    Q_PROPERTY(QString description READ description NOTIFY descriptionChanged)
    Q_PROPERTY(QDateTime time READ time NOTIFY timeChanged)
    Q_PROPERTY(QString timeStr READ timeStr NOTIFY timeChanged)
    Q_PROPERTY(int duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(QString durationStr READ durationStr NOTIFY durationChanged)

    Q_PROPERTY(int pauseDuration READ pauseDuration NOTIFY durationChanged)
    Q_PROPERTY(QString pauseDurationStr READ pauseDurationStr NOTIFY durationChanged)

    Q_PROPERTY(qreal distance READ distance NOTIFY distanceChanged)
    Q_PROPERTY(qreal speed READ speed NOTIFY speedChanged)
    Q_PROPERTY(qreal maxSpeed READ maxSpeed NOTIFY maxSpeedChanged)
    Q_PROPERTY(qreal pace READ pace NOTIFY paceChanged)
    Q_PROPERTY(QString paceStr READ paceStr NOTIFY paceChanged)
    Q_PROPERTY(qreal heartRate READ heartRate NOTIFY heartRateChanged)
    Q_PROPERTY(uint heartRateMin READ heartRateMin NOTIFY heartRateMinChanged)
    Q_PROPERTY(uint heartRateMax READ heartRateMax NOTIFY heartRateMaxChanged)
    Q_PROPERTY(bool loaded READ loaded NOTIFY loadedChanged)

public:
    struct TrackPoint
    {
        qreal latitude;
        qreal longitude;
        QDateTime time;
        qreal elevation;
        qreal direction;
        qreal groundSpeed;
        qreal verticalSpeed;
        qreal magneticVariation;
        qreal horizontalAccuracy;
        qreal verticalAccuracy;
        uint heartrate;
    };  

    explicit TrackLoader(QObject *parent = 0);
    QString filename() const;
    void setFilename(QString filename);
    QString name();
    QString workout();
    QString description();
    QDateTime time();
    QString timeStr();
    uint duration();
    QString durationStr();

    uint pauseDuration();
    QString pauseDurationStr();

    qreal distance();
    qreal speed();
    qreal maxSpeed();
    qreal pace();
    QString paceStr();
    qreal heartRate();
    uint heartRateMin();
    uint heartRateMax();
    bool loaded();
    Q_INVOKABLE int trackPointCount();
    Q_INVOKABLE int pausePositionsCount();
    Q_INVOKABLE QGeoCoordinate trackPointAt(int index);
    Q_INVOKABLE int pausePositionAt(int index);
    Q_INVOKABLE uint heartRateAt(int index);
    Q_INVOKABLE qreal elevationAt(int index);

    // Temporary "hacks" to get around misbehaving Map.fitViewportToMapItems()
    Q_INVOKABLE int fitZoomLevel(int width, int height);
    Q_INVOKABLE QGeoCoordinate center();

signals:
    void filenameChanged();
    void nameChanged();
    void workoutChanged();
    void descriptionChanged();
    void timeChanged();
    void durationChanged();
    void distanceChanged();
    void speedChanged();
    void maxSpeedChanged();
    void paceChanged();
    void loadedChanged();
    void trackChanged();
    void heartRateChanged();
    void heartRateMinChanged();
    void heartRateMaxChanged();

public slots:

private:    
    void load();

    QList<TrackPoint> m_points;   
    QList<int> m_pause_positions;
    bool m_loaded;
    bool m_error;
    QString m_filename;
    QString m_name;
    QString m_workout;
    QString m_description;
    QDateTime m_time;
    uint m_duration;
    uint m_pause_duration;
    qreal m_distance;
    qreal m_speed;
    qreal m_maxSpeed;
    qreal m_pace;
    qreal m_heartRate;
    qreal m_heartRatePoints;
    uint m_heartRateMin;
    uint m_heartRateMax;
    QGeoCoordinate m_center;
};

#endif // TRACKLOADER_H
