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

Page {
    id: page

    property bool bPushPreRecordPage: true
    property variant arComboboxStringArray : []
    property bool bLockOnCompleted : true;

    onStatusChanged:
    {
        if (status == PageStatus.Active && bPushPreRecordPage)
        {
            bPushPreRecordPage = false            
        }
    }
    Component.onCompleted:
    {
        bLockOnCompleted = true;

        //console.log("Eins: " + settings.workoutType);
        //console.log("Zwei: " + SharedResources.arrayWorkoutTypes.map(function(e) { return e.name; }).indexOf(settings.workoutType));
        //console.log("Drei: " + SharedResources.arrayWorkoutTypes.map(function(e) { return e.name; }));

        //This is a crazy thing, but at least it returns the index :-)
        cmbWorkout.currentIndex = SharedResources.arrayWorkoutTypes.map(function(e) { return e.name; }).indexOf(settings.workoutType);

        txtswUseHRMdevice.checked = settings.useHRMdevice;
        txtswRecordPagePreventScreenBlank.checked = settings.disableScreenBlanking;

        bLockOnCompleted = false;
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
