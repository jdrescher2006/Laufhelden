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
        })
    }

    function showClearConfirmation() {
        var dialog = pageStack.push(Qt.resolvedUrl("ConfirmClearDialog.qml"));
        dialog.accepted.connect(function() {
            console.log("Starting new tracking");
            recorder.clearTrack();
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

        var routeZoom = Math.min(map.maximumZoomLevel, recorder.fitZoomLevelToRoute(map.width, map.height));

        if(accuracyZoom <= routeZoom && recorder.accuracy > 0) {
            map.zoomLevel = accuracyZoom;
            map.center = recorder.currentPosition;
        } else {
            map.zoomLevel = routeZoom;
            map.center = recorder.routeCenter();
        }
    }

    function newRoutePoint(coordinate) {
        routeLine.addCoordinate(coordinate);
        setMapViewport();
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            pageStack.pushAttached(Qt.resolvedUrl("HistoryPage.qml"), {})
        }
    }

    Component.onCompleted: {
        recorder.newRoutePoint.connect(newRoutePoint);
        map.addMapItem(positionMarker);
        for(var i=0;i<recorder.points;i++) {
            routeLine.addCoordinate(recorder.trackPointAt(i));
        }
        map.addMapItem(routeLine);
        setMapViewport();
    }

    MapCircle {
        id: positionMarker
        center: recorder.currentPosition
        radius: recorder.accuracy
        color: "blue"
        border.color: "blue"
        opacity: 0.3
        onRadiusChanged: setMapViewport()
    }

    MapPolyline {
        id: routeLine
        line.color: "red"
        line.width: 5
        smooth: true
    }

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
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
            }
            Label {
                id: timeLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: recorder.time
                font.pixelSize: Theme.fontSizeHuge
            }
            Label {
                id: accuracyLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: recorder.accuracy < 0 ? "No position" :
                                              (recorder.accuracy < 30
                                               ? qsTr("Accuracy: ") + recorder.accuracy.toFixed(1) + "m"
                                               : qsTr("Accuracy too low: ") + recorder.accuracy.toFixed(1) + "m")
            }
            Map {
                id: map
                width: parent.width
                height: page.height - header.height - stateLabel.height - distanceLabel.height - timeLabel.height - accuracyLabel.height - 5*Theme.paddingLarge
                clip: true
                gesture.enabled: false
                plugin: Plugin {
                    name: "osm"
                }
                center {
                    latitude: 0.0
                    longitude: 0.0
                }
                zoomLevel: minimumZoomLevel

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
            }
        }
    }
}
