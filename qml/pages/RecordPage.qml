/*
    Copyright 2014 Simo Mattila
    simo.h.mattila@gmail.com

    This file is part of Rena.

    Rena is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    any later version.

    Rena is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Rena.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtLocation 5.0
import QtPositioning 5.0

Page {
    id: page

    function showSaveDialog() {
        var dialog = pageStack.push(Qt.resolvedUrl("SaveDialog.qml"));
        dialog.accepted.connect(function() {
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

    function newTrackPoint(coordinate) {
        trackLine.addCoordinate(coordinate);
        if(!map.gesture.enabled) {
            // Set viewport only when not browsing
            setMapViewport();
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            pageStack.pushAttached(Qt.resolvedUrl("HistoryPage.qml"), {})
        }
    }

    Component.onCompleted: {
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

    MapCircle {
        id: positionMarker
        center: recorder.currentPosition
        radius: recorder.accuracy
        color: "blue"
        border.color: "blue"
        opacity: 0.3
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
        anchors.bottom: map.top
        anchors.left: page.left
        anchors.right: page.right

        PullDownMenu {
            id: menu
            MenuItem {
                text: qsTr("About Rena")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: qsTr("Start new recording")
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

        contentHeight: column.height

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                id: header
                title: "Rena"
            }
            Label {
                id: stateLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: recorder.tracking ? qsTr("Recording") : qsTr("Stopped")
                font.pixelSize: Theme.fontSizeLarge
            }
            Label {
                id: distanceLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: (recorder.distance/1000).toFixed(3) + " km"
                font.pixelSize: Theme.fontSizeHuge
                Behavior on opacity {
                    FadeAnimation {}
                }
            }
            Label {
                id: timeLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: recorder.time
                font.pixelSize: Theme.fontSizeHuge
                Behavior on opacity {
                    FadeAnimation {}
                }
            }
            Label {
                id: accuracyLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: recorder.accuracy < 0 ? "No position" :
                                              (recorder.accuracy < 30
                                               ? qsTr("Accuracy: ") + recorder.accuracy.toFixed(1) + "m"
                                               : qsTr("Accuracy too low: ") + recorder.accuracy.toFixed(1) + "m")
                Behavior on opacity {
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
        plugin: Plugin {
            name: "osm"
            PluginParameter {
                name: "useragent"
                // TODO: make user agent from variable work
                //value: appUserAgent
                value: "Rena/0.0.7-dev (Sailfish)"
            }
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
