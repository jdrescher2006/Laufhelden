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

Page {
    id: detailPage
    allowedOrientations: Orientation.Portrait
    property string filename
    property string name

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

    TrackLoader
    {
        id: trackLoader
        onTrackChanged:
        {
            //******** START: draw pause icons on the map ********
            var pauseLength = trackLoader.pausePointCount();

            var pauseStartPoints = [];
            var pauseEndPoints = [];
            for(var i=0;i<pauseLength;i++)
            {
                pauseStartPoints.push(trackLoader.pauseStartPointAt(i));
                pauseEndPoints.push(trackLoader.pauseEndPointAt(i));
            }

            //iterate through pauses
            for (i = 0; i < pauseLength; i++)
            {
                var componentStart = Qt.createComponent("../tools/MapPauseItem.qml");
                var pauseItemStart = componentStart.createObject(trackMap);
                pauseItemStart.coordinate = pauseStartPoints[i];
                //pauseItemStart.coordinate.latitude = 51.8776;
                //pauseItemStart.coordinate.longitude = 9.1518;
                pauseItemStart.iSize = (detailPage.orientation == Orientation.Portrait || detailPage.orientation == Orientation.PortraitInverted) ? detailPage.width / 14 : detailPage.height / 14
                pauseItemStart.bPauseStart = true;

                var componentEnd = Qt.createComponent("../tools/MapPauseItem.qml");
                var pauseItemEnd = componentEnd.createObject(trackMap);
                pauseItemEnd.coordinate = pauseEndPoints[i];
                pauseItemEnd.iSize = (detailPage.orientation == Orientation.Portrait || detailPage.orientation == Orientation.PortraitInverted) ? detailPage.width / 14 : detailPage.height / 14
                pauseItemEnd.bPauseStart = false;

                trackMap.addMapItem(pauseItemStart);
                trackMap.addMapItem(pauseItemEnd);

            }
            //********END: draw pause icons on the map ********

            //******** START: draw track on the map ********

            var trackLength = trackLoader.trackPointCount();
            var trackPoints = [];
            JSTools.arrayDataPoints = [];

            for(i=0;i<trackLength;i++)
            {
                trackPoints.push(trackLoader.trackPointAt(i));

                JSTools.fncAddDataPoint(trackLoader.heartRateAt(i), trackLoader.elevationAt(i), 0);
            }
            trackLine.path = trackPoints;
            trackMap.addMapItem(trackLine);

            //******** END: draw track on the map ********

            //******** START: draw start/stop icons on the map ********

            idItemTrackStart.coordinate = trackLoader.trackPointAt(0);
            idItemTrackEnd.coordinate = trackLoader.trackPointAt(trackLength - 1);
            idItemTrackStart.visible = true;
            idItemTrackEnd.visible = true;

            //******** END: draw start/stop icons on the map ********


            //trackMap.fitViewportToMapItems(); // Not working
            setMapViewport(); // Workaround for above

            pauseData.text = pauseLength.toString();

            console.log("onTrackChanged: " + JSTools.arrayDataPoints.length.toString());
        }
        onLoadedChanged:
        {
            gridContainer.opacity = 1.0
            trackMap.opacity = 1.0                       
        }       
    }

    MapPolyline
    {
        id: trackLine
        line.color: "red"
        line.width: 5
        smooth: true
    }

    BusyIndicator
    {
        anchors.centerIn: detailPage
        running: !trackLoader.loaded
        size: BusyIndicatorSize.Large
    }

    SilicaFlickable
    {
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
                visible: true
            }
        }

        Column
        {
            width: parent.width
            PageHeader
            {
                id: header
                title: name==="" ? "-" : name
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
                    id: pauseLabel
                    height:heartRateData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: qsTr("Pause number/duration")
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
}
