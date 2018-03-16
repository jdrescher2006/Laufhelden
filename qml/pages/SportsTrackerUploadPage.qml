/*
 * Copyright (C) 2017 Jussi Nieminen, Finland
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

import QtQuick 2.2
import Sailfish.Silica 1.0
import "../tools/SportsTracker.js" as ST

Dialog {
    property int sharing: 0;
    property string stcomment: "";
    //property string defaultActivity: 0;

    onStatusChanged:{
        if (status === PageStatus.Activating){
            st_sharing.currentIndex = ST.sharingOptionToIndex(settings.stSharing);
            sharing = settings.stSharing;
            if (stcomment != "-"){
                st_description.text = stcomment;
            }
            /*for (var i=0; i< ST.stActivityLookup.length; i++){
                listModel.append({"name": ST.stActivityLookup[i]});
            }
            st_workout_type.currentIndex = defaultActivity;*/
        }
    }

    Column {
        id: input_fields
        width: parent.width

        DialogHeader { }

        TextField {
            id: st_description
            width: parent.width
            EnterKey.enabled: text.length > 0
            EnterKey.iconSource: "image://theme/icon-m-enter-close"
            EnterKey.onClicked: {
                stcomment = st_description.text;
            }
            onFocusChanged: {
                if (st_description.focus === false){
                    stcomment = st_description.text;
                }
            }
            placeholderText: qsTr("Give workout description to Sports-Tracker.com")
            label: qsTr("Description")
        }
        ComboBox
        {
            id: st_sharing
            label: qsTr("Share workout")
            menu: ContextMenu
            {
                MenuItem
                {
                    text: qsTr("Private")
                    onClicked:
                    {
                        sharing = 0;
                    }
                }
                MenuItem
                {
                    text: qsTr("Followers")
                    onClicked:
                    {
                        sharing = 17;
                    }
                }
                MenuItem
                {
                    text: qsTr("Public")
                    onClicked:
                    {
                        sharing = 19;
                    }
                }
            }
        }
        /*ComboBox  //Disabled for now. Enabled when tested properly
        {
            id: st_workout_type
            label: qsTr("Workout type")
            menu: ContextMenu {
                Repeater {
                   model: ListModel { id: listModel }
                   MenuItem { text: model.name }
                }
            }
        }*/

    }

    onAccepted: {
        if (result == DialogResult.Accepted) {
            stcomment = st_description.text;
        }
    }
}
