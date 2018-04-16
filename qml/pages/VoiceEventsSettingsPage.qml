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
import "../tools/JSTools.js" as JSTools

Page
{
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
            console.log("First Active VoiceEventsSettingsPage");

            id_TextSwitch_StartEndWorkout.checked = settings.voiceStartEndWorkout;
            id_TextSwitch_PauseContinueWorkout.checked = settings.voicePauseContinueWorkout;
            id_TextSwitch_GPSConnectLost.checked = settings.voiceGPSConnectLost;

            bLockOnCompleted = false;
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("Active VoiceEventsSettingsPage");
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
                title: qsTr("Voice coach events settings")
            }            
            TextSwitch
            {
                id: id_TextSwitch_StartEndWorkout
                text: qsTr("Start/end workout")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.voiceStartEndWorkout = checked;
                }                
            }
            TextSwitch
            {
                id: id_TextSwitch_PauseContinueWorkout
                text: qsTr("Pause/continue workout")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.voicePauseContinueWorkout = checked;
                }
            }
            TextSwitch
            {
                id: id_TextSwitch_GPSConnectLost
                text: qsTr("Connect/disconnect GPS")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.voiceGPSConnectLost = checked;
                }
            }            
        }
    }
}
