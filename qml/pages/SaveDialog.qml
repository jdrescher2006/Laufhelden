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

Dialog {
    id: saveDialog
    allowedOrientations: Orientation.Portrait
    property string name
    property string description

    onDone: {
        name = nameField.text;
        description = descriptionField.text;
    }

    Column {
        anchors.fill: parent
        DialogHeader {
            title: "Save track"
            acceptText: "Save"
        }
        TextField {
            id: nameField
            x: Theme.paddingLarge
            width: parent.width - Theme.paddingLarge
            focus: true
            label: qsTr("Name")
            placeholderText: qsTr("Name")
            text: recorder.startingDateTime + " - " + SharedResources.arrayLookupWorkoutTableByName[settings.workoutType].labeltext
            EnterKey.enabled: true
            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: descriptionField.focus = true
        }
        TextArea {
            id: descriptionField
            x: Theme.paddingLarge
            width: parent.width - Theme.paddingLarge
            focus: true
            label: qsTr("Description")
            placeholderText: qsTr("Description")
            text: ""
            EnterKey.enabled: true
            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            EnterKey.onClicked: accept()
        }
    }
}
