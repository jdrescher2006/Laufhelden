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
import "../tools/SharedResources.js" as SharedResources
import "../tools/Thresholds.js" as Thresholds

Page
{
    id: page

    allowedOrientations: settings.recordPagePortrait ? Orientation.Portrait : Orientation.All

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

            //This is a crazy thing, but at least it returns the index :-)
            console.log("Index of workout type: " + SharedResources.arrayWorkoutTypes.map(function(e) { return e.name; }).indexOf(settings.workoutType));

            cmbWorkout.currentIndex = SharedResources.arrayWorkoutTypes.map(function(e) { return e.name; }).indexOf(settings.workoutType);
            imgWorkoutImage.source = SharedResources.arrayWorkoutTypes[SharedResources.arrayWorkoutTypes.map(function(e) { return e.name; }).indexOf(settings.workoutType)].icon;

            if (sHRMAddress === "")
                txtswUseHRMdevice.checked = false;
            else
                txtswUseHRMdevice.checked = settings.useHRMdevice;

            txtswRecordPagePreventScreenBlank.checked = settings.disableScreenBlanking;


            //Load threshold settings and convert them to JS array
            Thresholds.fncConvertSaveStringToArray(settings.thresholds);

            //Set threshold profile names to combobox
            idThressholdRepeater.model = undefined;
            idThressholdRepeater.model = Thresholds.arrayThresholdProfiles;

            console.log("arrayThresholdProfiles.length: " + Thresholds.arrayThresholdProfiles.length.toString());
            console.log("selected profile index: " + Thresholds.fncGetCurrentProfileIndex().toString());


            //Set selected threshold profile to combobox
            idComboBoxThresholdProfiles.currentIndex = Thresholds.fncGetCurrentProfileIndex();

            pageStack.pushAttached(Qt.resolvedUrl("RecordPage.qml"));           

            bLockOnCompleted = false;
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("PreRecordPage active");

            //Switch off light sensor for this app
            id_Light.deactivate();

            if (bHRMConnected)
            {
                bRecordDialogRequestHRM = false;
                id_BluetoothData.disconnect();
            }

            //We might returned from record page and HR reconnect is still active. Switch it off.
            if (bRecordDialogRequestHRM)
                bRecordDialogRequestHRM = false;           

            //Check if pebble is connected
            if (sPebblePath !== "" && settings.enablePebble && !bPebbleConnected)
                bPebbleConnected = id_PebbleWatchComm.isConnected();

            //Launch pebble sport app
            if (sPebblePath !== "" && settings.enablePebble && bPebbleConnected)
                pebbleComm.fncLaunchPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970");

            bPebbleSportAppRequired = settings.enablePebble;
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
                title: qsTr("Let's go!")
            }           
            Row
            {
                spacing: Theme.paddingSmall
                width:parent.width;
                Image
                {
                    id: imgWorkoutImage
                    height: parent.width / 8
                    width: parent.width / 8
                    fillMode: Image.PreserveAspectFit
                }
                ComboBox
                {
                    id: cmbWorkout
                    width: (parent.width / 8) * 7
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

                    //Save selected profile thresholds array
                    Thresholds.fncSetCurrentProfileByIndex(currentIndex);
                    //Save theshold array to settings
                    settings.thresholds = Thresholds.fncConvertArrayToSaveString();
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
                description: qsTr("Disable screen blanking when recording.")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.disableScreenBlanking = checked;
                }
            }
        }


    }    
}
