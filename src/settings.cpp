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
QString Settings::pulseThreshold() const
{
        return m_settings->value("recordsettings/pulseThreshold", "default profile,false,false,110,160,3,3").toString();
}
void Settings::setPulseThreshold(QString pulseThreshold)
{
    m_settings->setValue("recordsettings/pulseThreshold", pulseThreshold);
}
QString Settings::paceThreshold() const
{
        return m_settings->value("recordsettings/paceThreshold", "default profile,false,false,4.5,6.3,3,3").toString();
}
void Settings::setPaceThreshold(QString paceThreshold)
{
    m_settings->setValue("recordsettings/paceThreshold", paceThreshold);
}
bool Settings::enableLogFile() const
{
    return m_settings->value("generalsettings/enableLogFile", false).toBool();
}
void Settings::setEnableLogFile(bool enableLogFile)
{
     m_settings->setValue("generalsettings/enableLogFile", enableLogFile);
}


