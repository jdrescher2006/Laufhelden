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
import harbour.laufhelden 1.0
import "../tools/SportsTracker.js" as ST

Page {
    id: page

    property bool downloadingGPX: false;

    onStatusChanged:
    {
        if (status === PageStatus.Active) {
            console.log("Active SportsTrackerSettingsPage");
        }
        else if (status === PageStatus.Activating){
            st_username.text = settings.stUsername;
            st_password.text = settings.stPassword;
            id_st_auto_upload.checked = settings.stAutoUpload;
            st_sharing.currentIndex = ST.sharingOptionToIndex(settings.stSharing);
        }
    }

    //Test login, calls success or error -functions
    function testlogin(){
        if (ST.SESSIONKEY == ""){
            login_message.text = qsTr("Test login...")
            ST.loginSportsTracker(success, error, st_username.text, st_password.text);
        }
        else{
            login_message.text = qsTr("Already authenticated")
        }
    }

    //Testlogin message
    function success(){
        login_message.text = qsTr("Login success!");
        settings.stSessionkey = ST.SESSIONKEY;
    }

    //Testlogin message
    function error(message){
        login_message.text = qsTr("Login error, Check username or password")
        login_message.color = Theme.highlightColor
        downloadingGPX = false;
    }

    //Workout loading messages
    function loadingMessage(text, type, delay){
        login_message.text = text
        login_message.color = Theme.highlightColor
        if (type === "info"){
            login_message.color = Theme.primaryColor;
        }
        else if (type === "success"){
            login_message.color = Theme.highlightColor;
        }
        else if (type === "error"){
            downloadingGPX = false;
            workoutdownload.visible = false;
            countselector.visible = true;
            bLoadHistoryData = true; //Load main page again after download
            downloadingGPX = false;
            workoutdownload.value = 0;
            workoutdownload.maximumValue = 0;
            if (ST.loginstate == 1 && ST.recycledlogin === true){
                console.log("Sessionkey might be too old. Trying to login again");
                settings.stSessionkey = "";
                ST.SESSIONKEY = "";
                recycledlogin = false;
                ST.loginSportsTracker(ST.loadWorkouts, loadingMessage, settings.stUsername, settings.stPassword);
            }
            else{
                login_message.color = Theme.highlightColor;
            }
        }
    }

    function downloadWorkouts(){
        //Set common callbacks
        ST.writecallback = writeGpxToFile;
        ST.downloadDoneCallback = allDownloaded;

        downloadingGPX = true;
        workoutdownload.visible = true;
        ST.loginstate = 1;

        //Read workoutkeys from existing workouts from phone
        for (var i=0; i<id_HistoryModel.rowCount(); i++){
            var workoutkey = id_HistoryModel.getSportsTrackerKey(i);
            if (workoutkey !== ""){
                ST.existingkeys[ST.existingkeys.length] = workoutkey;
            }
        }

        //Login only if we dont have sessionkey
        if (settings.stSessionkey === ""){
            login_message.text = qsTr("Loading workouts...");
            ST.loginSportsTracker(ST.loadWorkouts, loadingMessage, settings.stUsername, settings.stPassword);
        }
        else{
            ST.recycledlogin = true;
            ST.SESSIONKEY = settings.stSessionkey; //Read stored sessionkey and use it.
            console.log("Already authenticated, trying to use existing sessionkey");
            ST.loadWorkouts();
        }
    }


    function writeGpxToFile(gpx, recorded, desc, stkey, activity, distance){
        var writeok = trackRecorder.writeStGpxToFile(gpx, recorded, desc, stkey, activity, distance);
        if (writeok === false){
            login_message.text = qsTr("Track write error")
            login_message.color = Theme.highlightColor
        }

        //Look next exercise
        if (ST.numofitems > 0 && ST.currentitem < ST.numofitems){
            workoutdownload.value = ST.currentitem;
            workoutdownload.maximumValue = ST.numofitems;
            workoutdownload.valueText = workoutdownload.value + " " + qsTr("of") + " " + ST.numofitems;
            ST.exportNextGPX();
            return;
        }
        allDownloaded();
    }

    function allDownloaded(){
        workoutdownload.visible = false;
        countselector.visible = true;
        login_message.text = ST.currentitem +qsTr(" unique workout downloaded!");
        bLoadHistoryData = true; //Load main page again after download
        downloadingGPX = false;
        workoutdownload.value = 0;
        workoutdownload.maximumValue = 0;
        ST.loginstate = 0;
    }

    //Trackrecorder is used to write GPX to filesystem
    TrackRecorder{
        id: trackRecorder
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
                 spacing: Theme.paddingLarge

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
                        ST.SESSIONKEY = "";
                        settings.stSessionkey = "";
                    }
                    onFocusChanged: {
                        if (st_username.focus === false){
                            settings.stUsername = st_username.text;
                            ST.SESSIONKEY = "";
                            settings.stSessionkey = "";
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
                        ST.SESSIONKEY = "";
                        settings.stSessionkey = "";
                    }
                    onFocusChanged: {
                        if (st_username.focus === false){
                            settings.stPassword = st_password.text;
                            ST.SESSIONKEY = "";
                            settings.stSessionkey = "";
                        }
                    }
                }
                /*TextSwitch
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
                }*/
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
                Button{
                    width: parent.width/2
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Test login")
                    onClicked: {
                        if (downloadingGPX == false){
                            testlogin();
                        }
                    }
                }
                Separator
                {
                    anchors.topMargin: 50
                    color: Theme.highlightColor
                    width: parent.width
                }
                Label{
                    id:login_message
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                    text: ""
                }

                Button{
                    width: parent.width/2
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Download workouts")
                    onClicked: {
                        if (downloadingGPX == false){
                            ST.maxdownloadcount = countselector.value
                            countselector.visible = false
                            downloadWorkouts();
                        }
                    }
                }
                Slider {
                     id: countselector
                     label: qsTr("Maximum number to download")
                     width: parent.width
                     minimumValue: 1
                     maximumValue: 1000
                     value: ST.maxdownloadcount
                     stepSize: 10
                     valueText: value
                 }
                ProgressBar
                {
                    id: workoutdownload
                    width: parent.width
                    maximumValue: ST.numofitems
                    valueText: ""
                    label: qsTr("Downloading GPX files")
                    value: ST.currentitem
                    visible: false
                }
            }
        }
    }
}
