/*
 * Copyright (C) 2017 Jussi Nieminen, Finland
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

import QtQuick 2.2
import Sailfish.Silica 1.0
import harbour.laufhelden 1.0
import com.pipacs.o2 1.0
import "../tools"
import "../tools/JSTools.js" as JSTools

Page {
    id: stravaSegments
    property bool busy: false
    property var segments

    BusyIndicator {
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        visible: parent.busy
        running: parent.busy
    }

    SilicaListView
    {
        anchors.fill: parent
        id: segmentList
        model: segments

        VerticalScrollDecorator {}

        header: PageHeader {
            title: qsTr("Segments")
        }

        delegate: ListItem {
            id: listItem
            contentHeight: distangeImage.y + distangeImage.height + Theme.paddingMedium

            Image
            {
                id: image
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.paddingLarge
                width: Theme.paddingLarge * 3
                height: width
                source: segmentList.model[index]["pr_rank"] === null ? "" : "../img/strava_pr_" + segmentList.model[index]["pr_rank"] + ".png"
            }
            Label
            {
                id: nameLabel
                width: parent.width - image.width - 2*Theme.paddingLarge
                verticalAlignment: Text.AlignTop
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingMedium
                anchors.left: image.right
                anchors.leftMargin: Theme.paddingMedium
                truncationMode: TruncationMode.Fade
                text: segments[index].name
            }
            Image {
                id: distangeImage
                anchors.top: nameLabel.bottom
                anchors.left: nameLabel.left
                anchors.topMargin: Theme.paddingMedium
                source: "../img/pin.png"
                height: distLabel.height
                width: height
            }

            Label
            {
                id: distLabel
                anchors.top: distangeImage.top
                anchors.left: distangeImage.right
                anchors.leftMargin: Theme.paddingMedium
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: (settings.measureSystem === 0) ? (segmentList.model[index]["distance"]/1000).toFixed(2) + "km" : JSTools.fncConvertDistanceToImperial(segmentList.model[index]["distance"]/1000).toFixed(2) + "mi"
            }

            Image {
                id: timeImage
                anchors.top: nameLabel.bottom
                anchors.right: timeLabel.left
                anchors.topMargin: Theme.paddingMedium
                source: "../img/time.png"
                height: timeLabel.height
                width: height
            }
            Label
            {
                id: timeLabel
                anchors.top: nameLabel.bottom
                anchors.topMargin: Theme.paddingMedium
                x: (parent.width - width) / 2
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: Math.floor(segmentList.model[index]["elapsed_time"] / 60) + "min"
            }
            onClicked: {
                var segmentPage = pageStack.push(Qt.resolvedUrl("StravaSegment.qml"));
                segmentPage.effort = segmentList.model[index]
                segmentPage.loadSegment(segmentList.model[index]["segment"]["id"]);
            }
        }
    }
}
