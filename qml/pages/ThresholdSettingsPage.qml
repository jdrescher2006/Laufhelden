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
import "../tools/Thresholds.js" as Thresholds


Page {
    id: page

    property bool bLockOnCompleted : false;
    property bool bLockFirstPageLoad: true;      

    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockOnCompleted = true;

            bLockFirstPageLoad = false;
            // console.log("First Active ThresholdSettingsPage");

            //Load threshold settings and convert them to JS array
            Thresholds.fncConvertSaveStringToArray(settings.thresholds);

            //Set threshold profile names to combobox
            idThressholdRepeater.model = undefined;
            idThressholdRepeater.model = Thresholds.arrayThresholdProfiles;

            console.log("arrayThresholdProfiles.length: " + Thresholds.arrayThresholdProfiles.length.toString());
            console.log("selected profile index: " + Thresholds.fncGetCurrentProfileIndex().toString());


            //Set selected threshold profile to combobox
            idComboBoxThresholdProfiles.currentIndex = Thresholds.fncGetCurrentProfileIndex();



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
            ComboBox
            {
                id: idComboBoxThresholdProfiles
                width: parent.width
                label: "Select thresholds profile"
                menu: ContextMenu
                {
                    Repeater
                    {
                        id: idThressholdRepeater
                        model: Thresholds.arrayThresholdProfiles;
                        MenuItem { text: modelData.name }
                    }
                }

                onCurrentItemChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    console.log("Selected profile: " + Thresholds.arrayThresholdProfiles[currentIndex].name);

                    var oActiveProfileObject = Thresholds.fncGetProfileObjectByIndex(currentIndex);

                    id_TextSwitch_UpperHRThreshold.checked = oActiveProfileObject.bHRUpperThresholdEnable;
                    id_Slider_UpperHRThreshold.value = oActiveProfileObject.iHRUpperThreshold;

                    id_TextSwitch_BottomHRThreshold.checked = oActiveProfileObject.bHRLowerThresholdEnable;
                    id_Slider_BottomHRThreshold.value = oActiveProfileObject.iHRLowerThreshold;

                    id_TextSwitch_UpperPaceThreshold.checked = oActiveProfileObject.bPaceUpperThresholdEnable;
                    id_Slider_UpperPaceThreshold.value = oActiveProfileObject.fPaceUpperThreshold;

                    id_TextSwitch_BottomPaceThreshold.checked = oActiveProfileObject.bPaceLowerThresholdEnable;
                    id_Slider_BottomPaceThreshold.value = oActiveProfileObject.fPaceLowerThreshold;
                }
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }


            TextSwitch
            {
                id: id_TextSwitch_UpperHRThreshold
                text: qsTr("Upper heart rate limit")
                description: qsTr("Alarm if limit is exceeded.")
                onCheckedChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    //Get selected profile object
                    var oActiveProfileObject = Thresholds.fncGetProfileObjectByIndex(idComboBoxThresholdProfiles.currentIndex);
                    //Set value to object
                    oActiveProfileObject.bHRUpperThresholdEnable = checked;
                    //Save theshold array to settings
                    settings.thresholds = Thresholds.fncConvertArrayToSaveString();
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

                    //Get selected profile object
                    var oActiveProfileObject = Thresholds.fncGetProfileObjectByIndex(idComboBoxThresholdProfiles.currentIndex);
                    //Set value to object
                    oActiveProfileObject.iHRUpperThreshold = value;
                    //Save theshold array to settings
                    settings.thresholds = Thresholds.fncConvertArrayToSaveString();
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

                    //Get selected profile object
                    var oActiveProfileObject = Thresholds.fncGetProfileObjectByIndex(idComboBoxThresholdProfiles.currentIndex);
                    //Set value to object
                    oActiveProfileObject.bHRLowerThresholdEnable = checked;
                    //Save theshold array to settings
                    settings.thresholds = Thresholds.fncConvertArrayToSaveString();
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

                    //Get selected profile object
                    var oActiveProfileObject = Thresholds.fncGetProfileObjectByIndex(idComboBoxThresholdProfiles.currentIndex);
                    //Set value to object
                    oActiveProfileObject.iHRLowerThreshold = value;
                    //Save theshold array to settings
                    settings.thresholds = Thresholds.fncConvertArrayToSaveString();
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

                    //Get selected profile object
                    var oActiveProfileObject = Thresholds.fncGetProfileObjectByIndex(idComboBoxThresholdProfiles.currentIndex);
                    //Set value to object
                    oActiveProfileObject.bPaceUpperThresholdEnable = checked;
                    //Save theshold array to settings
                    settings.thresholds = Thresholds.fncConvertArrayToSaveString();
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

                    //Get selected profile object
                    var oActiveProfileObject = Thresholds.fncGetProfileObjectByIndex(idComboBoxThresholdProfiles.currentIndex);
                    //Set value to object
                    oActiveProfileObject.fPaceUpperThreshold = value;
                    //Save theshold array to settings
                    settings.thresholds = Thresholds.fncConvertArrayToSaveString();
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

                    //Get selected profile object
                    var oActiveProfileObject = Thresholds.fncGetProfileObjectByIndex(idComboBoxThresholdProfiles.currentIndex);
                    //Set value to object
                    oActiveProfileObject.bPaceLowerThresholdEnable = checked;
                    //Save theshold array to settings
                    settings.thresholds = Thresholds.fncConvertArrayToSaveString();
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

                    //Get selected profile object
                    var oActiveProfileObject = Thresholds.fncGetProfileObjectByIndex(idComboBoxThresholdProfiles.currentIndex);
                    //Set value to object
                    oActiveProfileObject.fPaceLowerThreshold = value;
                    //Save theshold array to settings
                    settings.thresholds = Thresholds.fncConvertArrayToSaveString();
                }
            }
        }
    }
}
