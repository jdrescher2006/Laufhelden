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


import QtQuick 2.0
import Sailfish.Silica 1.0


Page {
    id: page

    property bool bLockOnCompleted : false;
    property bool bPushSettingsPage: true

    onStatusChanged:
    {
        if (status == PageStatus.Active && bPushSettingsPage)
        {
            bPushSettingsPage = false
            pageStack.pushAttached(Qt.resolvedUrl("BTConnectPage.qml"));
        }
    }

    Component.onCompleted:
    {
        bLockOnCompleted = true;

        if(settings.updateInterval <= 1000) updateIntervalMenu.currentIndex = 0;
        else if(settings.updateInterval <= 2000) updateIntervalMenu.currentIndex = 1;
        else if(settings.updateInterval <= 5000) updateIntervalMenu.currentIndex = 2;
        else if(settings.updateInterval <= 10000) updateIntervalMenu.currentIndex = 3;
        else if(settings.updateInterval <= 15000) updateIntervalMenu.currentIndex = 4;
        else if(settings.updateInterval <= 30000) updateIntervalMenu.currentIndex = 5;
        else updateIntervalMenu.currentIndex = 6;

        id_TextSwitch_RecordPagePortrait.checked = settings.recordPagePortrait;

        bLockOnCompleted = false;
    }

    SilicaFlickable
    {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge;
        VerticalScrollDecorator {}
        Column
        {
            id: column
            width: page.width
            spacing: Theme.paddingLarge
            PageHeader
            {
                title: qsTr("General settings")
            }
            ComboBox
            {
                id: updateIntervalMenu
                label: qsTr("Track point interval")
                menu: ContextMenu {
                    MenuItem { text: qsTr("1 s (default)"); onClicked: settings.updateInterval = 1000; }
                    MenuItem { text: qsTr("2 s"); onClicked: settings.updateInterval = 2000; }
                    MenuItem { text: qsTr("5 s"); onClicked: settings.updateInterval = 5000; }
                    MenuItem { text: qsTr("10 s"); onClicked: settings.updateInterval = 10000; }
                    MenuItem { text: qsTr("15 s"); onClicked: settings.updateInterval = 15000; }
                    MenuItem { text: qsTr("30 s"); onClicked: settings.updateInterval = 30000; }
                    MenuItem { text: qsTr("1 minute"); onClicked: settings.updateInterval = 60000; }
                }
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            TextSwitch
            {
                id: id_TextSwitch_RecordPagePortrait
                text: qsTr("Record page portrait")
                description: qsTr("Keep record page in portrait mode.")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.recordPagePortrait = checked;
                }                
            }            
        }
    }
}
