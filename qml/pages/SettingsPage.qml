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

import QtQuick 2.0
import Sailfish.Silica 1.0


Page {
    id: page

    Component.onCompleted: {
        if(settings.updateInterval <= 1000) updateIntervalMenu.currentIndex = 0;
        else if(settings.updateInterval <= 2000) updateIntervalMenu.currentIndex = 1;
        else if(settings.updateInterval <= 5000) updateIntervalMenu.currentIndex = 2;
        else if(settings.updateInterval <= 10000) updateIntervalMenu.currentIndex = 3;
        else if(settings.updateInterval <= 15000) updateIntervalMenu.currentIndex = 4;
        else if(settings.updateInterval <= 30000) updateIntervalMenu.currentIndex = 5;
        else updateIntervalMenu.currentIndex = 6;
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: childrenRect.height
        Column {
            id: column
            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("Settings")
            }
            ComboBox {
                id: updateIntervalMenu
                label: "Track Point Interval"
                menu: ContextMenu {
                    MenuItem { text: qsTr("1 s (Default)"); onClicked: settings.updateInterval = 1000; }
                    MenuItem { text: qsTr("2 s"); onClicked: settings.updateInterval = 2000; }
                    MenuItem { text: qsTr("5 s"); onClicked: settings.updateInterval = 5000; }
                    MenuItem { text: qsTr("10 s"); onClicked: settings.updateInterval = 10000; }
                    MenuItem { text: qsTr("15 s"); onClicked: settings.updateInterval = 15000; }
                    MenuItem { text: qsTr("30 s"); onClicked: settings.updateInterval = 30000; }
                    MenuItem { text: qsTr("1 minute"); onClicked: settings.updateInterval = 60000; }
                }
            }
        }
    }
}
