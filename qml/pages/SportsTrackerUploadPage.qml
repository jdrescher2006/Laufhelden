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

    onStatusChanged:{
        if (status === PageStatus.Activating){
            st_sharing.currentIndex = ST.sharingOptionToIndex(settings.stSharing);
            sharing = settings.stSharing;
            if (stcomment != "-"){
                st_description.text = stcomment;
            }
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
    }

    onAccepted: {
        if (result == DialogResult.Accepted) {
            stcomment = st_description.text;
        }
    }
}
