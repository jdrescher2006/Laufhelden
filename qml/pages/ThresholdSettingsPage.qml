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

    function fncSaveHRValues()
    {
        var sSaveString = bHRUpperThresholdEnable.toString() + "," + bHRLowerThresholdEnable.toString() + "," + iHRLowerTreshold.toString() + "," + iHRUpperTreshold.toString() + "," + iHRLowerCounter.toString() + "," + iHRUpperCounter.toString();
        settings.pulseThreshold = sSaveString;
    }

    function fncSavePaceValues()
    {
        var sSaveString = bPaceUpperThresholdEnable.toString() + "," + bPaceLowerThresholdEnable.toString() + "," + iPaceLowerTreshold.toString() + "," + iPaceUpperTreshold.toString() + "," + iPaceLowerCounter.toString() + "," + iPaceUpperCounter.toString();
        settings.paceThreshold = sSaveString;
    }

    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockOnCompleted = true;

            bLockFirstPageLoad = false;
           // console.log("First Active ThresholdSettingsPage");

            var iHeartrateThresholds = settings.pulseThreshold.toString().split(",");
            var iPaceThresholds = settings.paceThreshold.toString().split(",");

            if (iHeartrateThresholds.length === 6)
            {
                //parse to bool
                bHRUpperThresholdEnable = (iHeartrateThresholds[0] === "true");
                bHRLowerThresholdEnable = (iHeartrateThresholds[1] === "true");

                //parse thresholds to int
                iHRLowerTreshold = parseInt(iHeartrateThresholds[2]);
                iHRUpperTreshold = parseInt(iHeartrateThresholds[3]);
                iHRLowerCounter = parseInt(iHeartrateThresholds[4]);
                iHRUpperCounter = parseInt(iHeartrateThresholds[5]);
            }

            if (iPaceThresholds.length === 6)
            {
                //parse to bool
                bPaceUpperThresholdEnable = (iPaceThresholds[0] === "true");
                bPaceLowerThresholdEnable = (iPaceThresholds[1] === "true");

                //parse thresholds to int
                iPaceLowerTreshold = parseFloat(iPaceThresholds[2]);
                iPaceUpperTreshold = parseFloat(iPaceThresholds[3]);
                iPaceLowerCounter = parseFloat(iPaceThresholds[4]);
                iPaceUpperCounter = parseFloat(iPaceThresholds[5]);
            }

            //Set values to dialog
            //id_TextSwitch_UpperHRThreshold.checked = bHRUpperThresholdEnable;
            id_TextSwitch_BottomHRThreshold.checked = bHRLowerThresholdEnable;

            id_Slider_UpperHRThreshold.value = iHRUpperTreshold;
            id_Slider_BottomHRThreshold.value = iHRLowerTreshold;

            id_TextSwitch_UpperPaceThreshold.checked = bPaceUpperThresholdEnable;
            id_TextSwitch_BottomPaceThreshold.checked = bPaceLowerThresholdEnable;

            id_Slider_UpperPaceThreshold.value = iPaceUpperTreshold;
            id_Slider_BottomPaceThreshold.value = iPaceLowerTreshold;


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
                checked: bHRUpperThresholdEnable
                onCheckedChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    bHRUpperThresholdEnable = checked;
                    fncSaveHRValues();
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
                enabled: id_TextSwitch_UpperHRThreshold.checked
                onValueChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    iHRUpperTreshold = value.toFixed(0);
                    fncSaveHRValues();
                }
            }
            TextSwitch
            {
                id: id_TextSwitch_BottomHRThreshold
                text: qsTr("Lower heart rate limit")
                description: qsTr("Alarm if limit is exceeded.")
                onCheckedChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    bHRLowerThresholdEnable = checked;
                    fncSaveHRValues();
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
                enabled: id_TextSwitch_BottomHRThreshold.checked
                onValueChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    iHRLowerTreshold = value.toFixed(0);
                    fncSaveHRValues();
                }
            }
            Separator
            {
                color: Theme.highlightColor;
                anchors { left: parent.left; right: parent.right; }
            }
            TextSwitch
            {
                id: id_TextSwitch_UpperPaceThreshold
                text: qsTr("Upper pace limit")
                description: qsTr("Alarm if limit is exceeded.")
                onCheckedChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    bPaceUpperThresholdEnable = checked;
                    fncSavePaceValues();
                }
            }
            Slider
            {
                id: id_Slider_UpperPaceThreshold
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                valueText: value.toFixed(1) + qsTr("min/km")
                label: qsTr("Upper pace limit")
                minimumValue: 0.1
                maximumValue: 50.0
                enabled: id_TextSwitch_UpperPaceThreshold.checked
                onValueChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    iPaceUpperTreshold = value.toFixed(1);
                    fncSavePaceValues();
                }
            }
            TextSwitch
            {
                id: id_TextSwitch_BottomPaceThreshold
                text: qsTr("Lower pace limit")
                description: qsTr("Alarm if limit is exceeded.")
                onCheckedChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    bPaceLowerThresholdEnable = checked;
                    fncSavePaceValues();
                }
            }
            Slider
            {
                id: id_Slider_BottomPaceThreshold
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                valueText: value.toFixed(1) + qsTr("min/km")
                label: qsTr("Lower pace limit")
                minimumValue: 0.1
                maximumValue: 50.0
                enabled: id_TextSwitch_BottomPaceThreshold.checked
                onValueChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    iPaceLowerTreshold = value.toFixed(1);
                    fncSavePaceValues();
                }
            }
        }
    }
}
