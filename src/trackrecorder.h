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

#ifndef TRACKRECORDER_H
#define TRACKRECORDER_H

#include <QObject>
#include <QGeoPositionInfoSource>
#include <QTimer>

class TrackRecorder : public QObject
{
    Q_OBJECT
    Q_PROPERTY(qreal accuracy READ accuracy NOTIFY accuracyChanged)
    Q_PROPERTY(int points READ points NOTIFY pointsChanged)
    Q_PROPERTY(qreal distance READ distance NOTIFY distanceChanged)
    Q_PROPERTY(qreal speed READ speed NOTIFY speedChanged)
    Q_PROPERTY(qreal pace READ pace NOTIFY paceChanged)
    Q_PROPERTY(QString paceStr READ paceStr NOTIFY paceChanged)
    Q_PROPERTY(qreal speedaverage READ speedaverage NOTIFY speedaverageChanged)
    Q_PROPERTY(qreal paceaverage READ paceaverage NOTIFY paceaverageChanged)
    Q_PROPERTY(qreal heartrateaverage READ heartrateaverage NOTIFY heartrateaverageChanged)
    Q_PROPERTY(QString paceaverageStr READ paceaverageStr NOTIFY paceaverageChanged)
    Q_PROPERTY(QString time READ time NOTIFY timeChanged)    
    Q_PROPERTY(QString pebbleTime READ pebbleTime NOTIFY pebbleTimeChanged)
    Q_PROPERTY(bool isEmpty READ isEmpty NOTIFY isEmptyChanged)
    Q_PROPERTY(QGeoCoordinate currentPosition READ currentPosition NOTIFY currentPositionChanged)
    Q_PROPERTY(int updateInterval READ updateInterval WRITE setUpdateInterval NOTIFY updateIntervalChanged)
    Q_PROPERTY(QString workoutType READ workoutType WRITE setWorkoutType)
    Q_PROPERTY(QString startingDateTime READ startingDateTime)
    Q_PROPERTY(double altitude READ altitude NOTIFY valuesChanged)
    Q_PROPERTY(bool pause READ pause WRITE setPause NOTIFY pauseChanged)
    Q_PROPERTY(bool running READ running WRITE setRunning NOTIFY runningChanged)
    Q_PROPERTY(QString pauseTime READ pauseTime NOTIFY pauseTimeChanged)

public:
    explicit TrackRecorder(QObject *parent = 0);
    ~TrackRecorder();
    Q_INVOKABLE bool writeStGpxToFile(QString gpxcontent, QString filename, QString desc, QString sTkey, QString activity);
    Q_INVOKABLE void exportGpx(QString name="", QString desc="");
    Q_INVOKABLE void clearTrack();
    Q_INVOKABLE void vSetCurrentHeartRate(uint heartRate);
    Q_INVOKABLE void vStartGPS();
    Q_INVOKABLE void vEndGPS();

    qreal accuracy() const;
    int points() const;
    qreal distance() const;
    qreal speed() const;
    qreal pace() const;
    QString paceStr() const;
    qreal speedaverage() const;
    qreal paceaverage() const;
    qreal heartrateaverage() const;
    QString paceaverageStr() const;
    QString time() const;
    QString pebbleTime() const;
    QString pauseTime() const;
    bool isEmpty() const;
    QGeoCoordinate currentPosition() const;
    int updateInterval() const;
    void setUpdateInterval(int updateInterval);
    QString workoutType() const;
    void setWorkoutType(QString workoutType);
    QString startingDateTime() const;
    double altitude() const;
    bool pause() const;
    bool running() const;
    void setPause(bool pause);
    void setRunning(bool running);

    Q_INVOKABLE QGeoCoordinate trackPointAt(int index);
    Q_INVOKABLE bool pausePointAt(int index);

    // Temporary "hacks" to get around misbehaving Map.fitViewportToMapItems()
    Q_INVOKABLE int fitZoomLevel(int width, int height);
    Q_INVOKABLE QGeoCoordinate trackCenter();

signals:
    void accuracyChanged();
    void pointsChanged();
    void distanceChanged();
    void speedChanged();
    void paceChanged();
    void speedaverageChanged();
    void paceaverageChanged();
    void heartrateaverageChanged();
    void timeChanged();    
    void pebbleTimeChanged();
    void isEmptyChanged();
    void currentPositionChanged();
    void updateIntervalChanged();
    void valuesChanged();
    void newTrackPoint(QGeoCoordinate coordinate, int iPointIndex);
    void pauseChanged();
    void runningChanged();
    void pauseTimeChanged();

public slots:
    void positionUpdated(const QGeoPositionInfo &newPos);
    void positioningError(QGeoPositionInfoSource::Error error);
    void autoSave();

private:
    void loadAutoSave();
    QGeoPositionInfoSource *m_posSrc;
    qreal m_accuracy;
    QList<QGeoPositionInfo> m_points;
    QList<uint> m_heartrate;
    QList<qreal> m_distancearray;
    QList<bool> m_pausearray;
    QGeoCoordinate m_currentPosition;
    qreal m_distance;
    qreal m_speed;
    qreal m_pace;
    qreal m_speedaverage;
    qreal m_paceaverage;
    qreal m_heartrateaverage;
    uint m_heartrateadded;
    qreal m_minLat;
    qreal m_maxLat;
    qreal m_minLon;
    qreal m_maxLon;
    bool m_isEmpty;
    int m_autoSavePosition;
    QTimer m_autoSaveTimer;
    uint iCurrentHeartRate;
    QString sWorkoutType;
    double m_altitude;
    bool m_pause;
    bool m_running;
    quint32 m_PauseDuration;
    };

#endif // TRACKRECORDER_H
