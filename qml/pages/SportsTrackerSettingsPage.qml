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

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../tools/SportsTracker.js" as ST

Page {
    id: page
    onStatusChanged:
    {
        if (status === PageStatus.Active)
        {
            console.log("Active MapSettingsPage");
        }
        else if (status === PageStatus.Activating){
            st_username.text = settings.stUsername;
            st_password.text = settings.stPassword;
            id_st_auto_upload.checked = settings.stAutoUpload;
            st_sharing.currentIndex = ST.sharingOptionToIndex(settings.stSharing);
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
                title: qsTr("Sports-Tracker.com settings")
            }
            TextSwitch
            {
                id: id_st_auto_upload
                visible:false;
                text: qsTr("Auto upload");
                description: qsTr("Send workout automatically to Sports-Tracker.com after exercise")
                onCheckedChanged:
                {
                    settings.stAutoUpload = checked;
                }
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            Column {
                width: parent.width

                TextField {
                    id: st_username
                    placeholderText: qsTr("Enter Username")
                    label: qsTr("Username")
                    width: parent.width

                    EnterKey.enabled: text.length > 0
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: {
                        settings.stUsername = st_username.text;
                        st_password.focus = true;
                    }
                    onFocusChanged: {
                        if (st_username.focus === false){
                            settings.stUsername = st_username.text;
                        }
                    }
                }
                PasswordField {
                    id: st_password
                    placeholderText: qsTr("Enter Password")
                    label: qsTr("Password")
                    width: parent.width
                    EnterKey.enabled: text.length > 0
                    EnterKey.iconSource: "image://theme/icon-m-enter-close"
                    EnterKey.onClicked:{
                        focus = false
                        settings.stPassword = st_password.text;
                    }
                    onFocusChanged: {
                        if (st_username.focus === false){
                            settings.stPassword = st_password.text;
                        }
                    }
                }
                TextSwitch
                {
                    id: shpassword
                    text: qsTr("Show password");
                    description: qsTr("")
                    onCheckedChanged:
                    {
                        if (shpassword.checked){
                            st_password.passwordEchoMode = TextInput.Normal;
                        }
                        else{
                            st_password.passwordEchoMode = TextInput.Password;
                        }
                    }
                }
                ComboBox
                {
                    id: st_sharing
                    label: qsTr("Default Sharing option")
                    menu: ContextMenu
                    {
                        MenuItem
                        {
                            text: qsTr("Private")
                            onClicked:{
                                settings.stSharing = 0;
                            }
                        }
                        MenuItem
                        {
                            text: qsTr("Followers")
                            onClicked:{
                                settings.stSharing = 17;
                            }
                        }
                        MenuItem
                        {
                            text: qsTr("Public")
                            onClicked:{
                                settings.stSharing = 19;
                            }
                        }
                    }
                }
            }
        }
    }
}
