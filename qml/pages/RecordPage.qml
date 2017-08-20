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
import "../tools"

Page
{
    id: page

    allowedOrientations: settings.recordPagePortrait ? Orientation.Portrait : Orientation.All;

    //If not tracking and we have no data, going back is possible
    backNavigation: (!recorder.tracking && recorder.isEmpty)

    property bool bShowMap: settings.showMapRecordPage

    property int iLastHeartRateArea: -1
    property int iHRAboveTopCounter: 0
    property int iHRBelowTopCounter: 0
    property int iHRAboveBottomCounter: 0
    property int iHRBelowBottomCounter: 0

    property int iLastPaceArea: -1
    property int iPaceAboveTopCounter: 0
    property int iPaceBelowTopCounter: 0
    property int iPaceAboveBottomCounter: 0
    property int iPaceBelowBottomCounter: 0    

    property bool bLockFirstPageLoad: true
    property int iButtonLoop : 3
    property bool bEndLoop: false;

    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockFirstPageLoad = false;
            console.log("First Active RecordPage");

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

            //Connect to HRM device if we have a BT address and HRM device should be used
             if (sHRMAddress !== "" && settings.useHRMdevice)
             {
                 id_BluetoothData.connect(sHRMAddress, 1);
             }

             bRecordDialogRequestHRM = true;
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("RecordPage active");
            console.log("vMainPageObject: " + vMainPageObject.toString());

            //If this page is shown, prevent screen from going blank
            if (settings.disableScreenBlanking)
                fncEnableScreenBlank(true);
        }

        if (status === PageStatus.Inactive)
        {            
            console.log("RecordPage inactive");            

            if (settings.disableScreenBlanking)
                fncEnableScreenBlank(false);                    
        }
    }

    Timer
    {
        id: idTimerButtonLoop
        interval: 1000;
        repeat: (iButtonLoop<3 && iButtonLoop>0)
        running: (iButtonLoop<3 && iButtonLoop>0)
        onTriggered:
        {
            //Cancel end operation
            if (bEndLoop)
            {
                iButtonLoop = 3;
                return;
            }

            iButtonLoop-=1;

            if (iButtonLoop===0)
            {
                iButtonLoop = 3;

                bRecordDialogRequestHRM = false;

                if (bHRMConnected) {id_BluetoothData.disconnect();}

                sHeartRate: ""
                sBatteryLevel: ""

                recorder.tracking = false;
                if(!recorder.isEmpty)
                {
                    showSaveDialog();
                }
            }
        }
    }   

    function showSaveDialog()
    {
        var dialog = pageStack.push(Qt.resolvedUrl("SaveDialog.qml"));
        dialog.accepted.connect(function()
        {
            console.log("Saving workout");
            recorder.exportGpx(dialog.name, dialog.description);
            recorder.clearTrack();  // TODO: Make sure save was successful?
            trackLine.path = [];

            //Mainpage must load history data to get this new workout in the list
            bLoadHistoryData = true;

            //We must return here to the mainpage.            
            pageStack.pop(vMainPageObject, PageStackAction.Immediate);
        })
        dialog.rejected.connect(function()
        {
            console.log("Cancel workout");
            recorder.clearTrack();
            trackLine.path = [];

            //We must return here to the mainpage.
            pageStack.pop(vMainPageObject, PageStackAction.Immediate);
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

    function setMapViewport()
    {
        if(recorder.accuracy < 0 && recorder.points < 1)
        {
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
        //console.log("Position: " + recorder.currentPosition);
        console.log("newTrackPoint");

        trackLine.addCoordinate(coordinate);
        if(!map.gesture.enabled)
        {
            // Set viewport only when not browsing
            setMapViewport();
        }

        fncHRThreshold();

        fncPaceThreshold();
    }    

    function fncHRThreshold()
    {
        //Now process the thresholds. Make some checks.
        if (sHeartRate === "" || sHeartRate === "-1")
        {
            return;
        }
        //Parse pulse value to int
        var iHeartrate = parseInt(sHeartRate);

        //Extract heart rate thresholds from string
        //[0] bottom threshold
        //[1] top threshold
        //[2] bottom threshold trigger counter
        //[3] top threshold trigger counter
        var iHeartrateThresholds = settings.pulseThreshold.toString().split(",");

        if (iHeartrateThresholds.length !== 4)
            return;

        //parse thresholds to int
        iHeartrateThresholds[0] = parseInt(iHeartrateThresholds[0]);
        iHeartrateThresholds[1] = parseInt(iHeartrateThresholds[1]);
        iHeartrateThresholds[2] = parseInt(iHeartrateThresholds[2]);
        iHeartrateThresholds[3] = parseInt(iHeartrateThresholds[3]);

        //Heart rate areas:
        //-1 not defined, start value
        // 0 below lower threshold
        // 1 between lower and upper threshold (good area)
        // 2 above upper threshold

        console.log("pulseThresholdUpperEnable: " + settings.pulseThresholdUpperEnable.toString());
        console.log("iLastHeartRateArea: " + iLastHeartRateArea.toString());
        console.log("iHRAboveTopCounter: " + iHRAboveTopCounter.toString());
        console.log("iHeartrateThresholds[1]: " + iHeartrateThresholds[1].toString());

        if (settings.pulseThresholdUpperEnable)
        {
            //First condition: detect a break from below through the upper threshold
            if (iLastHeartRateArea != 2 && iHeartrate >= iHeartrateThresholds[1])
            {
                //Ok the threshold was triggered. Check how often in a row that was the case.
                if (iHRAboveTopCounter >= iHeartrateThresholds[3])
                {
                    iHRAboveTopCounter = 0;
                    iLastHeartRateArea = 2;                    

                    fncPlaySound("audio/hr_toohigh.wav");
                }
                else
                    iHRAboveTopCounter+=1;
            }
            //Second condition: detect a break from above through the upper threshold
            else if(iLastHeartRateArea == 2 && iHeartrate < iHeartrateThresholds[1])
            {
                //Ok the threshold was triggered. Check how often in a row that was the case.
                if (iHRBelowTopCounter >= iHeartrateThresholds[3])
                {
                    iHRBelowTopCounter = 0;
                    iLastHeartRateArea = 1;                    

                    fncPlaySound("audio/hr_normal.wav");
                }
                else
                    iHRBelowTopCounter+=1;
            }
            else
            {
                //OK, the threshold was not triggered. Reset the trigger counters.
                iHRAboveTopCounter = 0;
                iHRBelowTopCounter = 0;
            }
        }

        if (settings.pulseThresholdBottomEnable)
        {
            //First condition: detect a break from above through the bottom threshold
            if (iLastHeartRateArea != 0 && iHeartrate <= iHeartrateThresholds[0])
            {
                //Ok the threshold was triggered. Check how often in a row that was the case.
                if (iHRBelowBottomCounter >= iHeartrateThresholds[2])
                {
                    iHRBelowBottomCounter = 0;
                    iLastHeartRateArea = 0;

                    fncPlaySound("audio/hr_toolow.wav");
                }
                else
                    iHRBelowBottomCounter+=1;
            }
            //Second condition: detect a break from below through the bottom threshold
            else if(iLastHeartRateArea == 0 && iHeartrate > iHeartrateThresholds[0])
            {
                //Ok the threshold was triggered. Check how often in a row that was the case.
                if (iHRAboveBottomCounter >= iHeartrateThresholds[2])
                {
                    iHRAboveBottomCounter = 0;
                    iLastHeartRateArea = 1;

                    fncPlaySound("audio/hr_normal.wav");
                }
                else
                    iHRAboveBottomCounter+=1;
            }
            else
            {
                //OK, the threshold was not triggered. Reset the trigger counters.
                iHRAboveBottomCounter = 0;
                iHRBelowBottomCounter = 0;
            }
        }
    }

    function fncPaceThreshold()
    {                      
        //Extract pace thresholds from string
        //[0] bottom threshold
        //[1] top threshold
        //[2] bottom threshold trigger counter
        //[3] top threshold trigger counter
        var fPaceThresholds = settings.paceThreshold.toString().split(",");

        if (fPaceThresholds.length !== 4)
            return;

        //parse thresholds to float
        fPaceThresholds[0] = parseFloat(fPaceThresholds[0]);
        fPaceThresholds[1] = parseFloat(fPaceThresholds[1]);
        fPaceThresholds[2] = parseFloat(fPaceThresholds[2]);
        fPaceThresholds[3] = parseFloat(fPaceThresholds[3]);

        //Pace areas:
        //-1 not defined, start value
        // 0 below lower threshold
        // 1 between lower and upper threshold (good area)
        // 2 above upper threshold

        if (settings.paceThresholdUpperEnable)      //Speed is too slow
        {
            //First condition: detect a break from below through the upper threshold
            if (iLastPaceArea != 2 && recorder.pace.toFixed(1) >= fPaceThresholds[1])
            {
                //Ok the threshold was triggered. Check how often in a row that was the case.
                if (iPaceAboveTopCounter >= fPaceThresholds[3])
                {
                    iPaceAboveTopCounter = 0;
                    iLastPaceArea = 2;                    

                    fncPlaySound("audio/pace_toolow.wav");

                    fncVibrate(3, 500);
                }
                else
                    iPaceAboveTopCounter+=1;
            }
            //Second condition: detect a break from above through the upper threshold
            else if(iLastPaceArea == 2 && recorder.pace.toFixed(1) < fPaceThresholds[1])
            {
                //Ok the threshold was triggered. Check how often in a row that was the case.
                if (iPaceBelowTopCounter >= fPaceThresholds[3])
                {
                    iPaceBelowTopCounter = 0;
                    iLastPaceArea = 1;                 

                    fncPlaySound("audio/pace_normal.wav");
                }
                else
                    iPaceBelowTopCounter+=1;
            }
            else
            {
                //OK, the threshold was not triggered. Reset the trigger counters.
                iPaceAboveTopCounter = 0;
                iPaceBelowTopCounter = 0;
            }
        }

        if (settings.pulseThresholdBottomEnable)    //Speed is too fast
        {
            //First condition: detect a break from above through the bottom threshold
            if (iLastPaceArea != 0 && recorder.pace.toFixed(1) <= fPaceThresholds[0])
            {
                //Ok the threshold was triggered. Check how often in a row that was the case.
                if (iPaceBelowBottomCounter >= fPaceThresholds[2])
                {
                    iPaceBelowBottomCounter = 0;
                    iLastPaceArea = 0;

                    fncPlaySound("audio/pace_toohigh.wav");

                    fncVibrate(3, 200);
                }
                else
                    iPaceBelowBottomCounter+=1;
            }
            //Second condition: detect a break from below through the bottom threshold
            else if(iLastPaceArea == 0 && recorder.pace.toFixed(1) > fPaceThresholds[0])
            {
                //Ok the threshold was triggered. Check how often in a row that was the case.
                if (iPaceAboveBottomCounter >= fPaceThresholds[2])
                {
                    iPaceAboveBottomCounter = 0;
                    iLastPaceArea = 1;

                    fncPlaySound("audio/pace_normal.wav");
                }
                else
                    iPaceAboveBottomCounter+=1;
            }
            else
            {
                //OK, the threshold was not triggered. Reset the trigger counters.
                iPaceAboveBottomCounter = 0;
                iPaceBelowBottomCounter = 0;
            }
        }


    }

    MapCircle
    {
        id: positionMarker
        center: recorder.currentPosition
        radius: recorder.accuracy
        color: "blue"
        border.color: "white"
        border.width: 6
        opacity: 0.3
        /* this stuff comes from Rena but was not working there either
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
        Behavior on radius
        {
            NumberAnimation { duration: 200 }
        }
        Behavior on center.latitude
        {
            NumberAnimation { duration: 200 }
        }
        Behavior on center.longitude
        {
            NumberAnimation { duration: 200 }
        }*/
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

            MenuItem
            {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }           
        }
        PushUpMenu
        {
            id: menuUP            

            MenuItem
            {
                text: bShowMap ? qsTr("Hide Map") : qsTr("Show Map")
                onClicked:
                {
                    bShowMap = !bShowMap;
                    settings.showMapRecordPage = bShowMap;
                }
            }
            MenuItem
            {
                text: qsTr("Disconnect HRM")
                visible: (sHRMAddress !== "" && settings.useHRMdevice)
                onClicked:
                {
                    bRecordDialogRequestHRM = false;
                    id_BluetoothData.disconnect();
                }
            }
            MenuItem
            {
                text: qsTr("Reconnect HRM")
                visible: (sHRMAddress !== "" && settings.useHRMdevice)
                onClicked:
                {
                    id_BluetoothData.connect(sHRMAddress, 1);
                    bRecordDialogRequestHRM = true;
                }
            }
            MenuItem
            {
                text: "Test"
                onClicked:
                {
                    fncPlaySound("audio/pace_normal.wav");

                    fncVibrate(1, 100);
                }
            }
        }

        contentHeight: column.height + Theme.paddingLarge

        Rectangle
        {
            visible: iButtonLoop < 3
            z: 2
            color: "steelblue"
            width: parent.width
            height: parent.height/3
            anchors.centerIn: parent
            Label
            {
                color: "white"
                text: qsTr("hold button for: ") + iButtonLoop.toString() + "s";
                font.pixelSize: Theme.fontSizeMedium
                anchors.centerIn: parent
            }
        }

        Column
        {
            id: column
            width: page.width
            spacing: Theme.paddingLarge

            Row
            {
                anchors.right: parent.right
                GlassItem
                {
                    anchors.verticalCenter: parent.verticalCenter
                    color: recorder.tracking ? "red" : (recorder.isEmpty ? "green" : "orange")
                    falloffRadius: 0.15
                    radius: 1.0
                    cache: false
                }
                Label
                {
                    anchors.verticalCenter: parent.verticalCenter
                    id: stateLabel
                    text: recorder.tracking ? qsTr("Recording") : (recorder.isEmpty ? qsTr("Stopped") : qsTr("Paused"))
                    font.pixelSize: Theme.fontSizeLarge
                }
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
                text: recorder.accuracy < 0 ? qsTr("No position") :
                                              (recorder.accuracy < 30
                                               ? qsTr("Accuracy: ") + recorder.accuracy.toFixed(1) + "m"
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
                id: avgspeedLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: recorder.speedaverage.toFixed(1) + "⌀ km/h / " + recorder.paceaverage.toFixed(1) + "⌀ min/km"
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
            Row
            {
                id: row
                width: parent.width
                spacing: Theme.paddingMedium
                Rectangle
                {

                    width: ((parent.width/2) - (Theme.paddingMedium/2))
                    height: parent.width/8
                    color: recorder.isEmpty ? "dimgrey" : "lightsalmon"
                    border.color: recorder.isEmpty ? "grey" : "white"
                    border.width: 2
                    radius: 10
                    Image
                    {
                        height: parent.height
                        anchors.left: parent.left
                        fillMode: Image.PreserveAspectFit
                        source: recorder.tracking ? "image://theme/icon-l-pause" : "image://theme/icon-l-play"
                    }
                    Label
                    {
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.paddingMedium
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.fontSizeLarge
                        color: recorder.isEmpty ? "grey" : "white"
                        text: recorder.tracking ? qsTr("Pause") : qsTr("Continue")
                    }
                    MouseArea
                    {
                        anchors.fill: parent
                        enabled: !recorder.isEmpty //pause or continue only if workout was really started
                        onClicked:
                        {
                            recorder.tracking = !recorder.tracking;
                        }
                    }
                }
                Rectangle
                {
                    width: ((parent.width/2) - (Theme.paddingMedium/2))
                    height: parent.width/8
                    //color: !recorder.tracking && recorder.isEmpty ? "#389632" : "salmon"
                    color: (recorder.isEmpty && recorder.accuracy >= 30) ? "dimgrey" : (!recorder.tracking && recorder.isEmpty ? "#389632" : "salmon")
                    border.color: (recorder.isEmpty && recorder.accuracy >= 30) ? "grey" : "white"
                    border.width: 2
                    radius: 10
                    Image
                    {
                        height: parent.height
                        anchors.left: parent.left
                        fillMode: Image.PreserveAspectFit
                        source: !recorder.tracking && recorder.isEmpty ? "image://theme/icon-l-add" :  "image://theme/icon-l-clear"
                    }
                    Label
                    {
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.paddingMedium
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.fontSizeLarge
                        color: (recorder.isEmpty && recorder.accuracy >= 30) ? "grey" : "white"
                        text: !recorder.tracking && recorder.isEmpty ? qsTr("Start") : qsTr("End")
                    }
                    MouseArea
                    {
                        anchors.fill: parent
                        onPressed:
                        {
                            if (!recorder.tracking && recorder.isEmpty)
                            {
                                //Check accuracy
                                if (recorder.accuracy < 30)
                                {
                                    //Start workout
                                    recorder.tracking = true;
                                }
                            }
                            else
                            {
                                bEndLoop = false;
                                iButtonLoop = 2;
                            }
                        }
                        onReleased:
                        {
                            bEndLoop = true;
                        }
                    }
                }
            }
        }      
    }
    Map {
        id: map
        width: parent.width
        height: map.gesture.enabled
                ? (page.height - stateLabel.height -2*Theme.paddingLarge)
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
                value: "Laufhelden(SailfishOS)"
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
                //page.forwardNavigation = !map.gesture.enabled;
                flickable.interactive = !map.gesture.enabled;
                menu.visible = !map.gesture.enabled;
            }
        }
    }
}
