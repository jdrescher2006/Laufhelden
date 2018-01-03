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

            id_CMB_MeasureSystem.currentIndex = settings.measureSystem;

            id_TextSwitch_RecordPagePortrait.checked = settings.recordPagePortrait;
            id_TextSwitch_LogFile.checked = settings.enableLogFile;           

            id_TextSwitch_ShowLines.checked = settings.showBorderLines;

            id_TextSwitch_EnableAutosave.checked = settings.enableAutosave;

            id_TextSwitch_EnableAutoNightmode.checked = settings.autoNightMode;

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
            ComboBox
            {
                id: id_CMB_MeasureSystem
                label: qsTr("Unit of measurement")
                menu: ContextMenu
                {
                    MenuItem { text: qsTr("Metric") }
                    MenuItem { text: qsTr("Imperial") }
                }
                onCurrentIndexChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    settings.measureSystem = currentIndex;
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
                text: qsTr("Record page portrait mode")
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
                id: id_TextSwitch_ShowLines
                text: qsTr("Show grid lines")
                description: qsTr("Show grid lines on record page.")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.showBorderLines = checked;
                }
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            TextSwitch
            {
                id: id_TextSwitch_EnableAutoNightmode
                text: qsTr("Automatic night mode")
                description: qsTr("Switch display to night mode if ambiance light is low.")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.autoNightMode = checked;
                }
            }                        
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            TextSwitch
            {
                id: id_TextSwitch_EnableAutosave
                text: qsTr("Enable autosave")
                description: qsTr("No need to enter workout name on end of workout.")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.enableAutosave = checked;
                }
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
                visible: false
            }
            TextSwitch
            {
                id: id_TextSwitch_LogFile
                text: qsTr("Write log file")
                description: qsTr("File: $HOME/Laufhelden/log.txt")
                visible: false
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.enableLogFile = checked;
                }
            }
        }
    }
}
