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
import QtPositioning 5.3
import "../tools/JSTools.js" as JSTools
import "../tools/SportsTracker.js" as ST
import "../tools/SharedResources.js" as SharedResources
import com.pipacs.o2 1.0
import "../components/"

Page
{
    id: detailPage
    allowedOrientations: Orientation.All

    property string filename
    property string name
    property int index

    property int stSharing: 0
    property string stComment: ""
    property var vTrackLinePoints

    property int iCurrentWorkout: 0

    property bool bHeartrateSupported: false
    property bool bPaceRelevantForWorkoutType: true
    property int iPausePositionsCount: 0

    property TrackLoader trackLoader

    onStatusChanged:
    {
        if (status === PageStatus.Active)
        {            
            trackLoader.filename = filename;          
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
            detail_flick.visible = true;
            detail_busy.visible = false;
            load_text.visible = false;
            ntimer.restart();
            ntimer.start();
        }
    }

    TrackLoader
    {
        id: trackLoader
        onTrackChanged:
        {
            var trackLength = trackLoader.trackPointCount();
            var pauseLength = trackLoader.pausePositionsCount();
            var iLastProperHeartRate = 0;

            JSTools.arrayDataPoints = [];
            JSTools.trackPointsAt = [];
            JSTools.trackPausePointsTemporary = [];

            for(var i=0; i<trackLength; i++)
            {
                var iHeartrate = trackLoader.heartRateAt(i);

                //Problem is there are often HR points with value 0. This will be solved.
                if (iHeartrate > 0)
                {
                    iLastProperHeartRate = iHeartrate;
                }
                else
                {
                    iHeartrate = iLastProperHeartRate;
                }

                //heartrate,elevation,distance,time,unixtime,speed,pace,pacevalue,paceimp,duration
                JSTools.fncAddDataPoint(iHeartrate, trackLoader.elevationAt(i), trackLoader.distanceAt(i), trackLoader.timeAt(i), trackLoader.unixTimeAt(i), trackLoader.speedAt(i), trackLoader.paceStrAt(i), trackLoader.paceAt(i), trackLoader.paceImperialStrAt(i), trackLoader.durationAt(i));
                JSTools.trackPointsAt.push(trackLoader.trackPointAt(i));
            }                    

            //Go through array with pause data points
            for (i=0; i<pauseLength; i++)
            {
                //add this track point to temporary array in JS.
                JSTools.trackPausePointsTemporary.push(trackLoader.pausePositionAt(i));
            }

            //console.log("JSTools.arrayDataPoints.length: " + JSTools.arrayDataPoints.length.toString());

            bHeartrateSupported = trackLoader.hasHeartRateData();
            bPaceRelevantForWorkoutType = trackLoader.paceRelevantForWorkoutType();
            iPausePositionsCount = trackLoader.pausePositionsCount();

            pageStack.pushAttached(Qt.resolvedUrl("MapViewPage.qml"),
                                   {
                                       bHeartrateSupported: bHeartrateSupported,
                                       bPaceRelevantForWorkoutType: bPaceRelevantForWorkoutType,
                                       trackLoader: trackLoader
                                   });
        }       
    }

    BusyIndicator
    {
        id: detail_busy
        visible: false
        anchors.centerIn: detailPage
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
         text: qsTr("loading...")
         font.pixelSize: Theme.fontSizeMedium
    }

    BusyIndicator
    {
        visible: true
        anchors.centerIn: detailPage
        running: !trackLoader.loaded
        size: BusyIndicatorSize.Large
    }       

    Image
    {
        visible: trackLoader.loaded
        id: id_IMG_WorkoutIcon
        anchors.bottom: id_IMG_PageLocator.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Theme.paddingLarge
        width: parent.width / 4
        height: parent.width / 4
        z: 2
        opacity: 0.2
        source: SharedResources.arrayWorkoutTypes[SharedResources.arrayWorkoutTypes.map(function(e) { return e.name; }).indexOf(trackLoader.workout)].icon
    }
    Label
    {
        visible: trackLoader.loaded
        anchors.horizontalCenter: id_IMG_WorkoutIcon.horizontalCenter
        anchors.verticalCenter: id_IMG_WorkoutIcon.verticalCenter
        horizontalAlignment: Label.AlignHCenter
        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeHuge
        width: parent.width
        z: 3
        text: SharedResources.arrayWorkoutTypes[SharedResources.arrayWorkoutTypes.map(function(e) { return e.name; }).indexOf(trackLoader.workout)].labeltext
    }
    Image
    {
        id: id_IMG_PageLocator
        visible: trackLoader.loaded
        height: parent.width / 14
        width: (parent.width / 14) * 3
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Theme.paddingSmall
        z: 2
        source:"../img/pagelocator_1_3.png"
    }

    SilicaFlickable
    {
        id:detail_flick
        visible: trackLoader.loaded
        anchors.fill: parent
        clip: true
        contentHeight: id_Column_Main.height
        VerticalScrollDecorator {}


        PullDownMenu
        {
            id: menu
            MenuItem
            {
                text: qsTr("Diagrams")
                onClicked: pageStack.push(Qt.resolvedUrl("DiagramViewPage.qml"))
                visible: false
            }
            MenuItem
            {
                text: qsTr("Edit workout")
                onClicked:
                {
                    iCurrentWorkout = SharedResources.fncGetIndexByName(trackLoader.workout);

                    var dialog = pageStack.push(id_Dialog_EditWorkout);
                    dialog.sName = trackLoader.name;
                    dialog.sDesc = trackLoader.description;
                    dialog.iWorkout = SharedResources.fncGetIndexByName(trackLoader.workout);

                    dialog.accepted.connect(function()
                    {
                        //Edit and save GPX file
                        trackLoader.vReadFile(filename);
                        trackLoader.vSetNewProperties(name, trackLoader.description, trackLoader.workout, dialog.sName, dialog.sDesc, dialog.sWorkout)
                        trackLoader.vWriteFile(filename);

                        //Set edited values to dialog
                        header.title = dialog.sName;
                        descriptionData.text = dialog.sDesc;

                        id_HistoryModel.editTrack(index);

                        //Mainpage must reload all GPX files
                        bLoadHistoryData = true;
                    })
                }
            }
            MenuItem
            {
                text: qsTr("Send to Sports-Tracker.com")
                visible: settings.stUsername === "" ? false:true
                onClicked: {

                    var dialog = pageStack.push(Qt.resolvedUrl("SportsTrackerUploadPage.qml"),{ stcomment: descriptionData.text});
                    dialog.accepted.connect(function() {
                        detail_busy.running = true;
                        detail_busy.visible = true;
                        load_text.visible = true;
                        detail_flick.visible = false;

                        ST.uploadToSportsTracker(dialog.sharing*1, dialog.stcomment, displayNotification);
                    });
                    dialog.rejected.connect(function() {

                    });

                 }
            }
            MenuItem
            {
                text: qsTr("Send to Strava")
                visible: o2strava.linked
                onClicked: {

                    var dialog = pageStack.push(Qt.resolvedUrl("StravaUploadPage.qml"));
                    dialog.activityID = filename;
                    var gpx = trackLoader.readGpx();
                    dialog.gpx = gpx;
                    dialog.activityName = name;
                    dialog.activityDescription = trackLoader.description;
                    dialog.activityType = trackLoader.workout
                }

                O2 {
                    id: o2strava
                    clientId: STRAVA_CLIENT_ID
                    clientSecret: STRAVA_CLIENT_SECRET
                    scope: "write"
                    requestUrl: "https://www.strava.com/oauth/authorize"
                    tokenUrl: "https://www.strava.com/oauth/token"
                }
            }
        }



        Column
        {
            id: id_Column_Main
            anchors.top: parent.top
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader
            {
                id: header
                title: qsTr("Overview")
            }

            Label
            {
                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeLarge
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
                text: trackLoader.name
            }
            Item
            {
                width: parent.width
                height: Theme.paddingLarge
            }

            Label
            {
                width: parent.width
                horizontalAlignment: Text.AlignLeft
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Description:")
                visible: trackLoader.description !== ""
            }
            Label
            {
                id: descriptionData
                width: parent.width
                text: trackLoader.description
                color: Theme.primaryColor
                wrapMode: Text.WordWrap
                visible: trackLoader.description !== ""
            }

            InfoItem
            {
                label: qsTr("Starting time:")
                value: trackLoader.timeStr
            }
            InfoItem
            {
                label: qsTr("Duration:")
                value: trackLoader.durationStr
            }
            InfoItem
            {
                label: qsTr("Distance:")
                value: (settings.measureSystem === 0) ? ((trackLoader.distance/1000).toFixed(2) + " km") : (JSTools.fncConvertDistanceToImperial(trackLoader.distance/1000).toFixed(2) + " mi")
            }
            InfoItem
            {
                label: qsTr("Speed max/⌀:")
                value: (settings.measureSystem === 0)
                       ? (trackLoader.maxGroundSpeed * 3.6).toFixed(1) + "/" + (trackLoader.speed*3.6).toFixed(1) + " km/h"
                       : (JSTools.fncConvertSpeedToImperial(trackLoader.maxGroundSpeed*3.6)).toFixed(1) + "/" + (JSTools.fncConvertSpeedToImperial(trackLoader.speed*3.6)).toFixed(1) + " mi/h"
            }
            InfoItem
            {
                visible: bPaceRelevantForWorkoutType
                label: qsTr("Pace ⌀:")
                value: (settings.measureSystem === 0) ? trackLoader.paceStr + " min/km" : trackLoader.paceImperialStr + " min/mi"
            }
            InfoItem
            {
                visible: bHeartrateSupported
                label: qsTr("Heart rate min/max/⌀:")
                value: trackLoader.heartRateMin + "/" + trackLoader.heartRateMax + "/" + trackLoader.heartRate.toFixed(1) + " bpm"
            }
            InfoItem
            {
                visible: (iPausePositionsCount > 0)
                label: qsTr("Pause number/duration:")
                value: trackLoader.pauseDurationStr
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
            acceptDestination: detailPage
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
