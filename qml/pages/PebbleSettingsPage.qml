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
import "../tools/RecordPageDisplay.js" as RecordPageDisplay

Page
{
    id: page

    property bool bLockOnCompleted : false
    property bool bLockFirstPageLoad: true
    property int iCheckPebbleStep: 0

    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockOnCompleted = true;

            bLockFirstPageLoad = false;
            console.log("First Active PebbleSettingsPage");

            id_TextSwitch_enablePebble.checked = settings.enablePebble;
            //id_CMB_MapCenterMode.currentIndex = settings.mapMode;


            //id_GI_PebbleConnected.color = pebbleComm.bIsPebbleConnected() ? "green" : "red"

            bLockOnCompleted = false;
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("Active PebbleSettingsPage");

        }
    }

    Timer
    {
        id: timCheckPebbleTimer
        interval: 1600
        running: (iCheckPebbleStep > 0)
        repeat: true
        onTriggered:
        {
            iCheckPebbleStep++;

            if (iCheckPebbleStep === 2)
            {
                progressBarCheckPebble.label = qsTr("set metric units");
                pebbleComm.fncSendDataToPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970", {'3': '1'});
                pebbleComm.fncSendDataToPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970", {'4': '1'});
            }
            if (iCheckPebbleStep === 3)
            {
                progressBarCheckPebble.label = qsTr("sending data 1");
                pebbleComm.fncSendDataToPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970", {'0': '02:30', '1': '10.12', '5': '0', '2': '2.4'});
            }
            if (iCheckPebbleStep === 4)
            {
                progressBarCheckPebble.label = qsTr("sending data 2");
                pebbleComm.fncSendDataToPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970", {'0': '02:33', '1': '10.22', '5': '0', '2': '3.3'});
            }
            if (iCheckPebbleStep === 5)
            {
                progressBarCheckPebble.label = qsTr("sending data 3");
                pebbleComm.fncSendDataToPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970", {'0': '02:45', '1': '11.34', '5': '0', '2': '14.4'});
            }
            if (iCheckPebbleStep === 6)
            {
                progressBarCheckPebble.label = qsTr("closing sport app");
                pebbleComm.fncClosePebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970");
            }
            if (iCheckPebbleStep === 7)
            {
                progressBarCheckPebble.label = "";
                iCheckPebbleStep = 0;
            }
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
                title: qsTr("Pebble settings")
            }                        
            TextSwitch
            {
                id: id_TextSwitch_enablePebble
                text: qsTr("Enable Pebble")
                description: qsTr("Send workout data to pebble. Make sure you have Rockpool (>= v1.4-4) installed!")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted && !bLockFirstPageLoad)
                        settings.enablePebble = checked;
                }                
            }                   
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            ComboBox
            {
                id: id_CMB_MapCenterMode
                label: qsTr("Value 1 field:")
                menu: ContextMenu { Repeater { model: RecordPageDisplay.arrayValueTypes; MenuItem { text: modelData.header } }}
                onCurrentItemChanged:
                {
                    if (!bLockOnCompleted && !bLockFirstPageLoad)
                    {
                        console.log("Combo changed: " + RecordPageDisplay.arrayValueTypes[currentIndex].header);
                    }
                }
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            Item
            {
                width: parent.width

                GlassItem
                {
                    id: id_GI_PebbleConnected
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: "red"
                    falloffRadius: 0.15
                    radius: 1.0
                    cache: false
                }
                Button
                {
                    text: qsTr("Test Pebble")
                    width: parent.width/2
                    onClicked:
                    {
                        iCheckPebbleStep = 1;
                        progressBarCheckPebble.label = qsTr("starting sport app");
                        pebbleComm.fncLaunchPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970");
                    }
                }
            }
            ProgressBar
            {
                id: progressBarCheckPebble
                width: parent.width
                maximumValue: 6
                valueText: value.toString() + "/" + maximumValue.toString()
                label: ""
                visible: (iCheckPebbleStep > 0)
                value: iCheckPebbleStep
            }
        }
    }
}
