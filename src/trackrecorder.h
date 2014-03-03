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

#ifndef TRACKRECORDER_H
#define TRACKRECORDER_H

#include <QObject>
#include <QGeoPositionInfoSource>

class TrackRecorder : public QObject
{
    Q_OBJECT
    Q_PROPERTY(qreal accuracy READ accuracy NOTIFY accuracyChanged)
    Q_PROPERTY(int points READ points NOTIFY pointsChanged)
    Q_PROPERTY(qreal distance READ distance NOTIFY distanceChanged)
    Q_PROPERTY(QString time READ time NOTIFY timeChanged)
    Q_PROPERTY(bool tracking READ isTracking WRITE setIsTracking NOTIFY isTrackingChanged)
    Q_PROPERTY(bool isEmpty READ isEmpty NOTIFY isEmptyChanged)
    Q_PROPERTY(bool applicationActive READ applicationActive WRITE setApplicationActive NOTIFY applicationActiveChanged)

public:
    explicit TrackRecorder(QObject *parent = 0);
    ~TrackRecorder();
    Q_INVOKABLE void exportGpx(QString name="", QString desc="");
    Q_INVOKABLE void clearTrack();

    qreal accuracy() const;
    int points() const;
    qreal distance() const;
    QString time() const;
    bool isTracking() const;
    void setIsTracking(bool tracking);
    bool isEmpty() const;
    bool applicationActive() const;
    void setApplicationActive(bool active);

signals:
    void accuracyChanged();
    void pointsChanged();
    void distanceChanged();
    void timeChanged();
    void isTrackingChanged();
    void isEmptyChanged();
    void applicationActiveChanged();

public slots:
    void positionUpdated(const QGeoPositionInfo &newPos);

private:
    QGeoPositionInfoSource *m_posSrc;
    qreal m_accuracy;
    QList<QGeoPositionInfo> m_points;
    qreal m_distance;
    bool m_tracking;
    bool m_isEmpty;
    bool m_applicationActive;
    };

#endif // TRACKRECORDER_H
