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
    m_settings = new QSettings("jdrescher", "Laufhelden");
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
