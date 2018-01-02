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
import QtPositioning 5.3
import MapboxMap 1.0
import harbour.laufhelden 1.0
import "../tools/JSTools.js" as JSTools
import "../tools/SportsTracker.js" as ST
import "../tools/SharedResources.js" as SharedResources
import com.pipacs.o2 1.0

Page
{
    id: detailPage
    allowedOrientations: bMapMaximized ? Orientation.All : Orientation.Portrait
    //No back navigation if the map is big
    backNavigation: !bMapMaximized

    property string filename
    property string name
    property int stSharing: 0
    property string stComment: ""
    property var vTrackLinePoints

    //Map buttons
    property bool showSettingsButton: true
    property bool showMinMaxButton: true
    property bool showCenterButton: true

    property bool bMapMaximized: false

    property int iCurrentWorkout: 0

    onStatusChanged: {
        if (status === PageStatus.Active)
        {
            trackLoader.filename = filename;

            console.log("settings.mapStyle: " + settings.mapStyle);
            map.styleUrl = settings.mapStyle;
        }
    }

    function uploadToSportsTracker(sharing, comment){
        ST.loginstate = 0;
        stComment = comment;
        stSharing = sharing;
        if (settings.stSessionkey === ""){
            displayNotification(qsTr("Logging in..."),"info",25000);
            ST.loginSportsTracker(sendGPX,
                                  displayNotification,
                                  settings.stUsername,
                                  settings.stPassword);
        }
        else{
            ST.recycledlogin = true;
            ST.SESSIONKEY = settings.stSessionkey; //Read stored sessionkey and use it.
            console.log("Already authenticated, trying to use existing sessionkey");
            sendGPX();
        }
    }

    function sendGPX(){
        ST.loginstate = 1;
        displayNotification("Reading GPX file...","info", 25000);
        var gpx = trackLoader.readGpx();
        displayNotification(qsTr("Uploading..."), "info", 25000);
        ST.importGPX(gpx, displayNotification, stSharing, stComment);
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
                uploadToSportsTracker(stSharing, stComment);
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
            map.opacity = 1.0
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

            JSTools.arrayDataPoints = [];

            for(var i=0; i<trackLength; i++)
            {
                JSTools.fncAddDataPoint(trackLoader.heartRateAt(i), trackLoader.elevationAt(i), 0);
            }

            var trackPointsTemporary = [];
            var iPausePositionsIndex = 0;


            //Go through array with track data points
            for (i=0; i<trackLength; i++)
            {
                //add this track point to temporary array. This will be used for drawing the track line
                trackPointsTemporary.push(trackLoader.trackPointAt(i));

                //Check if we have the first data point.
                if (i===0)
                {
                    //This is the first data point, draw the start icon
                    map.addSourcePoint("pointStartImage",  trackLoader.trackPointAt(i));
                    map.addImagePath("imageStartImage", Qt.resolvedUrl("../img/map_play.png"));
                    map.addLayer("layerStartLayer", {"type": "symbol", "source": "pointStartImage"});
                    map.setLayoutProperty("layerStartLayer", "icon-image", "imageStartImage");
                    map.setLayoutProperty("layerStartLayer", "icon-size", 1.0 / map.pixelRatio);
                    map.setLayoutProperty("layerStartLayer", "visibility", "visible");
                }

                //Check if we have the last data point, draw the stop icon
                if (i===(trackLength - 1))
                {
                    map.addSourcePoint("pointEndImage",  trackLoader.trackPointAt(i));
                    map.addImagePath("imageEndImage", Qt.resolvedUrl("../img/map_stop.png"));
                    map.addLayer("layerEndLayer", {"type": "symbol", "source": "pointEndImage"});
                    map.setLayoutProperty("layerEndLayer", "icon-image", "imageEndImage");
                    map.setLayoutProperty("layerEndLayer", "icon-size", 1.0 / map.pixelRatio);
                    map.setLayoutProperty("layerEndLayer", "visibility", "visible");

                    //We have to create a track line here.
                    map.addSourceLine("lineEndTrack", trackPointsTemporary)
                    map.addLayer("layerEndTrack", { "type": "line", "source": "lineEndTrack" })
                    map.setLayoutProperty("layerEndTrack", "line-join", "round");
                    map.setLayoutProperty("layerEndTrack", "line-cap", "round");
                    map.setPaintProperty("layerEndTrack", "line-color", "red");
                    map.setPaintProperty("layerEndTrack", "line-width", 2.0);

                    vTrackLinePoints = trackPointsTemporary;
                    map.fitView(trackPointsTemporary);
                }

                //now check if we have a point where a pause starts
                if (trackLoader.pausePositionsCount() > 0 && i===trackLoader.pausePositionAt(iPausePositionsIndex))
                {
                    //So this is a track point where a pause starts. The next one is the pause end!
                    //Draw the pause start icon
                    map.addSourcePoint("pointPauseStartImage" + iPausePositionsIndex.toString(),  trackLoader.trackPointAt(i));
                    map.addImagePath("imagePauseStartImage" + iPausePositionsIndex.toString(), Qt.resolvedUrl("../img/map_pause.png"));
                    map.addLayer("layerPauseStartLayer" + iPausePositionsIndex.toString(), {"type": "symbol", "source": "pointPauseStartImage" + iPausePositionsIndex.toString()});
                    map.setLayoutProperty("layerPauseStartLayer" + iPausePositionsIndex.toString(), "icon-image", "imagePauseStartImage" + iPausePositionsIndex.toString());
                    map.setLayoutProperty("layerPauseStartLayer" + iPausePositionsIndex.toString(), "icon-size", 1.0 / map.pixelRatio);
                    map.setLayoutProperty("layerPauseStartLayer" + iPausePositionsIndex.toString(), "visibility", "visible");

                    //Draw the pause end icon
                    map.addSourcePoint("pointPauseEndImage" + iPausePositionsIndex.toString(),  trackLoader.trackPointAt(i+1));
                    map.addImagePath("imagePauseEndImage" + iPausePositionsIndex.toString(), Qt.resolvedUrl("../img/map_resume.png"));
                    map.addLayer("layerPauseEndLayer" + iPausePositionsIndex.toString(), {"type": "symbol", "source": "pointPauseEndImage" + iPausePositionsIndex.toString()});
                    map.setLayoutProperty("layerPauseEndLayer" + iPausePositionsIndex.toString(), "icon-image", "imagePauseEndImage" + iPausePositionsIndex.toString());
                    map.setLayoutProperty("layerPauseEndLayer" + iPausePositionsIndex.toString(), "icon-size", 1.0 / map.pixelRatio);
                    map.setLayoutProperty("layerPauseEndLayer" + iPausePositionsIndex.toString(), "visibility", "visible");

                    //put pause items to the map
                    //trackMap.addMapItem(pauseItemStart);
                    //trackMap.addMapItem(pauseItemEnd);

                    //We can now create the track from start or end of last pause to start of this pause
                    map.addSourceLine("lineTrack" + iPausePositionsIndex.toString(), trackPointsTemporary)
                    map.addLayer("layerTrack" + iPausePositionsIndex.toString(), { "type": "line", "source": "lineTrack" + iPausePositionsIndex.toString() })
                    map.setLayoutProperty("layerTrack" + iPausePositionsIndex.toString(), "line-join", "round");
                    map.setLayoutProperty("layerTrack" + iPausePositionsIndex.toString(), "line-cap", "round");
                    map.setPaintProperty("layerTrack" + iPausePositionsIndex.toString(), "line-color", "red");
                    map.setPaintProperty("layerTrack" + iPausePositionsIndex.toString(), "line-width", 2.0);

                    //now we can delete the temp track array
                    trackPointsTemporary = [];

                    //set indexer to next pause position. But only if there is a further pause.
                    if ((iPausePositionsIndex + 1) < trackLoader.pausePositionsCount())
                        iPausePositionsIndex++;
                }
            }


            //trackMap.fitViewportToMapItems(); // Not working

            if (trackLoader.pausePositionsCount() === 0)
                pauseData.text = "-" ;
            else
                pauseData.text = trackLoader.pausePositionsCount().toString() + "/" + trackLoader.pauseDurationStr;

            console.log("onTrackChanged: " + JSTools.arrayDataPoints.length.toString());


        }
        onLoadedChanged:
        {
            gridContainer.opacity = 1.0
            map.opacity = 1.0
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
         text: "loading..."
         font.pixelSize: Theme.fontSizeMedium
    }

    BusyIndicator
    {
        visible: true
        anchors.centerIn: detailPage
        running: !trackLoader.loaded
        size: BusyIndicatorSize.Large

    }

    SilicaFlickable
    {
        id:detail_flick
        visible: true;
        anchors
        {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: map.top
        }
        clip: true
        contentHeight: header.height + gridContainer.height + Theme.paddingLarge
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

                    var dialog = pageStack.push(Qt.resolvedUrl("SportsTrackerUploadPage.qml"));//
                                            //,{"name": header.title})
                    dialog.accepted.connect(function() {
                        detail_busy.running = true;
                        detail_busy.visible = true;
                        load_text.visible = true;
                        detail_flick.visible = false;
                        map.opacity = 0.0;

                        console.log("accepted");
                        uploadToSportsTracker(dialog.sharing*1, dialog.stcomment); //TODO ENABLE ME AFTER TESTING
                    });
                    dialog.rejected.connect(function() {
                        console.log("rejected");

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
                    dialog.activityDescription = stComment;
                }

                O2 {
                    id: o2strava
                    clientId: "13707"
                    clientSecret: "6080ff1ae302088ddd3d3b0a310c722d0829fd6b"
                    scope: "write"
                    requestUrl: "https://www.strava.com/oauth/authorize"
                    tokenUrl: "https://www.strava.com/oauth/token"
                }
            }
        }

        Column
        {
            width: parent.width
            PageHeader
            {
                id: header
                title: trackLoader.name === "" ? "-" : trackLoader.name
                Behavior on opacity {
                    FadeAnimation {}
                }
            }
            Grid
            {
                id: gridContainer
                x: Theme.paddingLarge
                width: parent.width
                spacing: Theme.paddingMedium
                columns: 2
                opacity: 0.2
                Behavior on opacity
                {
                    FadeAnimation {}
                }

                Label
                {
                    id: descriptionLabel
                    width: hearRateLabel.width
                    height:descriptionData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: qsTr("Description:")
                }
                Label
                {
                    id: descriptionData
                    width: parent.width - descriptionLabel.width - 2*Theme.paddingLarge
                    text: trackLoader.description==="" ? "-" : trackLoader.description
                    wrapMode: Text.WordWrap
                }
                Label
                {
                    width: hearRateLabel.width
                    height:timeData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: qsTr("Starting time:")
                }
                Label
                {
                    id: timeData
                    width: descriptionData.width
                    text: trackLoader.timeStr
                }
                Label
                {
                    width: hearRateLabel.width
                    height:durationData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: qsTr("Duration:")
                }
                Label
                {
                    id: durationData
                    width: descriptionData.width
                    text: trackLoader.durationStr
                }
                Label
                {
                    width: hearRateLabel.width
                    height:distanceData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: qsTr("Distance:")
                }
                Label
                {
                    id: distanceData
                    width: descriptionData.width
                    text: (settings.measureSystem === 0) ? ((trackLoader.distance/1000).toFixed(2) + " km") : (JSTools.fncConvertDistanceToImperial(trackLoader.distance/1000).toFixed(2) + " mi")
                }
                Label
                {
                    width: hearRateLabel.width
                    height:speedData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    id: avgSpeedLabel
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: qsTr("Speed max/⌀:")
                }
                Label
                {
                    id: speedData
                    width: descriptionData.width
                    text: (settings.measureSystem === 0) ? (trackLoader.maxSpeed*3.6).toFixed(1) + "/" + (trackLoader.speed*3.6).toFixed(1) + " km/h" : (JSTools.fncConvertSpeedToImperial(trackLoader.maxSpeed*3.6)).toFixed(1) + "/" + (JSTools.fncConvertSpeedToImperial(trackLoader.speed*3.6)).toFixed(1) + " mi/h"
                }
                Label
                {
                    width: hearRateLabel.width
                    height:paceData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: qsTr("Pace ⌀:")
                }
                Label
                {
                    id: paceData
                    width: descriptionData.width
                    text: (settings.measureSystem === 0) ? trackLoader.paceStr + " min/km" : trackLoader.paceImperialStr + " min/mi"
                }
                Label
                {
                    id: hearRateLabel
                    height:heartRateData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: qsTr("Heart rate min/max/⌀:")
                }
                Label
                {
                    id: heartRateData
                    width: descriptionData.width
                    text: (trackLoader.heartRateMin === 9999999 && trackLoader.heartRateMax === 0) ? "-" : trackLoader.heartRateMin + "/" + trackLoader.heartRateMax + "/" + trackLoader.heartRate.toFixed(1) + " bpm"
                }
                Label
                {
                    width: hearRateLabel.width
                    id: pauseLabel
                    height:heartRateData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: qsTr("Pause number/duration:")
                }
                Label
                {
                    id: pauseData
                    width: descriptionData.width
                }
                Label
                {
                    width: hearRateLabel.width
                    id: elevationbLabel
                    height:heartRateData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: qsTr("Elevation up/down:")
                    visible: false
                }
                Label
                {
                    id: elevationData
                    width: descriptionData.width
                    text: trackLoader.elevationUp.toFixed(1) + "/" + trackLoader.elevationDown.toFixed(1)
                    visible: false
                }
            }
        }
    }
    MapboxMap
    {
        id: map

        width: parent.width
        height: bMapMaximized ? detailPage.height : detailPage.height / 3
        anchors.bottom: parent.bottom

        center: QtPositioning.coordinate(51.9854, 9.2743)
        zoomLevel: 8.0
        minimumZoomLevel: 0
        maximumZoomLevel: 20
        pixelRatio: 3.0

        accessToken: "pk.eyJ1IjoiamRyZXNjaGVyIiwiYSI6ImNqYmVta256YTJsdjUzMm1yOXU0cmxibGoifQ.JiMiONJkWdr0mVIjajIFZQ"
        cacheDatabaseMaximalSize: (settings.mapCache)*1024*1024
        cacheDatabaseDefaultPath: true

        styleUrl: settings.mapStyle

        Item
        {
            id: centerButton
            anchors.left: parent.left
            anchors.leftMargin: Theme.paddingSmall
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingSmall
            width: parent.width / 10
            height: parent.width / 10
            visible: showCenterButton
            z: 200

            MouseArea
            {
                anchors.fill: parent
                onReleased:
                {
                    console.log("centerButton pressed");
                    map.fitView(vTrackLinePoints);
                }
            }
            Image
            {
                anchors.fill: parent
                source: "../img/map_btn_center.png"
            }
        }
        Item
        {
            id: minmaxButton
            anchors.right: parent.right
            anchors.rightMargin: Theme.paddingSmall
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingSmall
            width: parent.width / 10
            height: parent.width / 10
            visible: showMinMaxButton
            z: 200

            MouseArea
            {
                anchors.fill: parent
                onReleased:
                {
                    console.log("minmaxButton pressed");
                    bMapMaximized = !bMapMaximized;
                }
            }
            Image
            {
                anchors.fill: parent
                source: (map.height === detailPage.height) ? "../img/map_btn_min.png" : "../img/map_btn_max.png"
            }
        }
        Item
        {
            id: settingsButton
            anchors.right: parent.right
            anchors.rightMargin: Theme.paddingSmall
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingSmall
            width: parent.width / 10
            height: parent.width / 10
            visible: showSettingsButton
            z: 200

            MouseArea
            {
                anchors.fill: parent
                onReleased:
                {
                    console.log("settingsButton pressed");
                    pageStack.push(Qt.resolvedUrl("MapSettingsPage.qml"));
                }
            }
            Image
            {
                anchors.fill: parent
                source: "../img/map_btn_settings.png"
            }
        }

        MapboxMapGestureArea
        {
            id: mouseArea
            map: map
            activeClickedGeo: true
            activeDoubleClickedGeo: true
            activePressAndHoldGeo: false

            onDoubleClicked:
            {
                //console.log("onDoubleClicked: " + mouse)
                map.setZoomLevel(map.zoomLevel + 1, Qt.point(mouse.x, mouse.y) );
            }
            onDoubleClickedGeo:
            {
                //console.log("onDoubleClickedGeo: " + geocoordinate);
                map.center = geocoordinate;
            }
        }
    }

    Item
    {
        id: scaleBar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingLarge
        anchors.left: parent.left
        anchors.leftMargin: Theme.paddingLarge
        height: base.height + text.height + text.anchors.bottomMargin
        opacity: 0.9
        visible: scaleWidth > 0
        z: 100

        property real   scaleWidth: 0
        property string text: ""

        Rectangle {
            id: base
            anchors.bottom: scaleBar.bottom
            color: "#98CCFD"
            height: Math.floor(Theme.pixelRatio * 3)
            width: scaleBar.scaleWidth
        }

        Rectangle {
            anchors.bottom: base.top
            anchors.left: base.left
            color: "#98CCFD"
            height: Math.floor(Theme.pixelRatio * 10)
            width: Math.floor(Theme.pixelRatio * 3)
        }

        Rectangle {
            anchors.bottom: base.top
            anchors.right: base.right
            color: "#98CCFD"
            height: Math.floor(Theme.pixelRatio * 10)
            width: Math.floor(Theme.pixelRatio * 3)
        }

        Text {
            id: text
            anchors.bottom: base.top
            anchors.bottomMargin: Math.floor(Theme.pixelRatio * 4)
            anchors.horizontalCenter: base.horizontalCenter
            color: "black"
            font.bold: true
            font.family: "sans-serif"
            font.pixelSize: Math.round(Theme.pixelRatio * 18)
            horizontalAlignment: Text.AlignHCenter
            text: scaleBar.text
        }

        function siground(x, n) {
            // Round x to n significant digits.
            var mult = Math.pow(10, n - Math.floor(Math.log(x) / Math.LN10) - 1);
            return Math.round(x * mult) / mult;
        }

        function roundedDistace(dist)
        {
            // Return dist rounded to an even amount of user-visible units,
            // but keeping the value as meters.

            if (settings.measureSystem === 0)
            {
                return siground(dist, 1);
            }
            else
            {
                return dist >= 1609.34 ?
                    siground(dist / 1609.34, 1) * 1609.34 :
                    siground(dist * 3.28084, 1) / 3.28084;
            }

            /*
            if (app.conf.get("units") === "american")
                // Round to an even amount of miles or feet.
                return dist >= 1609.34 ?
                    siground(dist / 1609.34, 1) * 1609.34 :
                    siground(dist * 3.28084, 1) / 3.28084;
            if (app.conf.get("units") === "british")
                // Round to an even amount of miles or yards.
                return dist >= 1609.34 ?
                    siground(dist / 1609.34, 1) * 1609.34 :
                    siground(dist * 1.09361, 1) / 1.09361;
            */

            // Round to an even amount of kilometers or meters.            
        }

        function update()
        {
            // Update scalebar for current zoom level and latitude.

            var meters = map.metersPerPixel * map.width / 4;
            var dist = scaleBar.roundedDistace(meters);

            scaleBar.scaleWidth = dist / map.metersPerPixel

            console.log("dist: " + dist);

            var sUnit = "m";
            var iDistance = Math.ceil(dist);
            if (dist >= 1000)
            {
                sUnit = "km";
                iDistance = dist / 1000.0;
            }

            //TODO: imperial conversion needed here!

            scaleBar.text = iDistance.toString() + " " + sUnit
        }

        Connections
        {
            target: map
            onMetersPerPixelChanged: scaleBar.update()
            onWidthChanged: scaleBar.update()
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
