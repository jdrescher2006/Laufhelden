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
    Q_PROPERTY(QString thresholds READ thresholds WRITE setThresholds)
    Q_PROPERTY(bool enableLogFile READ enableLogFile WRITE setEnableLogFile)
    Q_PROPERTY(int displayMode READ displayMode WRITE setDisplayMode)
    Q_PROPERTY(bool showBorderLines READ showBorderLines WRITE setShowBorderLines)
    Q_PROPERTY(QString valueFields READ valueFields WRITE setValueFields)
    Q_PROPERTY(bool enableAutosave READ enableAutosave WRITE setEnableAutosave)
    Q_PROPERTY(bool autoNightMode READ autoNightMode WRITE setAutoNightMode)
    Q_PROPERTY(int mapMode READ mapMode WRITE setMapMode)
    Q_PROPERTY(bool mapShowOnly4Fields READ mapShowOnly4Fields WRITE setmapShowOnly4Fields)
    Q_PROPERTY(QString mapStyle READ mapStyle WRITE setMapStyle)
    Q_PROPERTY(int mapCache READ mapCache WRITE setMapCache)
    Q_PROPERTY(int measureSystem READ measureSystem WRITE setMeasureSystem)
    Q_PROPERTY(QString valueCoverFields READ valueCoverFields WRITE setValueCoverFields)
    Q_PROPERTY(bool mapDisableRecordPage READ mapDisableRecordPage WRITE setMapDisableRecordPage)

    //Voice output
    Q_PROPERTY(int voiceLanguage READ voiceLanguage WRITE setVoiceLanguage)
    Q_PROPERTY(bool voiceStartEndWorkout READ voiceStartEndWorkout WRITE setVoiceStartEndWorkout)
    Q_PROPERTY(bool voicePauseContinueWorkout READ voicePauseContinueWorkout WRITE setVoicePauseContinueWorkout)
    Q_PROPERTY(bool voiceGPSConnectLost READ voiceGPSConnectLost WRITE setVoiceGPSConnectLost)

    //Cyclic voice output
    Q_PROPERTY(int voiceCycDistance READ voiceCycDistance WRITE setVoiceCycDistance)
    Q_PROPERTY(int voiceCycDuration READ voiceCycDuration WRITE setVoiceCycDuration)

    //Pebble specific setings
    Q_PROPERTY(bool enablePebble READ enablePebble WRITE setEnablePebble)
    Q_PROPERTY(QString valuePebbleFields READ valuePebbleFields WRITE setValuePebbleFields)

    //Sports-Tracker.com specific settings
    Q_PROPERTY(QString stUsername READ stUsername WRITE setStUsername)
    Q_PROPERTY(QString stPassword READ stPassword WRITE setStPassword)
    Q_PROPERTY(bool stAutoUpload READ stAutoUpload WRITE setStAutoUpload)
    Q_PROPERTY(int stSharing READ stSharing WRITE setStSharing)
    Q_PROPERTY(QString stSessionkey READ stSessionkey WRITE setStSessionkey)

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

    QString thresholds() const;
    void setThresholds(QString thresholds);

    bool enableLogFile() const;
    void setEnableLogFile(bool enableLogFile);

    int displayMode() const;
    void setDisplayMode(int displayMode);    

    bool showBorderLines() const;
    void setShowBorderLines(bool showBorderLines);

    QString valueFields() const;
    void setValueFields(QString valueFields);

    bool enableAutosave() const;
    void setEnableAutosave(bool enableAutosave);

    bool autoNightMode() const;
    void setAutoNightMode(bool autoNightMode);

    int mapMode() const;
    void setMapMode(int mapMode);

    bool mapShowOnly4Fields() const;
    void setmapShowOnly4Fields(bool mapShowOnly4Fields);

    QString valueCoverFields() const;
    void setValueCoverFields(QString valueCoverFields);

    bool enablePebble() const;
    void setEnablePebble(bool enablePebble);

    QString valuePebbleFields() const;
    void setValuePebbleFields(QString valuePebbleFields);

    QString mapStyle() const;
    void setMapStyle(QString mapStyle);

    int mapCache() const;
    void setMapCache(int mapCache);

    int measureSystem() const;
    void setMeasureSystem(int measureSystem);

    bool mapDisableRecordPage() const;
    void setMapDisableRecordPage(bool mapDisableRecordPage);

    //Voice output
    int voiceLanguage() const;
    void setVoiceLanguage(int voiceLanguage);

    bool voiceStartEndWorkout() const;
    void setVoiceStartEndWorkout(bool voiceStartEndWorkout);

    bool voicePauseContinueWorkout() const;
    void setVoicePauseContinueWorkout(bool voicePauseContinueWorkout);

    bool voiceGPSConnectLost() const;
    void setVoiceGPSConnectLost(bool voiceGPSConnectLost);

    //Cyclic voice output
    int voiceCycDistance() const;
    void setVoiceCycDistance(int voiceCycDistance);

    int voiceCycDuration() const;
    void setVoiceCycDuration(int voiceCycDuration);

    //Sporst-Tracker.com functions
    QString stUsername() const;
    void setStUsername(QString stUsername);

    QString stPassword() const;
    void setStPassword(QString stPassword);

    bool stAutoUpload() const;
    void setStAutoUpload(bool stAutoUpload);

    int stSharing() const;
    void setStSharing(int stSharing);

    QString stSessionkey() const;
    void setStSessionkey(QString stSessionkey);

signals:
    void updateIntervalChanged();

public slots:

private:
    QSettings *m_settings;
};

#endif // SETTINGS_H
