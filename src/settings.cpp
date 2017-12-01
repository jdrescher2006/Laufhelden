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

#include "settings.h"

Settings::Settings(QObject *parent) :
    QObject(parent)
{
    m_settings = new QSettings("harbour-laufhelden", "harbour-laufhelden");
}

int Settings::updateInterval() const
{
    return m_settings->value("positioning/updateInterval", 1000).toInt();
}
void Settings::setUpdateInterval(int updateInterval)
{
    m_settings->setValue("positioning/updateInterval", updateInterval);
    emit updateIntervalChanged();
}

QString Settings::hrmdevice() const
{
        return m_settings->value("hrm/hrmdevice", ",").toString();
}
void Settings::setHrmdevice(QString hrmdevice)
{
    m_settings->setValue("hrm/hrmdevice", hrmdevice);
}

bool Settings::recordPagePortrait() const
{
    return m_settings->value("generalsettings/recordpageportrait", true).toBool();
}
void Settings::setRecordPagePortrait(bool recordPagePortrait)
{
    m_settings->setValue("generalsettings/recordpageportrait", recordPagePortrait);
}

QString Settings::workoutType() const
{
    return m_settings->value("recordsettings/workoutType", "running").toString();
}
void Settings::setWorkoutType(QString workoutType)
{
    m_settings->setValue("recordsettings/workoutType", workoutType);
}

bool Settings::useHRMdevice() const
{
    return m_settings->value("recordsettings/useHRMdevice", false).toBool();
}
void Settings::setUseHRMdevice(bool useHRMdevice)
{
     m_settings->setValue("recordsettings/useHRMdevice", useHRMdevice);
}

bool Settings::disableScreenBlanking() const
{
    return m_settings->value("recordsettings/disableScreenBlanking", false).toBool();
}
void Settings::setDisableScreenBlanking(bool disableScreenBlanking)
{
     m_settings->setValue("recordsettings/disableScreenBlanking", disableScreenBlanking);
}
bool Settings::showMapRecordPage() const
{
    return m_settings->value("recordsettings/showMapRecordPage", true).toBool();
}
void Settings::setShowMapRecordPage(bool showMapRecordPage)
{
     m_settings->setValue("recordsettings/showMapRecordPage", showMapRecordPage);
}
QString Settings::thresholds() const
{
    return m_settings->value("recordsettings/thresholds", "Thresholds off,true,false,0,false,0,false,0,false,0|Wettkampf 10km,false,true,183,false,133,true,5.0,true,4.5|Training GA 1,false,true,141,true,130,false,6.2,false,3.2").toString();
}
void Settings::setThresholds(QString thresholds)
{
    m_settings->setValue("recordsettings/thresholds", thresholds);
}
bool Settings::enableLogFile() const
{
    return m_settings->value("generalsettings/enableLogFile", false).toBool();
}
void Settings::setEnableLogFile(bool enableLogFile)
{
     m_settings->setValue("generalsettings/enableLogFile", enableLogFile);
}
int Settings::displayMode() const
{
    return m_settings->value("recordsettings/displayMode", 3).toInt();
}
void Settings::setDisplayMode(int displayMode)
{
    m_settings->setValue("recordsettings/displayMode", displayMode);
}
int Settings::voiceLanguage() const
{
    return m_settings->value("generalsettings/voiceLanguage", 0).toInt();
}
void Settings::setVoiceLanguage(int voiceLanguage)
{
    m_settings->setValue("generalsettings/voiceLanguage", voiceLanguage);
}
bool Settings::showBorderLines() const
{
    return m_settings->value("generalsettings/showBorderLines", true).toBool();
}
void Settings::setShowBorderLines(bool showBorderLines)
{
     m_settings->setValue("generalsettings/showBorderLines", showBorderLines);
}
QString Settings::valueFields() const
{
    return m_settings->value("recordsettings/valueFields", "3,4,1,2,7,8|5,6,1,2,7,8|5,6,1,2,7,8|3,4,1,2,7,8|5,6,1,2,7,8").toString();
}
void Settings::setValueFields(QString valueFields)
{
    m_settings->setValue("recordsettings/valueFields", valueFields);
}
bool Settings::enableAutosave() const
{
    return m_settings->value("generalsettings/enableAutosave", false).toBool();
}
void Settings::setEnableAutosave(bool enableAutosave)
{
     m_settings->setValue("generalsettings/enableAutosave", enableAutosave);
}
bool Settings::autoNightMode() const
{
    return m_settings->value("generalsettings/autoNightMode", true).toBool();
}
void Settings::setAutoNightMode(bool autoNightMode)
{
     m_settings->setValue("generalsettings/autoNightMode", autoNightMode);
}
int Settings::mapMode() const
{
    return m_settings->value("mapsettings/mapMode", 0).toInt();
}
void Settings::setMapMode(int mapMode)
{
    m_settings->setValue("mapsettings/mapMode", mapMode);
}

bool Settings::mapShowOnly4Fields() const
{
    return m_settings->value("mapsettings/mapShowOnly4Fields", true).toBool();
}
void Settings::setmapShowOnly4Fields(bool mapShowOnly4Fields)
{
     m_settings->setValue("mapsettings/mapShowOnly4Fields", mapShowOnly4Fields);
}
bool Settings::enablePebble() const
{
    return m_settings->value("pebblesettings/enablePebble", false).toBool();
}
void Settings::setEnablePebble(bool enablePebble)
{
     m_settings->setValue("pebblesettings/enablePebble", enablePebble);
}
QString Settings::valuePebbleFields() const
{
    return m_settings->value("pebblesettings/valuePebbleFields", "10,8,3").toString();
}
void Settings::setValuePebbleFields(QString valuePebbleFields)
{
    m_settings->setValue("pebblesettings/valuePebbleFields", valuePebbleFields);
}

//Sports-Tracker.com Sharing functions
void Settings::setStUsername(QString username)
{
    return m_settings->setValue("sportstracker/username", username);
}
QString Settings::stUsername() const
{
    return m_settings->value("sportstracker/username").toString();
}

void Settings::setStPassword(QString password)
{
    return m_settings->setValue("sportstracker/password", password);
}
QString Settings::stPassword() const
{
    return m_settings->value("sportstracker/password").toString();
}

void Settings::setStAutoUpload(bool stAutoUpload)
{
     m_settings->setValue("sportstracker/autoupload", stAutoUpload);
}

bool Settings::stAutoUpload() const
{
    return m_settings->value("sportstracker/autoupload", true).toBool();
}

void Settings::setStSharing(int stSharing)
{
     m_settings->setValue("sportstracker/sharing", stSharing);
}

int Settings::stSharing() const
{
    return m_settings->value("sportstracker/sharing", 0).toInt(); //Defaults Private option = 0
}

void Settings::setStSessionkey(QString key)
{
    return m_settings->setValue("sportstracker/sessionkey", key);
}

QString Settings::stSessionkey() const
{
    return m_settings->value("sportstracker/sessionkey").toString();
}
