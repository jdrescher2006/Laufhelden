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
    property bool bLockFirstPageLoad: true;
    property int iHRUpperTreshold: 170;
    property int iHRLowerTreshold: 120;
    property int iHRUpperCounter: 3;
    property int iHRLowerCounter: 3;


    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockOnCompleted = true;

            bLockFirstPageLoad = false;
            console.log("First Active ThresholdSettingsPage");

            id_TextSwitch_UpperHRThreshold.checked = settings.pulseThresholdUpperEnable;
            id_TextSwitch_BottomHRThreshold.checked = settings.pulseThresholdBottomEnable;

            var iHeartrateThresholds = settings.pulseThreshold.toString().split(",");

            //parse thresholds to int
            iHRLowerTreshold = parseInt(iHeartrateThresholds[0]);
            iHRUpperTreshold = parseInt(iHeartrateThresholds[1]);
            iHRLowerCounter = parseInt(iHeartrateThresholds[2]);
            iHRUpperCounter = parseInt(iHeartrateThresholds[3]);

            id_Slider_UpperHRThreshold.value = iHRUpperTreshold;
            id_Slider_BottomHRThreshold.value = iHRLowerTreshold;

            pageStack.pushAttached(Qt.resolvedUrl("BTConnectPage.qml"));

            bLockOnCompleted = false;
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("Active ThresholdSettingsPage");

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
                title: qsTr("Threshold settings")
            }                        
            TextSwitch
            {
                id: id_TextSwitch_UpperHRThreshold
                text: qsTr("Upper heart rate limit")
                description: qsTr("Alarm if limit is exceeded.")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.pulseThresholdUpperEnable = checked;
                }                
            }
            Slider
            {
                id: id_Slider_UpperHRThreshold
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                valueText: value.toFixed(0) + qsTr("bpm")
                label: qsTr("Upper heart rate limit")
                minimumValue: 20
                maximumValue: 240
                onValueChanged:
                {
                    if (!bLockOnCompleted)
                    {
                        iHRUpperTreshold = value.toFixed(0);
                        var sSaveString = iHRLowerTreshold.toString() + "," + iHRUpperTreshold.toString() + "," + iHRLowerCounter.toString() + "," + iHRUpperCounter.toString();
                        settings.pulseThreshold = sSaveString;
                    }
                }
            }
            TextSwitch
            {
                id: id_TextSwitch_BottomHRThreshold
                text: qsTr("Lower heart rate limit")
                description: qsTr("Alarm if limit is exceeded.")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.pulseThresholdBottomEnable = checked;
                }
            }
            Slider
            {
                id: id_Slider_BottomHRThreshold
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                valueText: value.toFixed(0) + qsTr("bpm")
                label: qsTr("Lower heart rate limit")
                minimumValue: 20
                maximumValue: 240
                onValueChanged:
                {
                    if (!bLockOnCompleted)
                    {
                        iHRLowerTreshold = value.toFixed(0);
                        var sSaveString = iHRLowerTreshold.toString() + "," + iHRUpperTreshold.toString() + "," + iHRLowerCounter.toString() + "," + iHRUpperCounter.toString();
                        settings.pulseThreshold = sSaveString;
                    }
                }
            }
        }
    }
}
