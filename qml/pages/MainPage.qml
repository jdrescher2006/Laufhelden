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
import "../tools/JSTools.js" as JSTools
import "../tools/SportsTracker.js" as ST
import com.pipacs.o2 1.0
import SortFilterProxyModel 0.2

Page
{
    id: mainPage

    allowedOrientations: settings.recordPagePortrait ? Orientation.Portrait : Orientation.All

    property bool bLockFirstPageLoad: true
    property bool bLockOnCompleted : true;
    property int iLoadFileGPX: 0
    property int iGPXFiles: 100
    property bool bLoadingFiles: false

    property string sWorkoutDuration: ""
    property string sWorkoutDistance: ""
    property string sWorkoutCount: ""
    property string sWorkoutFilter: ""

    property int iCurrentWorkout: 0

    TrackLoader
    {
        id: trackLoader
    }

    function fncSetWorkoutFilter()
    {
        sWorkoutDistance = (settings.measureSystem === 0) ? (SharedResources.arrayLookupWorkoutFilterMainPageTableByName[settings.workoutTypeMainPage].iDistance/1000).toFixed(2) + "km" : JSTools.fncConvertDistanceToImperial(SharedResources.arrayLookupWorkoutTableByName[settings.workoutTypeMainPage].iDistance/1000).toFixed(2) + "mi";

        var iDuration = SharedResources.arrayLookupWorkoutFilterMainPageTableByName[settings.workoutTypeMainPage].iDuration;
        iDuration = Math.floor(iDuration);
        var hours = iDuration / (60*60);
        hours = Math.floor(hours);
        var minutes = (iDuration - hours*60*60) / 60;
        minutes = Math.floor(minutes);
        var seconds = iDuration - hours*60*60 - minutes*60;
        seconds = Math.floor(seconds);

        sWorkoutDuration = (JSTools.fncPadZeros(hours, 2)).toString() + "h " + (JSTools.fncPadZeros(minutes, 2)).toString() + "m " + (JSTools.fncPadZeros(seconds, 2)).toString() + "s";

        sWorkoutCount = (SharedResources.arrayLookupWorkoutFilterMainPageTableByName[settings.workoutTypeMainPage].iWorkouts).toString();

        if (settings.workoutTypeMainPage === "allworkouts")
            sWorkoutFilter = "";
        else
            sWorkoutFilter = settings.workoutTypeMainPage;

        //Find current year and week
        var sCurrentDate = new Date(Date.now());
        //console.log("Jahr: " + sCurrentDate.getFullYear() + ", Woche: " + SharedResources.fncGetWeek(sCurrentDate));

        //TODO/DEBUG: remove -3 here!!!
        var sWeekYear = ((SharedResources.fncGetWeek(sCurrentDate)) - 3).toString() + "." + (sCurrentDate.getFullYear()).toString();

        var iFoundIndex = -1;
        var bFoundValue = SharedResources.arrayLookupWorkoutFilterMainPageTableByName[settings.workoutTypeMainPage].weeklyData.some(function(sInputWeekYear, index){iFoundIndex = index; return sInputWeekYear.weekyear === this.toString();}, sWeekYear);


        console.log("sCurrentDate: " + sCurrentDate.toString() + ", sWeekYear: " + sWeekYear);

        if (bFoundValue)
        {
            id_TXT_WeeklyWorkoutDistance.text = SharedResources.arrayLookupWorkoutFilterMainPageTableByName[settings.workoutTypeMainPage].weeklyData[iFoundIndex].iWorkouts.toString() + " " + qsTr("workouts") + ", " + ((SharedResources.arrayLookupWorkoutFilterMainPageTableByName[settings.workoutTypeMainPage].weeklyData[iFoundIndex].iDistance)/1000).toFixed(2) + "km";
        }
        else
        {
            id_TXT_WeeklyWorkoutDistance.text = "-";
        }
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

    function displayNotification(text, type, delay){
        console.log(text);
        load_text.text = text;
        if (type === "info"){
            ntimer.interval = delay;
            load_text.color = Theme.primaryColor;
        }
        else if (type === "success"){
            ntimer.interval = delay;
            load_text.color = Theme.primaryColor;
        }
        else if (type === "error"){
            if (ST.loginstate == 1 && ST.recycledlogin === true){
                console.log("Sessionkey might be too old. Trying to login again");
                settings.stSessionkey = "";
                ST.SESSIONKEY = "";
                recycledlogin = false;
                ST.uploadToSportsTracker(stSharing, stComment, displayNotification);
            }
            else{
                ntimer.interval = delay;
                load_text.color = Theme.secondaryHighlightColor;
            }
        }
        ntimer.restart();
        ntimer.start();
    }

    Timer{
        id:ntimer;
        running: false;
        interval: 2000;
        repeat: false;
        onTriggered: {
            detail_busy.running = false;
            main_flickable.visible = true;
            load_text.visible = false;
            ntimer.restart();
            ntimer.start();
        }
    }


    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockOnCompleted = true;
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
                {
                    sPebblePath = sPebbleList[0];
                    id_PebbleWatchComm.setServicePath(sPebblePath); //This sets the path with the BT address to the C++ class and inits the DBUS communication object
                }
            }

            //Sport app on the pebble is no longer required
            bPebbleSportAppRequired = false;

            //If pebble is NOT connected, check if it's connected now
            if (sPebblePath !== "" && settings.enablePebble && !bPebbleConnected)
            {
                bPebbleConnected = id_PebbleWatchComm.isConnected();
            }

            //Set workout filter image and combobox
            imgWorkoutImage.source = SharedResources.arrayLookupWorkoutFilterMainPageTableByName[settings.workoutTypeMainPage].icon;
            cmbWorkoutFilter.currentIndex = SharedResources.arrayWorkoutTypesFilterMainPage.map(function(e) { return e.name; }).indexOf(settings.workoutTypeMainPage);

			//On start of App load acceleration array file
			id_HistoryModel.loadAccelerationFile();

            bLockOnCompleted = false;
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

            //Load history model. This is triggered if a workout was edited on the detailspage.
            if (bLoadHistoryData)
            {                
                iLoadFileGPX = 0;
                bLoadingFiles = true;

                //Check if there are more GPX files and add those files to the m_trackList array
                id_HistoryModel.readDirectory();
                //Go through trackList array and load all GPX files which have ready==false
                id_HistoryModel.loadAllTracks();

                bLoadHistoryData = false;
            }          
        }
    }

    BusyIndicator
    {
        id: detail_busy
        visible: false
        anchors.centerIn: main_flickable
        running: true
        size: BusyIndicatorSize.Large
    }
    Label {
         id:load_text
         width: parent.width
         anchors.top: detail_busy.bottom
         anchors.topMargin: 25;
         horizontalAlignment: Label.AlignHCenter
         visible: false
         text: "loading..."
         font.pixelSize: Theme.fontSizeMedium
    }

    SortFilterProxyModel
    {
        id: filterProxyModel
        sourceModel: id_HistoryModel
        filters: RegExpFilter
        {
            roleName: "workout"
            pattern: sWorkoutFilter
            caseSensitivity: Qt.CaseInsensitive
        }
        sorters:
        {
            enabled: false
        }
    }

    Connections
    {
        target: id_HistoryModel
        onSigLoadingFinished:     //This is called from C++ if the loading of the GPX files is ready
        {            
            //console.log("Workout rowCount: " + id_HistoryModel.rowCount());

            //Reset model for ListView
            //historyList.model = undefined;
            //Set new model for ListView from c++
            //historyList.model = id_HistoryModel;

            filterProxyModel.sourceModel = id_HistoryModel;

            var sWorkoutCurrent, fDistanceCurrent, iDurationCurrent
            //Go through all workouts
            for (var i = 0; i < id_HistoryModel.rowCount(); i++)
            {                                
                sWorkoutCurrent =  id_HistoryModel.workouttypeAt(i);
                iDurationCurrent = id_HistoryModel.durationAt(i);
                fDistanceCurrent = id_HistoryModel.distanceAt(i);

                //console.log("workout: " + sWorkoutCurrent + ", duration : " + iDurationCurrent + ", distance: " + fDistanceCurrent);

                if (sWorkoutCurrent === "" || iDurationCurrent === 0 || fDistanceCurrent === 0)
                    continue;

                SharedResources.arrayLookupWorkoutFilterMainPageTableByName[sWorkoutCurrent].iDistance = SharedResources.arrayLookupWorkoutFilterMainPageTableByName[sWorkoutCurrent].iDistance + fDistanceCurrent;
                SharedResources.arrayLookupWorkoutFilterMainPageTableByName[sWorkoutCurrent].iDuration = SharedResources.arrayLookupWorkoutFilterMainPageTableByName[sWorkoutCurrent].iDuration + iDurationCurrent;
                SharedResources.arrayLookupWorkoutFilterMainPageTableByName[sWorkoutCurrent].iWorkouts++;

                SharedResources.arrayLookupWorkoutFilterMainPageTableByName["allworkouts"].iDistance = SharedResources.arrayLookupWorkoutFilterMainPageTableByName["allworkouts"].iDistance + fDistanceCurrent;
                SharedResources.arrayLookupWorkoutFilterMainPageTableByName["allworkouts"].iDuration = SharedResources.arrayLookupWorkoutFilterMainPageTableByName["allworkouts"].iDuration + iDurationCurrent;
                SharedResources.arrayLookupWorkoutFilterMainPageTableByName["allworkouts"].iWorkouts++;

                //Get year and week
                var sCurrentDate = new Date(id_HistoryModel.dateAt(i));
                //console.log("Jahr: " + sCurrentDate.getFullYear() + ", Woche: " + SharedResources.fncGetWeek(sCurrentDate));

                var sWeekYear = (SharedResources.fncGetWeek(sCurrentDate)).toString() + "." + (sCurrentDate.getFullYear()).toString();

                //Check if entry for this week/year already exists
                //This thing is one ugly beast, find it in jsfiddle: https://jsfiddle.net/9h7zkx2u/66/
                var iFoundIndexAll = -1;
                var bFoundValueAll = SharedResources.arrayLookupWorkoutFilterMainPageTableByName["allworkouts"].weeklyData.some(function(sInputWeekYear, index){iFoundIndexAll = index; return sInputWeekYear.weekyear === this.toString();}, sWeekYear);

                var iFoundIndexCurrent = -1;
                var bFoundValueCurrent = SharedResources.arrayLookupWorkoutFilterMainPageTableByName[sWorkoutCurrent].weeklyData.some(function(sInputWeekYear, index){iFoundIndexCurrent = index; return sInputWeekYear.weekyear === this.toString();}, sWeekYear);

                if (!bFoundValueAll)
                {
                    var sNewEntry = new Object();
                    sNewEntry["weekyear"] = (SharedResources.fncGetWeek(sCurrentDate)).toString() + "." + (sCurrentDate.getFullYear()).toString();
                    sNewEntry["year"] = sCurrentDate.getFullYear();
                    sNewEntry["week"] = SharedResources.fncGetWeek(sCurrentDate);
                    sNewEntry["iDistance"] = fDistanceCurrent;
                    sNewEntry["iDuration"] = iDurationCurrent;
                    sNewEntry["iWorkouts"] = 1;
                    SharedResources.arrayLookupWorkoutFilterMainPageTableByName["allworkouts"].weeklyData.push(sNewEntry);
                }
                else
                {
                    //console.log("Found all!! " + iFoundIndexAll.toString());
                    SharedResources.arrayLookupWorkoutFilterMainPageTableByName["allworkouts"].weeklyData[iFoundIndexAll].iDistance = SharedResources.arrayLookupWorkoutFilterMainPageTableByName["allworkouts"].weeklyData[iFoundIndexAll].iDistance + fDistanceCurrent;
                    SharedResources.arrayLookupWorkoutFilterMainPageTableByName["allworkouts"].weeklyData[iFoundIndexAll].iDuration = SharedResources.arrayLookupWorkoutFilterMainPageTableByName["allworkouts"].weeklyData[iFoundIndexAll].iDuration + fDistanceCurrent;
                    SharedResources.arrayLookupWorkoutFilterMainPageTableByName["allworkouts"].weeklyData[iFoundIndexAll].iWorkouts = SharedResources.arrayLookupWorkoutFilterMainPageTableByName["allworkouts"].weeklyData[iFoundIndexAll].iWorkouts + 1;
                }

                if (!bFoundValueCurrent)
                {
                    var sNewEntry = new Object();
                    sNewEntry["weekyear"] = (SharedResources.fncGetWeek(sCurrentDate)).toString() + "." + (sCurrentDate.getFullYear()).toString();
                    sNewEntry["year"] = sCurrentDate.getFullYear();
                    sNewEntry["week"] = SharedResources.fncGetWeek(sCurrentDate);
                    sNewEntry["iDistance"] = fDistanceCurrent;
                    sNewEntry["iDuration"] = iDurationCurrent;
                    sNewEntry["iWorkouts"] = 1;
                    SharedResources.arrayLookupWorkoutFilterMainPageTableByName[sWorkoutCurrent].weeklyData.push(sNewEntry);
                }
                else
                {
                    //console.log("Found current!! " + iFoundIndexCurrent.toString());
                    SharedResources.arrayLookupWorkoutFilterMainPageTableByName[sWorkoutCurrent].weeklyData[iFoundIndexCurrent].iDistance = SharedResources.arrayLookupWorkoutFilterMainPageTableByName[sWorkoutCurrent].weeklyData[iFoundIndexCurrent].iDistance + fDistanceCurrent;
                    SharedResources.arrayLookupWorkoutFilterMainPageTableByName[sWorkoutCurrent].weeklyData[iFoundIndexCurrent].iDuration = SharedResources.arrayLookupWorkoutFilterMainPageTableByName[sWorkoutCurrent].weeklyData[iFoundIndexCurrent].iDuration + fDistanceCurrent;
                    SharedResources.arrayLookupWorkoutFilterMainPageTableByName[sWorkoutCurrent].weeklyData[iFoundIndexCurrent].iWorkouts = SharedResources.arrayLookupWorkoutFilterMainPageTableByName[sWorkoutCurrent].weeklyData[iFoundIndexCurrent].iWorkouts + 1;
                }
            }

            //console.log("weeklyData: " + SharedResources.arrayLookupWorkoutFilterMainPageTableByName["allworkouts"].weeklyData.length.toString());
            //console.log("Stringify: " + JSON.stringify(SharedResources.arrayWorkoutTypesFilterMainPage));


            fncSetWorkoutFilter();

            bLoadingFiles = false;

            fncCheckAutosave();
        }
        onDataChanged:     //This is called from C++ if the loading of one GPX file is ready
        {
            //console.log("Track loading finished!!!");
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

    SilicaFlickable
    {
        anchors.fill: parent
        contentHeight: clmMainColumn.height       
        id: main_flickable

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
                text: qsTr("My Strava Activities")
                visible: o2strava.linked
                onClicked: {

                    var dialog = pageStack.push(Qt.resolvedUrl("MyStravaActivities.qml"));
                }

                O2 {
                    id: o2strava
                    clientId: "13707"
                    clientSecret: STRAVA_CLIENT_SECRET
                    scope: "write"
                    requestUrl: "https://www.strava.com/oauth/authorize"
                    tokenUrl: "https://www.strava.com/oauth/token"
                }
            }
            MenuItem
            {
                text: qsTr("Start new workout")
                onClicked: pageStack.push(Qt.resolvedUrl("PreRecordPage.qml"))
            }
        }

        Column
        {
            id: clmMainColumn
            width: parent.width

            PageHeader
            {
                id: pageHeader
                title: "Laufhelden"
            }

            Rectangle
            {
                id: itmMainHeaderArea
                width: parent.width
                height: (mainPage.height - pageHeader.height) / 3.9
                color: "red"

                Rectangle
                {                    
                    width: parent.width
                    height: parent.height / 3.2
                    visible: !bLoadingFiles
                    color: "green"

                    Row
				    {
				        width: parent.width
                        //spacing: Theme.paddingSmall

                        Image
                        {
                            id: imgWorkoutImage
                            height: parent.width / 14
                            width: parent.width / 14
                            anchors.verticalCenter: parent.verticalCenter
                            fillMode: Image.PreserveAspectFit
                        }                       
                        ComboBox
                        {
                            id: cmbWorkoutFilter
                            anchors.verticalCenter: parent.verticalCenter
                            label: qsTr("Filter:")
                            menu: ContextMenu
                            {
                                Repeater
                                {
                                    id: idRepeaterFilterWorkout
                                    model: SharedResources.arrayWorkoutTypesFilterMainPage;
                                    MenuItem { text: modelData.labeltext }
                                }
                            }
                            onCurrentItemChanged:
                            {
                                if (bLockOnCompleted)
                                    return;

                                imgWorkoutImage.source = SharedResources.arrayWorkoutTypesFilterMainPage[currentIndex].icon;
                                settings.workoutTypeMainPage = SharedResources.arrayWorkoutTypesFilterMainPage[currentIndex].name;

                                fncSetWorkoutFilter();
                            }
                        }
                    }
                }
                Rectangle
                {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.bottom: parent.bottom
                    width: parent.width - Theme.paddingLarge
                    height: (parent.height / 3) * 1.5
                    visible: !bLoadingFiles
                    color: "blue"

                    Item
                    {
                        width: parent.height
                        height: parent.height

                        Label
                        {
                            id: id_LBL_WorkoutCount
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: parent.height / 7
                            text: historyList.count === 0 ? "0" : sWorkoutCount;
                            font.pixelSize: parent.height / 2.3
                        }
                        Label
                        {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: parent.height / 5
                            text: qsTr("workouts")
                            font.pixelSize: parent.height / 7
                        }

                        Image
                        {
                            anchors.fill: parent
                            source: "../img/circle.png"
                        }
                    }
                    Item
                    {
                        width: parent.width - parent.height
                        height: parent.height / 3
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.leftMargin: parent.height

                        Image
                        {
                            source: "../img/length.png"
                            height: parent.height
                            width: parent.height
                            anchors.leftMargin: Theme.paddingLarge
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Label
                        {
                            anchors.left: parent.left
                            anchors.leftMargin: parent.height + Theme.paddingLarge + Theme.paddingSmall
                            anchors.verticalCenter: parent.verticalCenter
                            x: Theme.paddingLarge
                            truncationMode: TruncationMode.Fade
                            text: sWorkoutDistance
                            color: Theme.highlightColor
                        }
                    }
                    Item
                    {
                        width: parent.width - parent.height
                        height: parent.height / 3
                        anchors.top: parent.top
                        anchors.topMargin: parent.height / 3
                        anchors.left: parent.left
                        anchors.leftMargin: parent.height

                        Image
                        {
                            source: "../img/time.png"
                            height: parent.height
                            width: parent.height
                            anchors.leftMargin: Theme.paddingLarge
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Label
                        {
                            anchors.left: parent.left
                            anchors.leftMargin: parent.height + Theme.paddingLarge + Theme.paddingSmall
                            anchors.verticalCenter: parent.verticalCenter
                            x: Theme.paddingLarge
                            truncationMode: TruncationMode.Fade
                            text: sWorkoutDuration
                            color: Theme.highlightColor
                        }
                    }
                    Item
                    {
                        width: parent.width - parent.height
                        height: parent.height / 3
                        anchors.top: parent.top
                        anchors.topMargin: (parent.height / 3) * 2
                        anchors.left: parent.left
                        anchors.leftMargin: parent.height

                        Image
                        {
                            source: "../img/calendar.png"
                            height: parent.height
                            width: parent.height
                            anchors.leftMargin: Theme.paddingLarge
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Label
                        {
                            id: id_TXT_WeeklyWorkoutDistance
                            anchors.left: parent.left
                            anchors.leftMargin: parent.height + Theme.paddingLarge + Theme.paddingSmall
                            anchors.verticalCenter: parent.verticalCenter
                            x: Theme.paddingLarge
                            truncationMode: TruncationMode.Fade
                            text: ""
                            color: Theme.highlightColor
                        }
                    }
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
            }

            Item
            {
                width: parent.width
                height: Theme.paddingLarge + Theme.paddingLarge
            }

            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }

            SilicaListView
            {                
                width: parent.width
                height: (((mainPage.height - pageHeader.height) / 4) * 3) - Theme.paddingLarge - Theme.paddingLarge
                id: historyList
                model: filterProxyModel
                clip: true

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
                                console.log("type: " + workout);
                                console.log("description: " + description);

                                iCurrentWorkout = SharedResources.fncGetIndexByName(workout);

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

                                    iLoadFileGPX = 0;
                                    bLoadingFiles = true;

                                    id_HistoryModel.editTrack(index);
                                    id_HistoryModel.loadAllTracks();
                                })
                            }
                        }
                        MenuItem
                        {
                            text: qsTr("Send to Sports-Tracker.com")
                            visible: settings.stUsername === "" ? false:true
                            onClicked: {
                                trackLoader.filename = filename;
                                var dialog = pageStack.push(Qt.resolvedUrl("SportsTrackerUploadPage.qml"),{ stcomment: description});
                                dialog.accepted.connect(function() {
                                    detail_busy.running = true;
                                    detail_busy.visible = true;
                                    load_text.visible = true;
                                    main_flickable.visible = false;
                                    ST.uploadToSportsTracker(dialog.sharing*1, dialog.stcomment, displayNotification);
                                });
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
                        text: name==="" ? qsTr("(Unnamed track)") : name
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
                        text: (settings.measureSystem === 0) ? (distance/1000).toFixed(2) + "km" : JSTools.fncConvertDistanceToImperial(distance/1000).toFixed(2) + "mi"
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
                        text: (settings.measureSystem === 0) ? speed.toFixed(1) + "km/h" : JSTools.fncConvertSpeedToImperial(speed).toFixed(1) + "mi/h"
                    }
                    onClicked: pageStack.push(Qt.resolvedUrl("DetailedViewPage.qml"),
                                              {filename: filename, name: name, index: index})
                }
            }
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
                        width:parent.width

                        Image
                        {
                            id: imgDialogWorkoutImage
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

                                imgDialogWorkoutImage.source = SharedResources.arrayWorkoutTypes[currentIndex].icon;
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
