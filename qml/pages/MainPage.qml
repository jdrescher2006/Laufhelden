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
import harbour.laufhelden 1.0
import "../tools/SharedResources.js" as SharedResources
import "../tools/Thresholds.js" as Thresholds

Page
{
    id: mainPage

    allowedOrientations: settings.recordPagePortrait ? Orientation.Portrait : Orientation.All

    property bool bLockFirstPageLoad: true
    property int iLoadFileGPX: 0
    property int iGPXFiles: 100
    property bool bLoadingFiles: false

    property string sWorkoutDuration: ""
    property string sWorkoutDistance: ""

    property int iCurrentWorkout: 0

    TrackLoader
    {
        id: trackLoader
    }

    function fncCheckAutosave()
    {

        console.log("recorder.isEmpty: " + recorder.isEmpty.toString());

        if (recorder.isEmpty === false)
        {
            var dialog = pageStack.push(id_Dialog_Autosave)
            dialog.accepted.connect(function()
            {
                //console.log("Accepted");
                //Accept means the users wants to resume the workout
                recorder.workoutType = settings.workoutType;
                pageStack.push(Qt.resolvedUrl("RecordPage.qml"));
            })
            dialog.rejected.connect(function()
            {
                console.log("Canceled");
                //Cancel means the users wants to delete the workout
                recorder.clearTrack();
            })
        }
    }

    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockFirstPageLoad = false;
            console.log("First Active MainPage");

            //Init log file. Save first string.
            //if (settings.enableLogFile) id_LogWriter.vWriteStart("Version: " + Qt.application.version + "\r\n" + "Date: " + Date() + "\r\n-------------------------------\r\n");
            //id_LogWriter.vWriteStart("Version: " + Qt.application.version + "\r\n" + "Date: " + Date() + "\r\n-------------------------------\r\n");
            //id_LogWriter.vWriteData("Test Eintrag..." + "\r\n");

            //Read settings to QML variables
            var sTemp = settings.hrmdevice;
            sTemp = sTemp.split(',');
            if (sTemp.length === 2)
            {
                sHRMAddress = sTemp[0];
                sHRMDeviceName = sTemp[1];
            }
            else
            {
                sHRMAddress = "";
                sHRMDeviceName = "";
            }

            //Search for pebble watch
            if (settings.enablePebble)
            {
                var sPebbleList = id_PebbleManagerComm.getListWatches();
                console.log("sPebbleList: " + sPebbleList);

                if (sPebbleList !== undefined && sPebbleList.length > 0)
                    sPebblePath = sPebbleList[0];
            }

            //Sport app on the pebble is no longer required
            bPebbleSportAppRequired = false;

            //If pebble is NOT connected, check if it's connected now
            if (sPebblePath !== "" && settings.enablePebble && !bPebbleConnected)
                bPebbleConnected = pebbleComm.bIsPebbleConnected();
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("Active MainPage");            

            //stop positioning
            recorder.vEndGPS();

            //close pebble sport app
            if (sPebblePath !== "" && settings.enablePebble)
            {
                pebbleComm.fncClosePebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970");
            }

            //Save the object of this page for back jumps
            vMainPageObject = pageStack.currentPage;
            console.log("vMainPageObject: " + vMainPageObject.toString());

            //Load history model.
            if (bLoadHistoryData)
            {
                iLoadFileGPX = 0;

                bLoadingFiles = true;

                id_HistoryModel.readDirectory();

                bLoadHistoryData = false;
            }
        }
    }


    Connections
    {
        target: id_HistoryModel
        onSigLoadingFinished:     //This is called from C++ if the loading of the GPX files is ready
        {            
            console.log("Workout rowCount: " + id_HistoryModel.rowCount());
            console.log("Workout distance: " + id_HistoryModel.rDistance());
            console.log("Workout duration: " + id_HistoryModel.iDuration());            

            var iHours = Math.floor(id_HistoryModel.iDuration() / 3600);
            console.log("iHours: " + iHours);

            var iMinutes = Math.floor((id_HistoryModel.iDuration() - iHours * 3600) / 60);
            console.log("iMinutes: " + iMinutes);

            var iSeconds = Math.floor(id_HistoryModel.iDuration() - (iHours * 3600) - (iMinutes * 60));

            sWorkoutDuration = iHours + "h " + iMinutes + "m " + iSeconds + "s";
            sWorkoutDistance = (id_HistoryModel.rDistance() / 1000).toFixed(1);

            historyList.model = undefined;
            historyList.model = id_HistoryModel;            

            bLoadingFiles = false;

            fncCheckAutosave();
        }
        onDataChanged:     //This is called from C++ if the loading of one GPX file is ready
        {
            console.log("Track loading finished!!!");
            iLoadFileGPX++;
        }
        onSigAmountGPXFiles:
        {
            console.log("Amount of tracks: " + iAmountGPXFiles.toString());
            iGPXFiles = iAmountGPXFiles;
        }
        onSigLoadingError:
        {
            console.log("Error while loading GPX files");

            bLoadingFiles = false;

            fncCheckAutosave();
        }
    }

    SilicaListView
    {
        anchors.fill: parent
        id: historyList
        model: id_HistoryModel
        VerticalScrollDecorator {}

        PullDownMenu
        {
            id: menu
            MenuItem
            {
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem
            {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsMenu.qml"))
            }
            MenuItem
            {
                text: qsTr("Start new workout")
                onClicked: pageStack.push(Qt.resolvedUrl("PreRecordPage.qml"))
            }
        }

        header: Column
        {
            spacing: Theme.paddingLarge;
            anchors {
                left: parent.left;
                right: parent.right;
            }

            PageHeader {
                title: qsTr("Welcome to Laufhelden")
            }

            Row
            {
                width: parent.width
                height: parent.height / 4
                visible: !bLoadingFiles

                Item
                {
                    width: parent.width / 2
                    height: parent.height

                    Image
                    {
                        source: "../img/length.png"
                        height: parent.height
                        width: parent.height
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Label
                    {
                        anchors.left: parent.left
                        anchors.leftMargin: parent.height + Theme.paddingMedium
                        anchors.verticalCenter: parent.verticalCenter
                        x: Theme.paddingLarge
                        truncationMode: TruncationMode.Fade
                        text: sWorkoutDistance + "km"
                        color: Theme.highlightColor
                    }
                }
                Item
                {
                    width: parent.width / 2
                    height: parent.height

                    Image
                    {
                        id: idIMGTime
                        source: "../img/time.png"
                        height: parent.height
                        width: parent.height
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Label
                    {
                        anchors.left: parent.left
                        anchors.leftMargin: parent.height + Theme.paddingMedium
                        anchors.verticalCenter: parent.verticalCenter
                        x: Theme.paddingLarge
                        truncationMode: TruncationMode.Fade
                        text: sWorkoutDuration
                        color: Theme.highlightColor
                    }
                }
            }
            Label
            {
                anchors.horizontalCenter: parent.horizontalCenter
                id: id_LBL_WorkoutCount
                x: Theme.paddingLarge
                truncationMode: TruncationMode.Fade
                text: historyList.count === 0 ? qsTr("No earlier workouts") : qsTr("Workouts: ") + (historyList.count).toString();
                color: Theme.highlightColor
                visible: !bLoadingFiles
            }


            ProgressBar
            {
                id: progressBarWaitLoadGPX
                width: parent.width
                maximumValue: iGPXFiles
                valueText: value + " " + qsTr("of") + " " + iGPXFiles
                label: qsTr("Loading GPX files...")
                value: iLoadFileGPX
                visible: bLoadingFiles
            }

            Separator
            {
                color: Theme.highlightColor;
                anchors {
                    left: parent.left;
                    right: parent.right;
                }
            }
        }

        delegate: ListItem
        {
            id: listItem
            width: parent.width
            ListView.onRemove: animateRemoval()
            menu: ContextMenu
            {
                MenuItem
                {
                    text: qsTr("Remove workout")
                    onClicked: remorseAction(qsTr("Removing workout..."), listItem.deleteTrack)
                }
                MenuItem
                {
                    text: qsTr("Edit workout")
                    onClicked:
                    {
                        console.log("Filename: " + filename);
                        console.log("name: " + name);
                        console.log("name: " + workout);
                        console.log("description: " + description);

                        iCurrentWorkout = SharedResources.fncGetIndexByName(trackLoader.workout);

                        var dialog = pageStack.push(id_Dialog_EditWorkout);
                        dialog.sName = name;
                        dialog.sDesc = description;
                        dialog.iWorkout = SharedResources.fncGetIndexByName(workout);

                        dialog.accepted.connect(function()
                        {
                            //Edit and save GPX file
                            trackLoader.vReadFile(filename);
                            trackLoader.vSetNewProperties(name, description, workout, dialog.sName, dialog.sDesc, dialog.sWorkout)
                            trackLoader.vWriteFile(filename);

                            //Reload all GPX files
                            iLoadFileGPX = 0;
                            bLoadingFiles = true;
                            id_HistoryModel.readDirectory();
                        })
                    }
                }
            }

            function deleteTrack()
            {
                id_HistoryModel.removeTrack(index);
            }


            Image
            {
                id: workoutImage
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingMedium
                x: Theme.paddingSmall
                width: Theme.paddingMedium * 3
                height: Theme.paddingMedium * 3
                source: workout==="" ? "" : SharedResources.arrayLookupWorkoutTableByName[workout].icon
            }
            Label
            {
                id: nameLabel
                x: Theme.paddingLarge * 2
                width: parent.width - dateLabel.width - 2*Theme.paddingLarge
                anchors.top: parent.top
                truncationMode: TruncationMode.Fade
                text: name==="" ? "(Unnamed track)" : name
                color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            Label
            {
                id: dateLabel
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                text: date
                color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            Label
            {
                anchors.top: nameLabel.bottom
                x: Theme.paddingLarge * 2
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: distance
            }
            Label
            {
                anchors.top: nameLabel.bottom
                x: (parent.width - width) / 2
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: duration
            }
            Label
            {
                anchors.top: nameLabel.bottom
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: speed
            }
            onClicked: pageStack.push(Qt.resolvedUrl("DetailedViewPage.qml"),
                                      {filename: filename, name: name})
        }
    }
    Component
    {
        id: id_Dialog_Autosave        

        Dialog
        {
            width: parent.width
            canAccept: true
            acceptDestination: mainPage
            acceptDestinationAction: PageStackAction.Pop


            Flickable
            {
                width: parent.width
                height: parent.height
                interactive: false

                Column
                {
                    width: parent.width

                    DialogHeader
                    {
                        title: qsTr("Uncompleted workout found!")
                        defaultAcceptText: qsTr("Resume")
                    }
                }
            }
        }
    }
    Component
    {
        id: id_Dialog_EditWorkout


        Dialog
        {
            property string sName
            property string sDesc
            property int iWorkout
            property string sWorkout

            canAccept: true
            acceptDestination: mainPage
            acceptDestinationAction:
            {
                sName = id_TXF_WorkoutName.text;
                sDesc = id_TXF_WorkoutDesc.text;
                iWorkout = cmbWorkout.currentIndex;

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

                    DialogHeader { title: qsTr("Edit workout") }

                    TextField
                    {
                        id: id_TXF_WorkoutName
                        width: parent.width
                        label: qsTr("Workout name")
                        placeholderText: qsTr("Workout name")
                        text: sName
                        inputMethodHints: Qt.ImhNoPredictiveText
                        focus: true
                        horizontalAlignment: TextInput.AlignLeft
                    }
                    Item
                    {
                        width: parent.width
                        height: Theme.paddingLarge
                    }
                    TextField
                    {
                        id: id_TXF_WorkoutDesc
                        width: parent.width
                        label: qsTr("Workout description")
                        placeholderText: qsTr("Workout description")
                        text: sDesc
                        inputMethodHints: Qt.ImhNoPredictiveText
                        focus: true
                        horizontalAlignment: TextInput.AlignLeft
                    }
                    Item
                    {
                        width: parent.width
                        height: Theme.paddingLarge
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
                            currentIndex: iCurrentWorkout
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
                                console.log("Workout changed!");

                                imgWorkoutImage.source = SharedResources.arrayWorkoutTypes[currentIndex].icon;
                                iWorkout = currentIndex;
                                sWorkout = SharedResources.arrayWorkoutTypes[currentIndex].name;
                            }
                        }
                    }
                }
            }
        }
    }
}
