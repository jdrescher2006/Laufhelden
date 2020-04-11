/*
 * Copyright (C) 2018 Jens Drescher, Germany
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
import "../tools/JSTools.js" as JSTools
import "../graph/"
import "../components/"

Page
{
    id: page

    allowedOrientations: Orientation.All

    property bool bLockFirstPageLoad: true
    property bool bPaceRelevantForWorkoutType: true
    property bool bHeartrateSupported: false
    property variant arHeartrateData
    property variant arElevationData
    property variant arSpeedData
    property variant arPaceData

    // Elevation + speed/pace always visible heart rate just when supported
    property int iVisibleGraphCount: (2 + (bHeartrateSupported ? 1 : 0))

    property real rGraphHeight: (id_ITEM_Graphs.height/(iVisibleGraphCount *(4.4/3.0)))

    property string sCurrentDistance: "0"
    property string sCurrentTime: ""
    property string sCurrentDuration: "0"
    property string sCurrentHeartrate: "-"
    property string sCurrentElevation: "-"
    property string sCurrentSpeed: "0"
    property string sCurrentPace: "0"

    property TrackLoader trackLoader

    onStatusChanged:
    {
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            var iLastProperHeartRate = 0;
            var arrayHeartrateData = [];
            var arrayElevationData = [];
            var arraySpeedData = [];
            var arrayPaceData = [];

            for (var i = 0; i < JSTools.arrayDataPoints.length; i++)
            {
                var iElevation = (settings.measureSystem === 0) ? JSTools.arrayDataPoints[i].elevation : JSTools.fncConvertelevationToImperial(JSTools.arrayDataPoints[i].elevation);
                arrayElevationData.push({"x":JSTools.arrayDataPoints[i].unixtime,"y":iElevation});

                if (!bPaceRelevantForWorkoutType) {
                    var iSpeed = (settings.measureSystem === 0) ? (JSTools.arrayDataPoints[i].speed) : (JSTools.fncConvertSpeedToImperial(JSTools.arrayDataPoints[i].speed));
                    arraySpeedData.push({"x":JSTools.arrayDataPoints[i].unixtime,"y":iSpeed});
                } else {
                    var iPace = (settings.measureSystem === 0) ? JSTools.arrayDataPoints[i].pacevalue : (JSTools.fncConvertPacetoImperial(JSTools.arrayDataPoints[i].pacevalue));
                    arrayPaceData.push({"x":JSTools.arrayDataPoints[i].unixtime,"y":iPace});
                }

                if (bHeartrateSupported) {
                    var iHeartrate = 0;
                    if (JSTools.arrayDataPoints[i].heartrate > 0)
                    {
                        iHeartrate = JSTools.arrayDataPoints[i].heartrate;
                        iLastProperHeartRate = JSTools.arrayDataPoints[i].heartrate;
                    }
                    else
                    {
                        iHeartrate = iLastProperHeartRate;
                    }
                    arrayHeartrateData.push({"x":JSTools.arrayDataPoints[i].unixtime,"y":iHeartrate});
                }
            }

            arHeartrateData = arrayHeartrateData;
            arElevationData = arrayElevationData;
            arSpeedData = arraySpeedData;
            arPaceData = arrayPaceData;

            fncUpdateGraphs();
            bLockFirstPageLoad = false;
        }

        if (status === PageStatus.Active)
        {

        }
    }

    function fncUpdateGraphs()
    {
        if (bHeartrateSupported)
            graphHeartrate.updateGraph();
        graphElevation.updateGraph();
        if (bPaceRelevantForWorkoutType)
            graphPace.updateGraph();
        else
            graphSpeed.updateGraph();
    }

    TimeFormatter
    {
        id: timeFormatter
    }

    ApplicationWindow
    {
        onApplicationActiveChanged:
        {
            console.log("applicationActive: " + applicationActive);
            if (applicationActive)
            {
                fncUpdateGraphs();
            }
        }
    }

    Image
    {
        id: id_IMG_PageLocator
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.width / 14
        width: (parent.width / 14) * 3
        anchors.bottomMargin: Theme.paddingSmall
        source:"../img/pagelocator_3_3.png"
    }

    PageHeader
    {
        id: idHeader
        title: qsTr("Diagrams")
    }

    Item
    {
        id: id_ITEM_Graphs
        anchors.top: idHeader.bottom
        width: parent.width
        height: parent.height / 1.7

        GraphData
        {
            anchors.top: parent.top
            visible: bHeartrateSupported
            id: graphHeartrate
            graphTitle: qsTr("Heartrate")
            graphHeight: rGraphHeight

            axisY.units: "bpm"

            function updateGraph()
            {
                setPoints(arHeartrateData);
            }

            bShowCurrentLine: true
            iCurrentLinePosition: ((100.0 / JSTools.trackPointsAt.length) * id_SliderMain.value);

            lineWidth: 1
            minY: 0
            maxY: 200
            valueConverter: function(value)
            {
                return value.toFixed(0);
            }
            onClicked:
            {
                updateGraph();
            }
        }
        GraphData
        {
            anchors.top: bHeartrateSupported ? graphHeartrate.bottom : parent.top
            id: graphElevation
            displayLastValue: true
            graphTitle: qsTr("Elevation")
            graphHeight: rGraphHeight

            axisY.units: (settings.measureSystem === 0) ? "m" : "ft"

            function updateGraph()
            {
                setPoints(arElevationData);
            }

            bShowCurrentLine: true
            iCurrentLinePosition: ((100.0 / JSTools.trackPointsAt.length) * id_SliderMain.value);

            lineWidth: 2
            minY: 0
            maxY: trackLoader.elevationMax
            valueConverter: function(value)
            {
                return value.toFixed(0);
            }
            onClicked:
            {
                updateGraph();
            }
        }
        GraphData
        {
            anchors.top: graphElevation.bottom
            visible: !bPaceRelevantForWorkoutType
            id: graphSpeed
            graphTitle: qsTr("Speed")
            graphHeight: rGraphHeight

            axisY.units: (settings.measureSystem === 0) ? "km/h" : "mi/h"

            function updateGraph()
            {
                setPoints(arSpeedData);
            }

            bShowCurrentLine: true
            iCurrentLinePosition: ((100.0 / JSTools.trackPointsAt.length) * id_SliderMain.value);

            lineWidth: 2
            minY: 0
            maxY: 1.1 * ((settings.measureSystem === 0) ? (trackLoader.maxSpeed) : (JSTools.fncConvertSpeedToImperial(trackLoader.maxSpeed * 3.6)));
            valueConverter: function(value)
            {
                return value.toFixed(1);
            }
            onClicked:
            {
                updateGraph();
            }
        }
        GraphData
        {
            anchors.top: graphElevation.bottom
            visible: bPaceRelevantForWorkoutType
            id: graphPace
            graphTitle: qsTr("Pace")
            graphHeight: rGraphHeight

            axisY.units: (settings.measureSystem === 0) ? "min/km" : "min/mi"

            function updateGraph()
            {
                setPoints(arPaceData);
            }

            bShowCurrentLine: true
            iCurrentLinePosition: ((100.0 / JSTools.trackPointsAt.length) * id_SliderMain.value);

            lineWidth: 2
            minY: 0.0
            maxY: 12.0
            valueConverter: function(value)
            {
                return value.toFixed(1);
            }
            onClicked:
            {
                updateGraph();
            }
        }
    }

    Item
    {
        anchors.top: id_ITEM_Graphs.bottom
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

            InfoItem
            {
                label: qsTr("Time: ")
                value: sCurrentTime
            }
            InfoItem
            {
                label: qsTr("Duration: ")
                value: sCurrentDuration
            }
            InfoItem
            {
                label: qsTr("Elevation: ")
                value: sCurrentElevation
            }
        }

        Column
        {
            width: parent.width / 2
            height: parent.height
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingMedium

            InfoItem
            {
                label: qsTr("Pace: ")
                value: sCurrentPace
            }
            InfoItem
            {
                label: qsTr("Speed: ")
                value: sCurrentSpeed
            }
            InfoItem
            {
                visible: bHeartrateSupported
                label: qsTr("Heartrate: ")
                value: sCurrentHeartrate
            }
        }
    }
    Slider
    {
        id: id_SliderMain
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: id_IMG_PageLocator.top
        valueText: sCurrentDistance
        minimumValue: 0
        maximumValue: JSTools.trackPointsAt.length
        onValueChanged:
        {
            if (bLockFirstPageLoad)
                return;

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
            sCurrentElevation = (settings.measureSystem === 0) ? JSTools.arrayDataPoints[value.toFixed(0)].elevation.toFixed(0) + " m" : JSTools.fncConvertelevationToImperial(JSTools.arrayDataPoints[value.toFixed(0)].elevation).toFixed(0) + "ft";
            sCurrentSpeed = (settings.measureSystem === 0) ? iSpeed.toFixed(1) + " km/h" : (JSTools.fncConvertSpeedToImperial(iSpeed)).toFixed(1) + " mi/h";
            sCurrentPace = (settings.measureSystem === 0) ? sPace + " min/km" : sPaceImp + " min/mi";


            //console.log("sCurrentDistance: " + sCurrentDidistancestance);sPace
            //console.log("sCurrentHeartrate: " + sCurrentHeartrate);
            //console.log("sCurrentElevation: " + sCurrentElevation);
        }
    }
}
