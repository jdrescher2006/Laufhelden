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
import QtPositioning 5.0
import QtMultimedia 5.0 as Media
import "../tools"

Page {
    id: page

    allowedOrientations: settings.recordPagePortrait ? Orientation.Portrait : Orientation.All;

    property bool bRecordPage: true
    property bool bShowMap: settings.showMapRecordPage
    property int iLastHeartRate: -1

    onStatusChanged:
    {
        //console.log("onStatusChanged record page: " + status.toString());

        if (status === PageStatus.Active && bRecordPage)
        {
            bRecordPage = false;

            //If this page is shown, prevent screen from going blank
            if (settings.disableScreenBlanking)
                fncEnableScreenBlank(true);

           //Connect to HRM device if we have a BT address and HRM device should be used
            if (sHRMAddress !== "" && settings.useHRMdevice)
            {              
                id_BluetoothData.connect(sHRMAddress, 1);
            }

            bRecordDialogRequestHRM = true;            
        }
        if (status === PageStatus.Inactive)
        {            
            bRecordDialogRequestHRM = false;

            if (settings.disableScreenBlanking)
                fncEnableScreenBlank(false);

            if (bHRMConnected) {id_BluetoothData.disconnect();}

            sHeartRate: ""
            sBatteryLevel: ""
        }
    }

    function showSaveDialog()
    {
        var dialog = pageStack.push(Qt.resolvedUrl("SaveDialog.qml"));
        dialog.accepted.connect(function()
        {
            console.log("Saving track");
            recorder.exportGpx(dialog.name, dialog.description);
            recorder.clearTrack();  // TODO: Make sure save was successful?
            trackLine.path = [];
        })
    }

    function showClearConfirmation() {
        var dialog = pageStack.push(Qt.resolvedUrl("ConfirmClearDialog.qml"));
        dialog.accepted.connect(function() {
            console.log("Starting new tracking");
            recorder.clearTrack();
            trackLine.path = [];
            recorder.tracking = true;
        })
    }

    function setMapViewport() {
        if(recorder.accuracy < 0 && recorder.points < 1) {
            return;
        }

        var accuracyZoom;
        if(recorder.accuracy > 0) {
            var windowPixels;
            if(map.width < map.height) {
                windowPixels = map.width;
            } else {
                windowPixels = map.height;
            }
            var latCor = Math.cos(recorder.currentPosition.latitude*Math.PI/180);
            // Earth equator length in WGS-84: 40075.016686 km
            // Tile size: 256 pixels
            var innerFunction = windowPixels/256.0 * 40075016.686/(2*recorder.accuracy) * latCor
            // 2 base logarithm is ln(x)/ln(2)
            accuracyZoom = Math.min(map.maximumZoomLevel, Math.floor(Math.log(innerFunction) / Math.log(2)));
        } else {
            accuracyZoom = map.maximumZoomLevel;
        }

        var trackZoom = Math.min(map.maximumZoomLevel, recorder.fitZoomLevel(map.width, map.height));

        if(accuracyZoom <= trackZoom && recorder.accuracy > 0) {
            map.zoomLevel = accuracyZoom;
        } else {
            map.zoomLevel = trackZoom;
        }
        if(recorder.isEmpty) {
            map.center = recorder.currentPosition;
        } else {
            map.center = recorder.trackCenter();
        }
    }

    function newTrackPoint(coordinate)
    {
        trackLine.addCoordinate(coordinate);
        if(!map.gesture.enabled)
        {
            // Set viewport only when not browsing
            setMapViewport();
        }

        //Check if we triggered a threshold
        if (settings.pulseThresholdEnable && sHeartRate != "" && sHeartRate != -1)
        {
            //Parse pulse value to int
            var iHeartrate = parseInt(sHeartRate);

            var iHeartrateThresholds = settings.pulseThreshold.toString().split(",");

            if (iHeartrate === NaN || iHeartrateThresholds.length !== 4)
                return;

            //These are the thresholds:
            // [0] bottom threshold
            // [1] bottom hysteresis
            // [2] top threshold
            // [3] top hysteresis

            //These are the areas:
            //-1 start value undefined
            // 0 under bottom threshold
            // 1 inbetween thresholds
            // 2 over top threshod


            //This is first start condition.
            if (iLastHeartRate === -1)
            {
                iLastHeartRate = iHeartrate;
                return;
            }

            //Check if we are over the upper threshold and was not there the last time.
            if (iLastHeartRate < iHeartrateThresholds[2] && iHeartrate >= iHeartrateThresholds[2])
            {
                //Now we need to alert that we are over the top threshold

            }

            //Check if we are under the upper threshold

            //Check if we are over the under threshold

            //Check if we are under the under threshold


            //playSoundEffect.source = "../audio/catch-action.wav";
            //playSoundEffect.play();
        }
    }

    Component.onCompleted:
    {
        recorder.newTrackPoint.connect(newTrackPoint);
        map.addMapItem(positionMarker);
        console.log("RecordPage: Plotting track line");
        for(var i=0;i<recorder.points;i++) {
            trackLine.addCoordinate(recorder.trackPointAt(i));
        }
        console.log("RecordPage: Appending track line to map");
        map.addMapItem(trackLine);
        console.log("RecordPage: Setting map viewport");
        setMapViewport();
    }

    Media.SoundEffect
    {
        id: playSoundEffect
        source: "../audio/catch-action.wav"
        volume: 1.0; //Full 1.0
    }

    MapCircle
    {
        id: positionMarker
        center: recorder.currentPosition
        //radius: recorder.accuracy
        radius: 1000
        color: "blue"
        border.color: "blue"
        //opacity: 0.3
        opacity: 1.0
        onRadiusChanged: {
            if(!map.gesture.enabled) {  // When not browsing the map
                setMapViewport()
            }
        }
        onCenterChanged: {
            if(!map.gesture.enabled) {  // When not browsing the map
                setMapViewport()
            }
        }
        Behavior on radius {
            NumberAnimation { duration: 200 }
        }
        Behavior on center.latitude {
            NumberAnimation { duration: 200 }
        }
        Behavior on center.longitude {
            NumberAnimation { duration: 200 }
        }
    }

    MapPolyline {
        id: trackLine
        visible: path.length > 1
        line.color: "red"
        line.width: 5
        smooth: true
    }

    SilicaFlickable {
        id: flickable
        anchors.top: page.top
        anchors.bottom: bShowMap ? map.top : page.bottom
        anchors.left: page.left
        anchors.right: page.right

        PullDownMenu
        {
            id: menu

            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: qsTr("Start workout!")
                visible: !recorder.tracking
                onClicked: {
                    if(!recorder.isEmpty) {
                        showClearConfirmation();
                    } else {
                        recorder.tracking = true;
                    }
                }
            }
            MenuItem {
                text: qsTr("Continue recording")
                visible: !recorder.tracking && !recorder.isEmpty
                onClicked: recorder.tracking = true
            }
            MenuItem {
                text: qsTr("Save track")
                visible: !recorder.tracking && !recorder.isEmpty
                onClicked: showSaveDialog()
            }
            MenuItem {
                text: qsTr("Stop recording")
                visible: recorder.tracking
                onClicked: {
                    recorder.tracking = false;
                    if(!recorder.isEmpty) {
                        showSaveDialog();
                    }
                }
            }
        }
        PushUpMenu
        {
            id: menuUP


            MenuItem
            {
                text: recorder.tracking ? qsTr("Pause workout") : qsTr("Continue workout")
                onClicked:
                {
                    recorder.tracking = !recorder.tracking;
                }
            }
            MenuItem
            {
                text: qsTr("Disconnect HRM")
                onClicked:
                {
                    bRecordDialogRequestHRM = false;
                    id_BluetoothData.disconnect();
                }
            }
            MenuItem
            {
                text: qsTr("Reconnect HRM")
                onClicked:
                {
                     id_BluetoothData.connect(sHRMAddress, 1);
                    bRecordDialogRequestHRM = true;
                }
            }
            MenuItem
            {
                text: bShowMap ? qsTr("Hide Map") : qsTr("Show Map")
                onClicked:
                {
                    bShowMap = !bShowMap;
                    settings.showMapRecordPage = bShowMap;
                }
            }
        }

        contentHeight: column.height

        Column
        {
            id: column
            width: page.width
            spacing: Theme.paddingLarge
            PageHeader
            {
                id: header
                title: "Laufhelden"
            }
            Label
            {
                id: stateLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: recorder.tracking ?
                          settings.updateInterval===1000 ? qsTr("Recording")
                                                         : qsTr("Recording - ")
                                                           + settings.updateInterval/1000
                                                           + " s interval"
                        : qsTr("Stopped")
                font.pixelSize: Theme.fontSizeLarge
            }
            Label
            {
                id: distanceLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: (recorder.distance/1000).toFixed(1) + " km"
                font.pixelSize: Theme.fontSizeLarge
                Behavior on opacity {
                    FadeAnimation {}
                }
            }
            Label
            {
                id: timeLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: recorder.time
                font.pixelSize: Theme.fontSizeLarge
                Behavior on opacity {
                    FadeAnimation {}
                }
            }
            Label
            {
                id: accuracyLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: recorder.accuracy < 0 ? "No position" :
                                              (recorder.accuracy < 30
                                               ? sHeartRate + recorder.accuracy.toFixed(1) + "m"
                                               : qsTr("Accuracy too low: ") + recorder.accuracy.toFixed(1) + "m")
                Behavior on opacity {
                    FadeAnimation {}
                }
            }
            Label
            {
                id: speedLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: recorder.speed.toFixed(1) + "km/h / " + recorder.pace.toFixed(1) + "min/km"
                font.pixelSize: Theme.fontSizeLarge
                Behavior on opacity {
                    FadeAnimation {}
                }
            }
            Label
            {
                id: heartrateLabel
                anchors.horizontalCenter: parent.horizontalCenter                
                visible: sHRMAddress !== "" && settings.useHRMdevice
                text: sHeartRate + qsTr(" bpm, ") + sBatteryLevel + " %, Conn: " + bHRMConnected.toString();
                Behavior on opacity
                {
                    FadeAnimation {}
                }
            }
        }
    }
    Map {
        id: map
        width: parent.width
        height: map.gesture.enabled
                ? (page.height - header.height - stateLabel.height -2*Theme.paddingLarge)
                : width * 3/4
                  //: (page.height - header.height - stateLabel.height - distanceLabel.height - timeLabel.height - accuracyLabel.height - 5*Theme.paddingLarge)
        anchors.bottom: parent.bottom
        clip: true
        gesture.enabled: false
        visible: bShowMap
        plugin: Plugin
        {
            name: "osm"
            PluginParameter
            {
                name: "useragent"                
                value: "Laufhelden/0.0.1 (SailfishOS)"
            }
            //PluginParameter { name: "osm.mapping.host"; value: "http://localhost:8553/v1/tile/" }
        }
        center {
            latitude: 0.0
            longitude: 0.0
        }
        zoomLevel: minimumZoomLevel
        onHeightChanged: setMapViewport()
        onWidthChanged: setMapViewport()
        Behavior on height {
            NumberAnimation { duration: 200 }
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
        MouseArea {
            anchors.fill: parent
            onClicked: {
                map.gesture.enabled = !map.gesture.enabled;
                if(map.gesture.enabled) {
                    distanceLabel.opacity = 0.0;
                    timeLabel.opacity = 0.0;
                    accuracyLabel.opacity = 0.0;
                    //page.allowedOrientations = Orientation.All;
                } else {
                    distanceLabel.opacity = 1.0;
                    timeLabel.opacity = 1.0;
                    accuracyLabel.opacity = 1.0;
                    //page.allowedOrientations = Orientation.All;
                }
                page.forwardNavigation = !map.gesture.enabled;
                flickable.interactive = !map.gesture.enabled;
                menu.visible = !map.gesture.enabled;
            }
        }
    }
}
