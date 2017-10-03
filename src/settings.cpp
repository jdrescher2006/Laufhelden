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
    return m_settings->value("recordsettings/valueFields", "5,3,4,1,2,0,0,6|5,3,4,0,0,1,2,6|5,3,4,0,0,1,2,6|5,3,4,1,2,0,0,6|5,3,4,0,0,1,2,6").toString();
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
