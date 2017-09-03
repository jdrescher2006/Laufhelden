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
import "SharedResources.js" as SharedResources
import "../tools/Thresholds.js" as Thresholds

Page
{
    id: page

    allowedOrientations: settings.recordPagePortrait ? Orientation.Portrait : Orientation.All;

    //If not tracking and we have no data, going back is possible
    backNavigation: (!recorder.tracking && recorder.isEmpty)

    property bool bShowMap: settings.showMapRecordPage  

    property bool bLockFirstPageLoad: true
    property int iButtonLoop : 3
    property bool bEndLoop: false;

    property int iDisplayMode: 0
    property color cBackColor: "black"
    property color cPrimaryTextColor: "white"
    property color cSecondaryTextColor: "white"
    property color cBorderColor: "steelblue"
    property int iBorderWidth: height / 400
    property int iSecondaryTextHeightFactor: 4

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

            //If this page is shown, prevent screen from going blank
            if (settings.disableScreenBlanking)
                fncEnableScreenBlank(true);

            //Load threshold settings and convert them to JS array
            Thresholds.fncConvertSaveStringToArray(settings.thresholds);
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

        Thresholds.fncCheckHRThresholds();
        Thresholds.fncCheckPaceThresholds(recorder.pace.toFixed(1));
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
                text: qsTr("Switch display mode")
                onClicked:
                {
                    iDisplayMode++;

                    if (iDisplayMode > 3)
                        iDisplayMode = 0;

                    if (iDisplayMode == 0)
                    {
                        //LCD mode
                        cBackColor = "white";
                        cPrimaryTextColor = "black";
                        cSecondaryTextColor = "#5B5B5B";
                        cBorderColor = "steelblue";
                    }
                    else if (iDisplayMode == 1)
                    {
                        //AMOLED mode
                        cBackColor = "black";
                        cPrimaryTextColor = "white";
                        cSecondaryTextColor = "#D5D5D5";
                        cBorderColor = "steelblue";
                    }
                    else if (iDisplayMode == 2)
                    {
                        //Night mode
                        cBackColor = "black";
                        cPrimaryTextColor = "#F50103";
                        cSecondaryTextColor = "#FF1937";
                        cBorderColor = "#F50103";
                    }
                    else
                    {
                        //Silica mode
                        cBackColor = "transparent";
                        cPrimaryTextColor = Theme.primaryColor;
                        cSecondaryTextColor = Theme.secondaryColor;
                        cBorderColor = Theme.secondaryColor;
                    }
                }
            }
        }

        //contentHeight: column.height + Theme.paddingLarge

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


        Item   //Header Line Left
        {
            id: idItemHeaderLine
            anchors.top: parent.top
            anchors.left: parent.left
            width: parent.width / 2
            height: parent.height / 9

            MouseArea
            {
                anchors.fill: parent
                onClicked:
                {
                    console.log("Clicked!!!");
                }
            }

            Rectangle
            {
                anchors.fill: parent
                color: cBackColor
                visible: iDisplayMode !== 3 //invisible in silica mode because we need system background
            }
            GlassItem
            {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: recorder.accuracy < 0 ? "red" : (recorder.accuracy < 30 ? "green" : "orange")
                falloffRadius: 0.15
                radius: 1.0
                cache: false
            }
            Text
            {
                text: qsTr("GPS accuracy:")
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignTop
                height: parent.height
                width: parent.width
                color: cSecondaryTextColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Text
            {
                text: recorder.accuracy < 0 ? qsTr("No position") :
                                              (recorder.accuracy < 30
                                               ? recorder.accuracy.toFixed(1) + "m"
                                               : qsTr("too low: ") + recorder.accuracy.toFixed(1) + "m")
                anchors.centerIn: parent
                height: parent.height
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: cPrimaryTextColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Rectangle
            {
                width: parent.width
                height: iBorderWidth
                anchors.bottom: parent.bottom
                color: cBorderColor
            }
            Rectangle
            {
                width: iBorderWidth
                height: parent.height
                anchors.right: parent.right
                color: cBorderColor
            }
        }
        Item   //Header Line Right
        {
            anchors.top: parent.top
            anchors.right: parent.right
            width: parent.width / 2
            height: parent.height / 9

            MouseArea
            {
                anchors.fill: parent
                onClicked:
                {
                    console.log("Clicked!!!");
                }
            }

            Rectangle
            {
                anchors.fill: parent
                color: cBackColor
                visible: iDisplayMode !== 3 //invisible in silica mode because we need system background
            }

            GlassItem
            {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: recorder.tracking ? "red" : (recorder.isEmpty ? "green" : "orange")
                falloffRadius: 0.15
                radius: 1.0
                cache: false
            }
            Text
            {
                text: recorder.tracking ? qsTr("Recording") : (recorder.isEmpty ? qsTr("Stopped") : qsTr("Paused"))
                anchors.centerIn: parent
                height: parent.height
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: cPrimaryTextColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Rectangle
            {
                width: parent.width
                height: iBorderWidth
                anchors.bottom: parent.bottom
                color: cBorderColor
            }
        }

        Item   //First Line Left
        {
            id: idItemFirstLine
            anchors.top: idItemHeaderLine.bottom
            anchors.left: parent.left
            width: parent.width / 2
            height: parent.height / 4

            MouseArea
            {
                anchors.fill: parent
                onClicked:
                {
                    console.log("Clicked!!!");
                }
            }

            Rectangle
            {
                anchors.fill: parent
                color: cBackColor
                visible: iDisplayMode !== 3 //invisible in silica mode because we need system background
            }

            Text
            {
                text: qsTr("Pace:")
                anchors.top: parent.top
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                text: recorder.pace.toFixed(1)
                anchors.centerIn: parent
                height: parent.height / 2
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cPrimaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                text: qsTr("min/km")
                anchors.bottom: parent.bottom
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Rectangle
            {
                width: parent.width
                height: iBorderWidth
                anchors.bottom: parent.bottom
                color: cBorderColor
            }
            Rectangle
            {
                width: iBorderWidth
                height: parent.height
                anchors.right: parent.right
                color: cBorderColor
            }
        }

        Item   //First Line Right
        {
            anchors.top: idItemHeaderLine.bottom
            anchors.right: parent.right
            width: parent.width / 2
            height: parent.height / 4

            MouseArea
            {
                anchors.fill: parent
                onClicked:
                {
                    console.log("Clicked!!!");
                }
            }

            Rectangle
            {
                anchors.fill: parent
                color: cBackColor
                visible: iDisplayMode !== 3 //invisible in silica mode because we need system background
            }

            Text
            {
                text: qsTr("Speed:")
                anchors.top: parent.top
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                text: recorder.speed.toFixed(1)
                anchors.centerIn: parent
                height: parent.height / 2
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cPrimaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                text: qsTr("km/h")
                anchors.bottom: parent.bottom
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Rectangle
            {
                width: parent.width
                height: iBorderWidth
                anchors.bottom: parent.bottom
                color: cBorderColor
            }
        }

        Item   //Second Line Left
        {
            id: idItemSecondLine
            anchors.top: idItemFirstLine.bottom
            anchors.left: parent.left
            width: parent.width / 2
            height: parent.height / 4

            MouseArea
            {
                anchors.fill: parent
                onClicked:
                {
                    console.log("Clicked!!!");
                }
            }

            Rectangle
            {
                anchors.fill: parent
                color: cBackColor
                visible: iDisplayMode !== 3 //invisible in silica mode because we need system background
            }

            Text
            {
                text: qsTr("Distance:")
                anchors.top: parent.top
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                text: (recorder.distance/1000).toFixed(1)
                anchors.centerIn: parent
                height: parent.height / 2
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cPrimaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                text: qsTr("km")
                anchors.bottom: parent.bottom
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Rectangle
            {
                width: parent.width
                height: iBorderWidth
                anchors.bottom: parent.bottom
                color: cBorderColor
            }
            Rectangle
            {
                width: iBorderWidth
                height: parent.height
                anchors.right: parent.right
                color: cBorderColor
            }
        }

        Item   //First Line Right
        {
            anchors.top: idItemFirstLine.bottom
            anchors.right: parent.right
            width: parent.width / 2
            height: parent.height / 4

            MouseArea
            {
                anchors.fill: parent
                onClicked:
                {
                    console.log("Clicked!!!");
                }
            }

            Rectangle
            {
                anchors.fill: parent
                color: cBackColor
                visible: iDisplayMode !== 3 //invisible in silica mode because we need system background
            }

            Text
            {
                text: qsTr("Heartrate:")
                anchors.top: parent.top
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                text: sHeartRate
                anchors.centerIn: parent
                height: parent.height / 2
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cPrimaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                text: qsTr("bpm")
                anchors.bottom: parent.bottom
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                text: qsTr("Bat:") + " " +  sBatteryLevel + "%"
                anchors.bottom: parent.bottom
                height: parent.height / 7
                width: parent.width
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Rectangle
            {
                width: parent.width
                height: iBorderWidth
                anchors.bottom: parent.bottom
                color: cBorderColor
            }
        }


        Row
        {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingSmall
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
    Map
    {
        id: map
        width: parent.width
        height: map.gesture.enabled ? page.height : width * 3/4
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
                if(map.gesture.enabled)
                {
                    //distanceLabel.opacity = 0.0;
                    //timeLabel.opacity = 0.0;
                    //accuracyLabel.opacity = 0.0;
                    //page.allowedOrientations = Orientation.All;
                }
                else
                {
                    //distanceLabel.opacity = 1.0;
                    //timeLabel.opacity = 1.0;
                    //accuracyLabel.opacity = 1.0;
                    //page.allowedOrientations = Orientation.All;
                }
                //page.forwardNavigation = !map.gesture.enabled;
                flickable.interactive = !map.gesture.enabled;
                menu.visible = !map.gesture.enabled;
            }
        }
    }
}
