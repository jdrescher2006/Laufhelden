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
import "SharedResources.js" as SharedResources

Page
{
    id: page

    property bool bLockOnCompleted : true;
    property bool bLockFirstPageLoad: true

    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockOnCompleted = true;

            bLockFirstPageLoad = false;
            console.log("First Active PreRecordPage");


            //console.log("Eins: " + settings.workoutType);
            //console.log("Zwei: " + SharedResources.arrayWorkoutTypes.map(function(e) { return e.name; }).indexOf(settings.workoutType));
            //console.log("Drei: " + SharedResources.arrayWorkoutTypes.map(function(e) { return e.name; }));

            //This is a crazy thing, but at least it returns the index :-)
            cmbWorkout.currentIndex = SharedResources.arrayWorkoutTypes.map(function(e) { return e.name; }).indexOf(settings.workoutType);

            if (sHRMAddress === "")
                txtswUseHRMdevice.checked = false;
            else
                txtswUseHRMdevice.checked = settings.useHRMdevice;

            txtswRecordPagePreventScreenBlank.checked = settings.disableScreenBlanking;


            //Load threshold settings and convert them to JS array
            SharedResources.fncConvertSaveStringToArray(settings.thresholds);

            //Set threshold profile names to combobox
            idThressholdRepeater.model = undefined;
            idThressholdRepeater.model = SharedResources.arrayThresholdProfiles;

            console.log("arrayThresholdProfiles.length: " + SharedResources.arrayThresholdProfiles.length.toString());

            //Set selected profile to combobox
            var iProfileNameIndex = -1;
            //Search profile index
            for (var i = 0; i < SharedResources.arrayThresholdProfiles.length; i++)
            {
                if (SharedResources.arrayThresholdProfiles[i].name === settings.selectedThresholdProfile)
                    iProfileNameIndex = i;
            }
            //Check if profile name was found in array of profiles
            if (iProfileNameIndex !== -1)
                idComboBoxThresholdProfiles.currentIndex = iProfileNameIndex;
            else
                idComboBoxThresholdProfiles.currentIndex = 0;

            bLockOnCompleted = false;
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("PreRecordPage active");

            if (bHRMConnected)
            {
                bRecordDialogRequestHRM = false;
                id_BluetoothData.disconnect();
            }


        }

        if (status === PageStatus.Inactive)
        {
            console.log("PreRecordPage inactive");

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
                title: qsTr("Workout settings")
            }

            Button
            {
                text: qsTr("Let's go!")
                width: parent.width
                onClicked: pageStack.push(Qt.resolvedUrl("RecordPage.qml"))
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            Row
            {
                spacing: Theme.paddingSmall
                width:parent.width;
                Image
                {
                    id: imgWorkoutImage
                    height: cmbWorkout.height
                    fillMode: Image.PreserveAspectFit
                }
                ComboBox
                {
                    id: cmbWorkout
                    width: parent.width - imgWorkoutImage.width
                    label: qsTr("Workout:")
                    menu: ContextMenu
                    {
                        Repeater
                        {
                            model: SharedResources.arrayWorkoutTypes;
                            MenuItem { text: modelData.labeltext }
                        }
                    }
                    onCurrentItemChanged:
                    {
                        if (bLockOnCompleted)
                            return;

                        imgWorkoutImage.source = SharedResources.arrayWorkoutTypes[currentIndex].icon;
                        settings.workoutType = recorder.workoutType = SharedResources.arrayWorkoutTypes[currentIndex].name;
                    }
                }
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            TextSwitch
            {
                id: txtswUseHRMdevice
                text: qsTr("Use HRM device")
                description: qsTr("Use heart rate monitor in this workout.")
                enabled: (sHRMAddress !== "")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.useHRMdevice = checked;
                }                
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
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
                        model: SharedResources.arrayThresholdProfiles;
                        MenuItem { text: modelData.name }
                    }
                }
                onCurrentItemChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    console.log("Selected profile: " + SharedResources.arrayThresholdProfiles[currentIndex].name);

                    //Save selected profile to Settings
                    settings.selectedThresholdProfile = SharedResources.arrayThresholdProfiles[currentIndex].name;
                }
            }


            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            TextSwitch
            {
                id: txtswRecordPagePreventScreenBlank
                text: qsTr("Disable screen blanking")
                description: qsTr("Disbale screen blanking when recording.")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.disableScreenBlanking = checked;
                }
            }
        }
    }
}
