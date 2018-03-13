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
import "../tools/JSTools.js" as JSTools


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

        PullDownMenu
        {
            visible: (idComboBoxThresholdProfiles.currentIndex !== 0)
            id: menu
            MenuItem
            {
                text: qsTr("Add profile")
                onClicked:
                {
                    var dialog = pageStack.push(id_Dialog_RenameProfile)
                    dialog.sProfileName = ""
                    dialog.accepted.connect(function()
                    {
                        //Add the new profile to array and set it to active
                        var iNewIndex = Thresholds.fncAddProfile(dialog.sProfileName, "true");

                        //Save theshold array to settings
                        settings.thresholds = Thresholds.fncConvertArrayToSaveString();

                        //Set new profile name to combobox
                        idThressholdRepeater.model = undefined;
                        idThressholdRepeater.model = Thresholds.arrayThresholdProfiles;

                        //Select new profile
                        idComboBoxThresholdProfiles.currentIndex = iNewIndex;
                    })
                }
            }
            MenuItem
            {
                text: qsTr("Rename profile")
                onClicked:
                {
                    var dialog = pageStack.push(id_Dialog_RenameProfile)
                    dialog.sProfileName = idComboBoxThresholdProfiles.currentItem.text
                    dialog.accepted.connect(function()
                    {
                        //console.log("New name: " + dialog.sProfileName);

                        //Get selected profile object
                        var oActiveProfileObject = Thresholds.fncGetProfileObjectByIndex(idComboBoxThresholdProfiles.currentIndex);
                        //Set value to object
                        oActiveProfileObject.name = dialog.sProfileName;
                        //Save theshold array to settings
                        settings.thresholds = Thresholds.fncConvertArrayToSaveString();

                        idComboBoxThresholdProfiles.currentItem.text = dialog.sProfileName;
                    })
                }
            }
            MenuItem
            {
                text: qsTr("Remove profile")
                onClicked:
                {
                    Thresholds.fncRemoveProfile(idComboBoxThresholdProfiles.currentIndex);

                    //Save theshold array to settings
                    settings.thresholds = Thresholds.fncConvertArrayToSaveString();

                    //Set new profile name to combobox
                    idThressholdRepeater.model = undefined;
                    idThressholdRepeater.model = Thresholds.arrayThresholdProfiles;

                    //Select new profile
                    idComboBoxThresholdProfiles.currentIndex = 0;
                }
            }
        }

        Column
        {
            id: column
            width: page.width
            spacing: Theme.paddingLarge
            PageHeader
            {
                title: qsTr("Alarm thresholds")
            }
            ComboBox
            {
                id: idComboBoxThresholdProfiles
                width: parent.width
                label: qsTr("Select thresholds profile")
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
                visible: (idComboBoxThresholdProfiles.currentIndex !== 0)
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
                visible: (idComboBoxThresholdProfiles.currentIndex !== 0)
                onValueChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    //Get selected profile object
                    var oActiveProfileObject = Thresholds.fncGetProfileObjectByIndex(idComboBoxThresholdProfiles.currentIndex);
                    //Set value to object
                    oActiveProfileObject.iHRUpperThreshold = value.toFixed(0);
                    //Save theshold array to settings
                    settings.thresholds = Thresholds.fncConvertArrayToSaveString();
                }
            }
            TextSwitch
            {
                id: id_TextSwitch_BottomHRThreshold
                text: qsTr("Lower heart rate limit")
                description: qsTr("Alarm if limit is undershot.")
                visible: (idComboBoxThresholdProfiles.currentIndex !== 0)
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
                visible: (idComboBoxThresholdProfiles.currentIndex !== 0)
                onValueChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    //Get selected profile object
                    var oActiveProfileObject = Thresholds.fncGetProfileObjectByIndex(idComboBoxThresholdProfiles.currentIndex);
                    //Set value to object
                    oActiveProfileObject.iHRLowerThreshold = value.toFixed(0);
                    //Save theshold array to settings
                    settings.thresholds = Thresholds.fncConvertArrayToSaveString();
                }
            }
            Separator
            {
                color: Theme.highlightColor;
                anchors { left: parent.left; right: parent.right; }
                visible: (idComboBoxThresholdProfiles.currentIndex !== 0)
            }
            TextSwitch
            {
                id: id_TextSwitch_UpperPaceThreshold
                text: qsTr("Upper pace limit")
                description: qsTr("Alarm if limit is exceeded.")
                visible: (idComboBoxThresholdProfiles.currentIndex !== 0)
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
                valueText: (settings.measureSystem === 0) ? Math.floor(value) + ":" + JSTools.fncPadZeros(Math.ceil((value * 60.0) - (Math.floor(value) * 60.0)),2) + qsTr("min/km") : Math.floor(JSTools.fncConvertPacetoImperial(value)) + ":" + JSTools.fncPadZeros(Math.ceil((JSTools.fncConvertPacetoImperial(value) * 60.0) - (Math.floor(JSTools.fncConvertPacetoImperial(value)) * 60.0)),2) + qsTr("min/mi")
                label: qsTr("Upper pace limit")
                minimumValue: 0.1
                maximumValue: 10.0
                enabled: id_TextSwitch_UpperPaceThreshold.checked
                visible: (idComboBoxThresholdProfiles.currentIndex !== 0)
                onValueChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    //Get selected profile object
                    var oActiveProfileObject = Thresholds.fncGetProfileObjectByIndex(idComboBoxThresholdProfiles.currentIndex);
                    //Set value to object
                    oActiveProfileObject.fPaceUpperThreshold = value.toFixed(1);
                    //Save theshold array to settings
                    settings.thresholds = Thresholds.fncConvertArrayToSaveString();
                }
            }
            TextSwitch
            {
                id: id_TextSwitch_BottomPaceThreshold
                text: qsTr("Lower pace limit")
                description: qsTr("Alarm if limit is undershot.")
                visible: (idComboBoxThresholdProfiles.currentIndex !== 0)
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
                valueText: (settings.measureSystem === 0) ? Math.floor(value) + ":" + JSTools.fncPadZeros(Math.ceil((value * 60.0) - (Math.floor(value) * 60.0)),2) + qsTr("min/km") : Math.floor(JSTools.fncConvertPacetoImperial(value)) + ":" + JSTools.fncPadZeros(Math.ceil((JSTools.fncConvertPacetoImperial(value) * 60.0) - (Math.floor(JSTools.fncConvertPacetoImperial(value)) * 60.0)),2) + qsTr("min/mi")
                label: qsTr("Lower pace limit")
                minimumValue: 0.1
                maximumValue: 10.0
                enabled: id_TextSwitch_BottomPaceThreshold.checked
                visible: (idComboBoxThresholdProfiles.currentIndex !== 0)
                onValueChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    //Get selected profile object
                    var oActiveProfileObject = Thresholds.fncGetProfileObjectByIndex(idComboBoxThresholdProfiles.currentIndex);
                    //Set value to object
                    oActiveProfileObject.fPaceLowerThreshold = value.toFixed(1);
                    //Save theshold array to settings
                    settings.thresholds = Thresholds.fncConvertArrayToSaveString();
                }
            }
        }

        Component
        {
            id: id_Dialog_RenameProfile

            Dialog
            {
                property string sProfileName

                canAccept: id_TXF_ProfileName.text.length > 0 && id_TXF_ProfileName.text.indexOf(",") === -1 && id_TXF_ProfileName.text.indexOf("|") === -1
                acceptDestination: page
                acceptDestinationAction:
                {
                    sProfileName = id_TXF_ProfileName.text;
                    PageStackAction.Pop;
                }

                Flickable
                {
                    width: parent.width
                    height: parent.height
                    interactive: false

                    Column
                    {
                        width: parent.width

                        DialogHeader { title: qsTr("Edit profile name") }

                        Label
                        {
                            text: qsTr("Only text, no special characters!")
                        }

                        TextField
                        {
                            id: id_TXF_ProfileName
                            width: parent.width
                            label: qsTr("Threshold profile name")
                            placeholderText: qsTr("Threshold profile name")
                            text: sProfileName
                            inputMethodHints: Qt.ImhNoPredictiveText
                            focus: true
                            horizontalAlignment: TextInput.AlignRight
                        }
                    }
                }
            }
        }
    }
}
