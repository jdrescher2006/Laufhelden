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
import TrackLoader 1.0

Page {
    id: detailPage
    property string filename

    TrackLoader {
        id: trackLoader
        filename: detailPage.filename
    }

    SilicaFlickable {
        anchors.fill: parent
        Column {
            width: parent.width
            PageHeader {
                title: trackLoader.name==="" ? "Unnamed track" : trackLoader.name
            }
            Grid {
                x: Theme.paddingLarge
                width: parent.width
                spacing: Theme.paddingLarge
                columns: 2

                Label {
                    id: descriptionLabel
                    width: avgSpeedLabel.width
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
                    width: avgSpeedLabel.width
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
                    width: avgSpeedLabel.width
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
                    width: avgSpeedLabel.width
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
                    width: avgSpeedLabel.width
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
                    text: trackLoader.pace.toFixed(1) + " min/km"
                }
            }
        }
    }
}
