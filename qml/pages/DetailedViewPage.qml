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
import TrackLoader 1.0

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

    TrackLoader {
        id: trackLoader
        onTrackChanged: {
            var trackLength = trackLoader.trackPointCount();
            var trackPoints = [];
            for(var i=0;i<trackLength;i++) {
                trackPoints.push(trackLoader.trackPointAt(i));
            }
            trackLine.path = trackPoints;
            trackMap.addMapItem(trackLine);
            //trackMap.fitViewportToMapItems(); // Not working
            setMapViewport(); // Workaround for above
        }
        onLoadedChanged: {
            gridContainer.opacity = 1.0
            trackMap.opacity = 1.0
        }
    }

    MapPolyline {
        id: trackLine
        line.color: "red"
        line.width: 5
        smooth: true
    }

    BusyIndicator {
        anchors.centerIn: detailPage
        running: !trackLoader.loaded
        size: BusyIndicatorSize.Large
    }

    SilicaFlickable {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: trackMap.top
        }
        clip: true
        contentHeight: header.height + gridContainer.height + Theme.paddingLarge
        VerticalScrollDecorator {}
        Column {
            width: parent.width
            PageHeader {
                id: header
                title: name==="" ? "Unnamed track" : name
                Behavior on opacity {
                    FadeAnimation {}
                }
            }
            Grid {
                id: gridContainer
                x: Theme.paddingLarge
                width: parent.width
                spacing: Theme.paddingLarge
                columns: 2
                opacity: 0.2
                Behavior on opacity {
                    FadeAnimation {}
                }

                Label {
                    id: descriptionLabel
                    width: hearRateLabel.width
                    height:descriptionData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: "Description:"
                }
                Label {
                    id: descriptionData
                    width: parent.width - descriptionLabel.width - 2*Theme.paddingLarge
                    text: trackLoader.description==="" ? "No description" : trackLoader.description
                    wrapMode: Text.WordWrap
                }
                Label {
                    width: hearRateLabel.width
                    height:timeData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: "Starting time:"
                }
                Label {
                    id: timeData
                    width: descriptionData.width
                    text: trackLoader.timeStr
                }
                Label {
                    width: hearRateLabel.width
                    height:durationData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: "Duration:"
                }
                Label {
                    id: durationData
                    width: descriptionData.width
                    text: trackLoader.durationStr
                }
                Label {
                    width: hearRateLabel.width
                    height:distanceData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: "Distance:"
                }
                Label {
                    id: distanceData
                    width: descriptionData.width
                    text: (trackLoader.distance/1000).toFixed(2) + " km"
                }
                Label {
                    height:speedData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    id: avgSpeedLabel
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: "Average speed:"
                }
                Label {
                    id: speedData
                    width: descriptionData.width
                    text: (trackLoader.speed*3.6).toFixed(1) + " km/h"
                }
                Label {
                    height:maxSpeedData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    id: maxSpeedLabel
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: "Maximum speed:"
                }
                Label {
                    id: maxSpeedData
                    width: descriptionData.width
                    text: trackLoader.maxSpeed>0
                          ? (trackLoader.maxSpeed*3.6).toFixed(1) + " km/h"
                          : "-"
                }
                Label {
                    width: hearRateLabel.width
                    height:paceData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: "Average pace:"
                }
                Label {
                    id: paceData
                    width: descriptionData.width
                    text: trackLoader.pace.toFixed(2) + " min/km"
                }

                Label {
                    id: hearRateLabel
                    height:heartRateData.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignBottom
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    text: "Heart rate Min/Max/Ø:"
                }
                Label {
                    id: heartRateData
                    width: descriptionData.width
                    text: trackLoader.heartRateMin + "/" + trackLoader.heartRateMax + "/" + trackLoader.heartRate.toFixed(1) + " bpm"
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
                value: "Laufhelden/0.0.1 (SailfishOS)"
            }
            PluginParameter { name: "osm.mapping.host"; value: "http://localhost:8553/v1/tile/" }
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
