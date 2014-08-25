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

#include "settings.h"

Settings::Settings(QObject *parent) :
    QObject(parent)
{
    m_settings = new QSettings("Simom", "Rena");
}

int Settings::updateInterval() const {
    return m_settings->value("positioning/updateInterval", 1000).toInt();
}

void Settings::setUpdateInterval(int updateInterval) {
    m_settings->setValue("positioning/updateInterval", updateInterval);
    emit updateIntervalChanged();
}
