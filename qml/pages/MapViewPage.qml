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
    id: detailMapPage
    allowedOrientations: bMapMaximized ? Orientation.All : Orientation.Portrait
    //No back navigation if the map is big
    backNavigation: !bMapMaximized    
    forwardNavigation: !bMapMaximized

    property var vTrackLinePoints

    property bool bHeartrateSupported: false
    property bool bPaceRelevantForWorkoutType: true

    //Map buttons
    property bool showSettingsButton: true
    property bool showMinMaxButton: true
    property bool showCenterButton: true
    property bool bLockOnCompleted : false

    property string sCurrentPosition: ""
    property string sCurrentDistance: "0"
    property string sCurrentTime: ""
    property string sCurrentDuration: "0"
    property string sCurrentHeartrate: "-"
    property string sCurrentElevation: "-"
    property string sCurrentSpeed: "0"
    property string sCurrentPace: "0"

    property bool bMapMaximized: false

    property int iCurrentWorkout: 0

    onStatusChanged:
    {
        if (status === PageStatus.Active)
        {
            bLockOnCompleted = true;

            var iPausePositionsIndex = 0;
            var trackPointsTemporary = [];

            console.log("settings.mapStyle: " + settings.mapStyle);
            map.styleUrl = settings.mapStyle;


            //Go through array with track data points
            for (var i=0; i<JSTools.trackPointsAt.length; i++)
            {
                //add this track point to temporary array. This will be used for drawing the track line
                trackPointsTemporary.push(JSTools.trackPointsAt[i]);

                //Check if we have the first data point.
                if (i===0)
                {                                       
                    //This is the first data point, draw the start icon
                    map.addSourcePoint("pointStartImage",  JSTools.trackPointsAt[i]);
                    map.addImagePath("imageStartImage", Qt.resolvedUrl("../img/map_play.png"));
                    map.addLayer("layerStartLayer", {"type": "symbol", "source": "pointStartImage"});
                    map.setLayoutProperty("layerStartLayer", "icon-image", "imageStartImage");
                    map.setLayoutProperty("layerStartLayer", "icon-size", 1.0 / map.pixelRatio);
                    map.setLayoutProperty("layerStartLayer", "icon-allow-overlap", true);

                    //Draw the current position icon to the first position
                    sCurrentPosition = "currentPosition";
                    map.addSourcePoint(sCurrentPosition,  JSTools.trackPointsAt[i]);
                    map.addImagePath("imageCurrentImage", Qt.resolvedUrl("../img/position-circle-blue.png"));
                    map.addLayer("layerCurrentLayer", {"type": "symbol", "source": sCurrentPosition});
                    map.setLayoutProperty("layerCurrentLayer", "icon-image", "imageCurrentImage");
                    map.setLayoutProperty("layerCurrentLayer", "icon-size", 1.0 / map.pixelRatio);
                    map.setLayoutProperty("layerCurrentLayer", "icon-allow-overlap", true);
                }

                //Check if we have the last data point, draw the stop icon
                if (i===(JSTools.trackPointsAt.length - 1))
                {
                    map.addSourcePoint("pointEndImage",  JSTools.trackPointsAt[i]);
                    map.addImagePath("imageEndImage", Qt.resolvedUrl("../img/map_stop.png"));
                    map.addLayer("layerEndLayer", {"type": "symbol", "source": "pointEndImage"});
                    map.setLayoutProperty("layerEndLayer", "icon-image", "imageEndImage");
                    map.setLayoutProperty("layerEndLayer", "icon-size", 1.0 / map.pixelRatio);
                    map.setLayoutProperty("layerEndLayer", "icon-allow-overlap", true);

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
                if (JSTools.trackPausePointsTemporary.length > 0 && i===JSTools.trackPausePointsTemporary[iPausePositionsIndex])
                {
                    //So this is a track point where a pause starts. The next one is the pause end!
                    //Draw the pause start icon
                    map.addSourcePoint("pointPauseStartImage" + iPausePositionsIndex.toString(),  JSTools.trackPointsAt[i]);
                    map.addImagePath("imagePauseStartImage" + iPausePositionsIndex.toString(), Qt.resolvedUrl("../img/map_pause.png"));
                    map.addLayer("layerPauseStartLayer" + iPausePositionsIndex.toString(), {"type": "symbol", "source": "pointPauseStartImage" + iPausePositionsIndex.toString()});
                    map.setLayoutProperty("layerPauseStartLayer" + iPausePositionsIndex.toString(), "icon-image", "imagePauseStartImage" + iPausePositionsIndex.toString());
                    map.setLayoutProperty("layerPauseStartLayer" + iPausePositionsIndex.toString(), "icon-size", 1.0 / map.pixelRatio);
                    map.setLayoutProperty("layerPauseStartLayer" + iPausePositionsIndex.toString(), "icon-allow-overlap", true);

                    //Draw the pause end icon
                    map.addSourcePoint("pointPauseEndImage" + iPausePositionsIndex.toString(),  JSTools.trackPointsAt[i+1]);
                    map.addImagePath("imagePauseEndImage" + iPausePositionsIndex.toString(), Qt.resolvedUrl("../img/map_resume.png"));
                    map.addLayer("layerPauseEndLayer" + iPausePositionsIndex.toString(), {"type": "symbol", "source": "pointPauseEndImage" + iPausePositionsIndex.toString()});
                    map.setLayoutProperty("layerPauseEndLayer" + iPausePositionsIndex.toString(), "icon-image", "imagePauseEndImage" + iPausePositionsIndex.toString());
                    map.setLayoutProperty("layerPauseEndLayer" + iPausePositionsIndex.toString(), "icon-size", 1.0 / map.pixelRatio);
                    map.setLayoutProperty("layerPauseEndLayer" + iPausePositionsIndex.toString(), "icon-allow-overlap", true);


                    //We can now create the track from start or end of last pause to start of this pause
                    map.addSourceLine("lineTrack" + iPausePositionsIndex.toString(), trackPointsTemporary)
                    map.addLayer("layerTrack" + iPausePositionsIndex.toString(), { "type": "line", "source": "lineTrack" + iPausePositionsIndex.toString() })
                    map.setLayoutProperty("layerTrack" + iPausePositionsIndex.toString(), "line-join", "round");
                    map.setLayoutProperty("layerTrack" + iPausePositionsIndex.toString(), "line-cap", "round");
                    map.setPaintProperty("layerTrack" + iPausePositionsIndex.toString(), "line-color", "red");
                    map.setPaintProperty("layerTrack" + iPausePositionsIndex.toString(), "line-width", 2.0);

                    trackPointsTemporary = [];

                    //set indexer to next pause position. But only if there is a further pause.
                    if ((iPausePositionsIndex + 1) < JSTools.trackPausePointsTemporary.length)
                        iPausePositionsIndex++;
                }
            }
            bLockOnCompleted = false;

            pageStack.pushAttached(Qt.resolvedUrl("DiagramViewPage.qml"));
        }
    } 

    TimeFormatter
    {
        id: timeFormatter
    }

    BusyIndicator
    {
        visible: true
        anchors.centerIn: detailMapPage
        running: false
        size: BusyIndicatorSize.Large
    }

    Image
    {
        id: id_IMG_PageLocator
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.width / 14
        width: (parent.width / 14) * 3
        anchors.bottomMargin: Theme.paddingSmall
        visible: !bMapMaximized
        source:"../img/pagelocator_2_3.png"
    }

    PageHeader
    {
        id: idHeader
        title: ""
        visible: !bMapMaximized
    }

    MapboxMap
    {
        id: map        
        anchors.top: bMapMaximized ? parent.top : idHeader.bottom
        width: parent.width
        height: bMapMaximized ? parent.height : (parent.height / 1.7)
        center: QtPositioning.coordinate(51.9854, 9.2743)
        zoomLevel: 8.0
        minimumZoomLevel: 0
        maximumZoomLevel: 20
        pixelRatio: 3.0
        accessToken: "pk.eyJ1IjoiamRyZXNjaGVyIiwiYSI6ImNqYmVta256YTJsdjUzMm1yOXU0cmxibGoifQ.JiMiONJkWdr0mVIjajIFZQ"
        cacheDatabaseMaximalSize: (settings.mapCache)*1024*1024
        cacheDatabaseDefaultPath: true

        styleUrl: settings.mapStyle

        Behavior on height {
            NumberAnimation { duration: 150 }
        }

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
                source: (map.height === detailMapPage.height) ? "../img/map_btn_min.png" : "../img/map_btn_max.png"
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

            /*
            onReleased:
            {
                console.log("onReleased: " + mouse);
            }

            onPressAndHold:
            {
                console.log("onPressAndHold: " + mouse);
            }

            onPressAndHoldGeo:
            {
                console.log("onPressAndHoldGeo: " + mouse);
            }
            */

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
            }

            function update()
            {
                // Update scalebar for current zoom level and latitude.

                var meters = map.metersPerPixel * map.width / 4;
                var dist = scaleBar.roundedDistace(meters);

                scaleBar.scaleWidth = dist / map.metersPerPixel

                console.log("dist: " + dist);

                var sUnit = "";
                var iDistance = 0;

                if (settings.measureSystem === 0)
                {
                    sUnit = "m";
                    iDistance = Math.ceil(dist);
                    if (dist >= 1000)
                    {
                        sUnit = "km";
                        iDistance = dist / 1000.0;
                        iDistance = Math.ceil(iDistance);
                    }
                }
                else
                {
                    dist = dist * 3.28084;  //convert to feet

                    sUnit = "ft";
                    iDistance = Math.ceil(dist);
                    if (dist >= 5280)
                    {
                        sUnit = "mi";
                        iDistance = dist / 5280.0;
                        iDistance = Math.ceil(iDistance);
                    }
                }

                scaleBar.text = iDistance.toString() + " " + sUnit
            }

            Connections
            {
                target: map
                onMetersPerPixelChanged: scaleBar.update()
                onWidthChanged: scaleBar.update()
            }
        }
    }

    Item
    {
        visible: !bMapMaximized
        anchors.top: map.bottom
        anchors.bottom: id_SliderMain.top
        width: parent.width

        Column
        {
            width: parent.width / 2
            height: parent.height
            anchors.left: parent.left
            anchors.top: parent.top

            anchors.topMargin: Theme.paddingMedium

            anchors.leftMargin: Theme.paddingSmall
            Row
            {
                Label
                {
                    text: qsTr("Time: ")
                    color: Theme.secondaryColor
                }
                Label
                {
                    text: sCurrentTime
                    color: Theme.primaryColor
                }
            }



            Row
            {
                Label
                {
                    text: qsTr("Duration: ")
                    color: Theme.secondaryColor
                }
                Label
                {
                    text: sCurrentDuration
                    color: Theme.primaryColor

                }
            }
            Row
            {
                Label
                {
                    text: qsTr("Elevation: ")
                    color: Theme.secondaryColor
                }
                Label
                {
                    text: sCurrentElevation
                    color: Theme.primaryColor
                }
            }
        }

        Column
        {
            width: parent.width / 2
            height: parent.height
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingMedium
            Row
            {
                Label
                {
                    text: qsTr("Pace: ")
                    color: Theme.secondaryColor
                }
                Label
                {
                    text: sCurrentPace
                    color: Theme.primaryColor
                }
            }
            Row
            {
                Label
                {
                    text: qsTr("Speed: ")
                    color: Theme.secondaryColor
                }
                Label
                {
                    text: sCurrentSpeed
                    color: Theme.primaryColor
                }
            }
            Row
            {
                visible: bHeartrateSupported
                Label
                {
                    text: qsTr("Heartrate: ")
                    color: Theme.secondaryColor
                }
                Label
                {
                    text: sCurrentHeartrate
                    color: Theme.primaryColor
                }
            }
        }
    }
    Slider
    {
        id: id_SliderMain
        visible: !bMapMaximized
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: id_IMG_PageLocator.top
        valueText: sCurrentDistance
        minimumValue: 0
        maximumValue: JSTools.trackPointsAt.length
        onValueChanged:
        {
            if (bLockOnCompleted)
                return;

            map.updateSourcePoint(sCurrentPosition, JSTools.trackPointsAt[value.toFixed(0)]);

            var dDate = new Date(JSTools.arrayDataPoints[value.toFixed(0)].time);
            var sDate = dDate.getHours() + ":" + dDate.getMinutes() + ":" + dDate.getSeconds();
            var iDistance = JSTools.arrayDataPoints[value.toFixed(0)].distance;
            var iSpeed = JSTools.arrayDataPoints[value.toFixed(0)].speed;
            var sPace = JSTools.arrayDataPoints[value.toFixed(0)].pace;
            var sPaceImp = JSTools.arrayDataPoints[value.toFixed(0)].paceimp;


            sCurrentTime = sDate;
            sCurrentDistance= (settings.measureSystem === 0) ? (iDistance/1000).toFixed(2) + qsTr("km") : JSTools.fncConvertDistanceToImperial(iDistance/1000).toFixed(2) + qsTr("mi");
            sCurrentDuration = timeFormatter.formatHMS_fromSeconds(JSTools.arrayDataPoints[value.toFixed(0)].duration);
            sCurrentHeartrate = JSTools.arrayDataPoints[value.toFixed(0)].heartrate.toString() + " bpm";
            sCurrentElevation = JSTools.arrayDataPoints[value.toFixed(0)].elevation.toFixed(0) +" m";
            sCurrentSpeed = (settings.measureSystem === 0) ? (iSpeed*3.6).toFixed(1) + " km/h" : (JSTools.fncConvertSpeedToImperial(iSpeed*3.6)).toFixed(1) + " mi/h";
            sCurrentPace = (settings.measureSystem === 0) ? sPace + " min/km" : sPaceImp + " min/mi";


            //console.log("sCurrentDistance: " + sCurrentDidistancestance);sPace
            //console.log("sCurrentHeartrate: " + sCurrentHeartrate);
            //console.log("sCurrentElevation: " + sCurrentElevation);
        }
    }
}
