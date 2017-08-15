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

#ifndef SETTINGS_H
#define SETTINGS_H

#include <QObject>
#include <QSettings>

class Settings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int updateInterval READ updateInterval WRITE setUpdateInterval NOTIFY updateIntervalChanged)
    Q_PROPERTY(QString hrmdevice READ hrmdevice WRITE setHrmdevice)
    Q_PROPERTY(bool recordPagePortrait READ recordPagePortrait WRITE setRecordPagePortrait)
    Q_PROPERTY(QString workoutType READ workoutType WRITE setWorkoutType)
    Q_PROPERTY(bool useHRMdevice READ useHRMdevice WRITE setUseHRMdevice)
    Q_PROPERTY(bool disableScreenBlanking READ disableScreenBlanking WRITE setDisableScreenBlanking)
    Q_PROPERTY(bool showMapRecordPage READ showMapRecordPage WRITE setShowMapRecordPage)
    Q_PROPERTY(QString pulseThreshold READ pulseThreshold WRITE setPulseThreshold)
    Q_PROPERTY(bool pulseThresholdUpperEnable READ pulseThresholdUpperEnable WRITE setPulseThresholdUpperEnable)
    Q_PROPERTY(bool pulseThresholdBottomEnable READ pulseThresholdBottomEnable WRITE setPulseThresholdBottomEnable)
    Q_PROPERTY(bool enableLogFile READ enableLogFile WRITE setEnableLogFile)

public:
    explicit Settings(QObject *parent = 0);
    int updateInterval() const;
    void setUpdateInterval(int updateInterval);

    QString hrmdevice() const;
    void setHrmdevice(QString hrmdevice);

    bool recordPagePortrait() const;
    void setRecordPagePortrait(bool recordPagePortrait);

    QString workoutType() const;
    void setWorkoutType(QString workoutType);

    bool useHRMdevice() const;
    void setUseHRMdevice(bool useHRMdevice);

    bool disableScreenBlanking() const;
    void setDisableScreenBlanking(bool disableScreenBlanking);

    bool showMapRecordPage() const;
    void setShowMapRecordPage(bool showMapRecordPage);

    bool pulseThresholdUpperEnable() const;
    void setPulseThresholdUpperEnable(bool pulseThresholdUpperEnable);

    bool pulseThresholdBottomEnable() const;
    void setPulseThresholdBottomEnable(bool pulseThresholdBottomEnable);

    QString pulseThreshold() const;
    void setPulseThreshold(QString pulseThreshold);

    bool enableLogFile() const;
    void setEnableLogFile(bool enableLogFile);

signals:
    void updateIntervalChanged();

public slots:

private:
    QSettings *m_settings;
};

#endif // SETTINGS_H
