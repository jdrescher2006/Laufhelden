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
        return m_settings->value("recordsettings/pulseThreshold", "110,160,3,3").toString();
}
void Settings::setPulseThreshold(QString pulseThreshold)
{
    m_settings->setValue("recordsettings/pulseThreshold", pulseThreshold);
}
bool Settings::pulseThresholdUpperEnable() const
{
    return m_settings->value("recordsettings/pulseThresholdUpperEnable", false).toBool();
}
void Settings::setPulseThresholdUpperEnable(bool pulseThresholdUpperEnable)
{
     m_settings->setValue("recordsettings/pulseThresholdUpperEnable", pulseThresholdUpperEnable);
}
bool Settings::pulseThresholdBottomEnable() const
{
    return m_settings->value("recordsettings/pulseThresholdBottomEnable", false).toBool();
}
void Settings::setPulseThresholdBottomEnable(bool pulseThresholdBottomEnable)
{
     m_settings->setValue("recordsettings/pulseThresholdBottomEnable", pulseThresholdBottomEnable);
}
QString Settings::paceThreshold() const
{
        return m_settings->value("recordsettings/paceThreshold", "4.5,6.3,3,3").toString();
}
void Settings::setPaceThreshold(QString paceThreshold)
{
    m_settings->setValue("recordsettings/paceThreshold", paceThreshold);
}
bool Settings::paceThresholdUpperEnable() const
{
    return m_settings->value("recordsettings/paceThresholdUpperEnable", false).toBool();
}
void Settings::setPaceThresholdUpperEnable(bool paceThresholdUpperEnable)
{
     m_settings->setValue("recordsettings/paceThresholdUpperEnable", paceThresholdUpperEnable);
}
bool Settings::paceThresholdBottomEnable() const
{
    return m_settings->value("recordsettings/paceThresholdBottomEnable", false).toBool();
}
void Settings::setPaceThresholdBottomEnable(bool paceThresholdBottomEnable)
{
     m_settings->setValue("recordsettings/paceThresholdBottomEnable", paceThresholdBottomEnable);
}
bool Settings::enableLogFile() const
{
    return m_settings->value("generalsettings/enableLogFile", false).toBool();
}
void Settings::setEnableLogFile(bool enableLogFile)
{
     m_settings->setValue("generalsettings/enableLogFile", enableLogFile);
}


