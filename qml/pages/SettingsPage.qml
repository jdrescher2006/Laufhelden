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
    property bool bLockFirstPageLoad: true

    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockOnCompleted = true;

            bLockFirstPageLoad = false;
            console.log("First Active SettingsPage");

            id_TextSwitch_RecordPagePortrait.checked = settings.recordPagePortrait;
            id_TextSwitch_LogFile.checked = settings.enableLogFile;

            pageStack.pushAttached(Qt.resolvedUrl("BTConnectPage.qml"));

            bLockOnCompleted = false;
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("Active SettingsPage");

        }
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
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            TextSwitch
            {
                id: id_TextSwitch_LogFile
                text: qsTr("Write log file")
                description: qsTr("File: $HOME/Laufhelden/log.txt")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.enableLogFile = checked;
                }
            }
        }
    }
}
