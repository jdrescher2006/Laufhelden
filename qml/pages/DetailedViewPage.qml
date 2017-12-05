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
import QtLocation 5.0

import harbour.laufhelden 1.0
import "../tools/JSTools.js" as JSTools
import "../tools/SportsTracker.js" as ST
import "../tools/SharedResources.js" as SharedResources

Page
{
    id: detailPage
    allowedOrientations: Orientation.Portrait
    property string filename
    property string name
    property int stSharing: 0
    property string stComment: ""

    property int iCurrentWorkout: 0

    function setMapViewport() {
        trackMap.zoomLevel = Math.min(trackMap.maximumZoomLevel,
                                      trackLoader.fitZoomLevel(trackMap.width, trackMap.height));
        trackMap.center = trackLoader.center();
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            trackLoader.filename = filename;
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
            trackMap.opacity = 1.0
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
            var trackPoints = [];

            JSTools.arrayDataPoints = [];

            for(var i=0; i<trackLength; i++)
            {
                trackPoints.push(trackLoader.trackPointAt(i));

                JSTools.fncAddDataPoint(trackLoader.heartRateAt(i), trackLoader.elevationAt(i), 0);
            }           

            var trackPointsTemporary = [];

            var iPausePositionsIndex = 0;

            //Go through JS array with track data points
            for (i=0; i<trackLength; i++)
            {
                //add this track point to temporary array. This will be used for drawing the track line
                trackPointsTemporary.push(trackLoader.trackPointAt(i));

                //Check if we have the first data point.
                if (i===0)
                {
                    //This is the first data point, draw the start icon
                    idItemTrackStart.coordinate = trackLoader.trackPointAt(i);
                    idItemTrackStart.visible = true;
                }

                //Check if we have the last data point, draw the stop icon
                if (i===(trackLength - 1))
                {
                    idItemTrackEnd.coordinate = trackLoader.trackPointAt(i);
                    idItemTrackEnd.visible = true;                    

                    //We have to create a track line here. Either it comes from a pause end or from start of track
                    var componentTrack = Qt.createComponent("../tools/MapPolyLine.qml");
                    var track = componentTrack.createObject(trackMap);
                    track.path = trackPointsTemporary;
                    //Add track to map
                    trackMap.addMapItem(track);
                }                

                //now check if we have a point where a pause starts
                if (trackLoader.pausePositionsCount() > 0 && i===trackLoader.pausePositionAt(iPausePositionsIndex))
                {
                    //So this is a track point where a pause starts. The next one is the pause end!
                    //Draw the pause start icon
                    var componentStart = Qt.createComponent("../tools/MapPauseItem.qml");
                    var pauseItemStart = componentStart.createObject(trackMap);
                    pauseItemStart.coordinate = trackLoader.trackPointAt(i);
                    pauseItemStart.iSize = (detailPage.orientation == Orientation.Portrait || detailPage.orientation == Orientation.PortraitInverted) ? detailPage.width / 14 : detailPage.height / 14
                    pauseItemStart.bPauseStart = true;
                    //Draw the pause end icon
                    var componentEnd = Qt.createComponent("../tools/MapPauseItem.qml");
                    var pauseItemEnd = componentEnd.createObject(trackMap);
                    pauseItemEnd.coordinate = trackLoader.trackPointAt(i+1);
                    pauseItemEnd.iSize = (detailPage.orientation == Orientation.Portrait || detailPage.orientation == Orientation.PortraitInverted) ? detailPage.width / 14 : detailPage.height / 14
                    pauseItemEnd.bPauseStart = false;

                    //put pause items to the map
                    trackMap.addMapItem(pauseItemStart);
                    trackMap.addMapItem(pauseItemEnd);

                    //We can now create the track from start or end of last pause to start of this pause
                    var componentPauseTrack = Qt.createComponent("../tools/MapPolyLine.qml");
                    var pauseTrack = componentPauseTrack.createObject(trackMap);
                    pauseTrack.path = trackPointsTemporary;
                    //Add track to map
                    trackMap.addMapItem(pauseTrack);


                    //now we can delete the temp track array
                    trackPointsTemporary = [];

                    //set indexer to next pause position. Bu only if there is a further pause.
                    if ((iPausePositionsIndex + 1) < trackLoader.pausePositionsCount())
                        iPausePositionsIndex++;
                }
            }

            //trackMap.fitViewportToMapItems(); // Not working
            setMapViewport(); // Workaround for above

            if (trackLoader.pausePositionsCount() === 0)
                pauseData.text = "-" ;
            else
                pauseData.text = trackLoader.pausePositionsCount().toString() + "/" + trackLoader.pauseDurationStr;

            console.log("onTrackChanged: " + JSTools.arrayDataPoints.length.toString());
        }
        onLoadedChanged:
        {
            gridContainer.opacity = 1.0
            trackMap.opacity = 1.0
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
            bottom: trackMap.top
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
                        trackMap.opacity = 0.0;

                        console.log("accepted");
                        uploadToSportsTracker(dialog.sharing*1, dialog.stcomment); //TODO ENABLE ME AFTER TESTING
                    });
                    dialog.rejected.connect(function() {
                        console.log("rejected");

                    });

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
                    text: (trackLoader.distance/1000).toFixed(2) + " km"
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
                    text: (trackLoader.maxSpeed*3.6).toFixed(1) + "/" + (trackLoader.speed*3.6).toFixed(1) + " km/h"
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
                    text: trackLoader.paceStr + " min/km"
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
            }
        }
    }
    Map {
        id: trackMap
        width: parent.width
        height: trackMap.gesture.enabled ? detailPage.height : trackMap.width*3/4;
        anchors.bottom: parent.bottom
        clip: true
        gesture.enabled: false
        plugin: Plugin {
            name: "osm"
            PluginParameter
            {
                name: "useragent"                
                value: "Laufhelden(SailfishOS)"
            }
            //PluginParameter { name: "osm.mapping.host"; value: "http://localhost:8553/v1/tile/" }
        }
        // Following definition of map center does not work without QtPositioning!?
        center {
            latitude: 0
            longitude: 0
        }
        zoomLevel: minimumZoomLevel
        onHeightChanged: setMapViewport()
        onWidthChanged: setMapViewport()
        opacity: 0.1
        Behavior on height {
            NumberAnimation { duration: 200 }
        }
        Behavior on opacity {
            FadeAnimation {}
        }
        Behavior on zoomLevel {
            NumberAnimation { duration: 200 }
        }
        Behavior on center.latitude {
            NumberAnimation { duration: 200 }
        }
        Behavior on center.longitude {
            NumberAnimation { duration: 200 }
        }

        MapQuickItem {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            sourceItem: Rectangle {
                color: "white"
                opacity: 0.6
                width: contributionLabel.width
                height: contributionLabel.height
                    Label {
                        id: contributionLabel
                        font.pixelSize: Theme.fontSizeTiny
                        color: "black"
                        text: "(C) OpenStreetMap contributors"
                }
            }
        }
        MapQuickItem
        {
            id: idItemTrackStart
            anchorPoint.x: sourceItem.width/2
            anchorPoint.y: sourceItem.height/2
            visible: false
            z: 1    //this means that pause icons are placed on top
            sourceItem: Item
            {
                height: (detailPage.orientation == Orientation.Portrait || detailPage.orientation == Orientation.PortraitInverted) ? detailPage.width / 14 : detailPage.height / 14
                width: (detailPage.orientation == Orientation.Portrait || detailPage.orientation == Orientation.PortraitInverted) ? detailPage.width / 14 : detailPage.height / 14
                Image
                {
                    width: parent.width
                    height: parent.height
                    source: "../img/map_play.png"
                }
            }
        }
        MapQuickItem
        {
            id: idItemTrackEnd
            anchorPoint.x: sourceItem.width/2
            anchorPoint.y: sourceItem.height/2
            visible: false
            z: 1    //this means that pause icons are placed on top
            sourceItem: Item
            {
                height: (detailPage.orientation == Orientation.Portrait || detailPage.orientation == Orientation.PortraitInverted) ? detailPage.width / 14 : detailPage.height / 14
                width: (detailPage.orientation == Orientation.Portrait || detailPage.orientation == Orientation.PortraitInverted) ? detailPage.width / 14 : detailPage.height / 14
                Image
                {
                    width: parent.width
                    height: parent.height
                    source: "../img/map_stop.png"
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                trackMap.gesture.enabled = !trackMap.gesture.enabled;
                if(trackMap.gesture.enabled) {
                    gridContainer.opacity = 0.0;
                    header.opacity = 0.0;
                    //detailPage.allowedOrientations = Orientation.All;
                } else {
                    gridContainer.opacity = 1.0;
                    header.opacity = 1.0;
                    //detailPage.allowedOrientations = Orientation.Portrait;
                }
                detailPage.backNavigation = !trackMap.gesture.enabled;
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
